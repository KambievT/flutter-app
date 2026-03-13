import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/request.dart';
import '../models/contractor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestStore {
  static const String requestBoxName = 'requests';
  static const String contractorBoxName = 'contractors';

  late Box _requestBox;
  late Box<Contractor> _contractorBox;
  final _uuid = const Uuid();

  RequestStore._privateConstructor();
  static final RequestStore _instance = RequestStore._privateConstructor();
  factory RequestStore() => _instance;

  bool _initialized = false;

  /// Инициализация Hive + синхронизация из Firestore (без дублирования)
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // Безопасная регистрация адаптеров — чтобы не получить HiveError при повторной инициализации
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RequestItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ContractorAdapter());
    }

    try {
      _requestBox = await Hive.openBox(requestBoxName);
      _contractorBox = await Hive.openBox<Contractor>(contractorBoxName);
      _initialized = true;
    } catch (e, st) {
      print('RequestStore.init(): failed to open boxes: $e\n$st');
      rethrow;
    }

    try {
      final keys = _requestBox.keys.toList();
      print('RequestStore: opened requestBox with keys=${keys.length}');
    } catch (e) {
      print('RequestStore: cannot read requestBox.keys: $e');
    }

    final firestore = FirebaseFirestore.instance;

    // Синхронизация заявок из Firestore — обёрнута в try/catch, и без добавления дубликатов
    try {
      final snapshot = await firestore.collection('requests').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final item = RequestItem(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          contractor: data['contractor'] ?? '',
          serviceType: data['serviceType'] ?? '',
          durationLabel: data['durationLabel'] ?? '',
          revenue: (data['revenue'] ?? 0).toDouble(),
          cost: (data['cost'] ?? 0).toDouble(),
          isDone: data['isDone'] ?? false,
        );

        final dateKey = _normalizeDateKey(data['date']);
        if (dateKey == null) continue;
        // Получаем существующий список (безопасно приводим тип)
        final existingRaw = _requestBox.get(dateKey);
        final existing = (existingRaw is List<RequestItem>)
            ? existingRaw
            : (existingRaw is List)
            ? existingRaw.whereType<RequestItem>().toList()
            : <RequestItem>[];

        // Если такой id уже есть — не добавляем снова
        final exists = existing.any((r) => r.id == item.id);
        if (!exists) {
          final updated = [...existing, item];
          await _requestBox.put(dateKey, updated);
        }
      }
    } catch (e, st) {
      // Логируем, но не падаем — сеть/Firestore не должны ломать инициализацию
      // ignore: avoid_print
      print(
        'RequestStore.init(): failed to sync requests from Firestore: $e\n$st',
      );
    }

    // Синхронизация подрядчиков из Firestore — без дубликатов
    try {
      final contractorSnapshot = await firestore
          .collection('contractors')
          .get();
      for (final doc in contractorSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? doc.id).toString();
        if (!_contractorBox.values.any((c) => c.name == name)) {
          await _contractorBox.add(Contractor(name: name));
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'RequestStore.init(): failed to sync contractors from Firestore: $e\n$st',
      );
    }
  }

  String _keyFor(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String? _normalizeDateKey(dynamic source) {
    if (source is String && source.isNotEmpty) {
      return source;
    }

    if (source is Timestamp) {
      final d = source.toDate();
      return _keyFor(DateTime(d.year, d.month, d.day));
    }

    if (source is DateTime) {
      return _keyFor(DateTime(source.year, source.month, source.day));
    }

    return null;
  }

  List<RequestItem> getRequests(DateTime date) {
    // Возвращаем список заявок для даты (безопасно приводим тип)
    final raw = _requestBox.get(_keyFor(date));
    if (raw == null) return <RequestItem>[];
    if (raw is List<RequestItem>) return raw;
    if (raw is List) return raw.whereType<RequestItem>().toList();
    return <RequestItem>[];
  }

  List<String> getContractors() {
    return _contractorBox.values.map((c) => c.name).toList();
  }

  Future<void> addContractor(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!_contractorBox.values.any((c) => c.name == trimmed)) {
      await _contractorBox.add(Contractor(name: trimmed));

      // Сохраняем подрядчика в Firestore
      final firestore = FirebaseFirestore.instance;
      try {
        await firestore.collection('contractors').doc(trimmed).set({
          'name': trimmed,
        });
      } catch (e, st) {
        // ignore: avoid_print
        print(
          'RequestStore.addContractor(): failed to save to Firestore: $e\n$st',
        );
      }
    }
  }

  Future<void> addRequest(DateTime date, RequestItem item) async {
    final k = _keyFor(date);
    final raw = _requestBox.get(k);
    final list = (raw is List<RequestItem>)
        ? raw
        : (raw is List)
        ? raw.whereType<RequestItem>().toList()
        : <RequestItem>[];

    // Удаляем старую запись с таким id, если есть — чтобы не было дублей,
    // затем добавляем (сохранена логика "append / replace" — если редактировали, старая удаляется)
    final filtered = list.where((r) => r.id != item.id).toList();
    final updated = [...filtered, item];
    try {
      await _requestBox.put(k, updated);
    } catch (e, st) {
      print('RequestStore.addRequest(): failed to put to Hive: $e\n$st');
    }

    // Сохраняем в Firestore (включаем isDone)
    final firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('requests').doc(item.id).set({
        'date': k,
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'contractor': item.contractor,
        'serviceType': item.serviceType,
        'durationLabel': item.durationLabel,
        'revenue': item.revenue,
        'cost': item.cost,
        'isDone': item.isDone,
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('RequestStore.addRequest(): failed to save to Firestore: $e\n$st');
    }
  }

  Future<void> removeRequest(DateTime date, RequestItem item) async {
    final k = _keyFor(date);
    final raw = _requestBox.get(k);
    final list = (raw is List<RequestItem>)
        ? raw
        : (raw is List)
        ? raw.whereType<RequestItem>().toList()
        : <RequestItem>[];
    final updated = list.where((r) => r.id != item.id).toList();
    await _requestBox.put(k, updated);

    // Удаляем из Firestore
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(item.id)
          .delete();
    } catch (e, st) {
      print(
        'RequestStore.removeRequest(): failed to delete from Firestore: $e\n$st',
      );
    }
  }

  RequestItem createRequest({
    required String title,
    required String description,
    required String contractor,
    required String serviceType,
    required String durationLabel,
    required double revenue,
    required double cost,
  }) {
    return RequestItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      contractor: contractor,
      serviceType: serviceType,
      durationLabel: durationLabel,
      revenue: revenue,
      cost: cost,
    );
  }
}
