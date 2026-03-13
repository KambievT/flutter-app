import 'package:flutter/material.dart';
import '../models/request.dart';
import '../services/request_store.dart';

class DayPage extends StatefulWidget {
  final DateTime date;
  const DayPage({Key? key, required this.date}) : super(key: key);

  @override
  State<DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  List<RequestItem> _requests = [];

  void _load() {
    _requests = RequestStore().getRequests(widget.date);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _delete(RequestItem item) async {
    await RequestStore().removeRequest(widget.date, item);
    _load();
  }

  void _openEditor({required RequestItem item}) {
    final titleCtrl = TextEditingController(text: item.title);
    final revenueCtrl = TextEditingController(
      text: item.revenue == 0 ? '' : item.revenue.toString(),
    );
    final costCtrl = TextEditingController(
      text: item.cost == 0 ? '' : item.cost.toString(),
    );

    bool isDone = item.isDone;
    String serviceType = item.serviceType;

    // Защита: если label не найден, ставим индекс по умолчанию 1 ('1 мин')
    int durationIndex = [
      "30 сек",
      "1 мин",
      "2 мин",
      "3 мин",
    ].indexOf(item.durationLabel);
    if (durationIndex < 0) durationIndex = 1;

    String contractor = item.contractor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (c, setState) {
            final mq = MediaQuery.of(ctx).viewInsets.bottom;
            final contractors = RequestStore().getContractors();

            return Padding(
              padding: EdgeInsets.only(bottom: mq),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'Название заявки',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Выбрать подрядчика'),
                          ),
                          ...contractors.map(
                            (cName) => DropdownMenuItem(
                              value: cName,
                              child: Text(cName),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: '__new__',
                            child: Text('Добавить нового подрядчика...'),
                          ),
                        ],
                        value: contractor.isEmpty ? '' : contractor,
                        onChanged: (v) async {
                          if (v == '__new__') {
                            final res = await showDialog<String>(
                              context: ctx,
                              builder: (dctx) {
                                final ctrl = TextEditingController();

                                return AlertDialog(
                                  title: const Text('Новый подрядчик'),
                                  content: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Имя подрядчика',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dctx).pop(),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final name = ctrl.text.trim();
                                        if (name.isNotEmpty) {
                                          Navigator.of(dctx).pop(name);
                                        }
                                      },
                                      child: const Text('Сохранить'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (res != null && res.isNotEmpty) {
                              await RequestStore().addContractor(res);
                              setState(() => contractor = res);
                            }
                          } else {
                            setState(() => contractor = v ?? '');
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Тип услуги',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => serviceType = 'individual'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: serviceType == 'individual'
                                      ? const Color(0xFF8535A2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Center(
                                  child: Text(
                                    'Индивидуально',
                                    style: TextStyle(
                                      color: serviceType == 'individual'
                                          ? Colors.white
                                          : Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => serviceType = 'group'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: serviceType == 'group'
                                      ? const Color(0xFF8535A2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Center(
                                  child: Text(
                                    'Группа',
                                    style: TextStyle(
                                      color: serviceType == 'group'
                                          ? Colors.white
                                          : Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(
                            value: isDone,
                            onChanged: (v) =>
                                setState(() => isDone = v ?? false),
                          ),
                          const Text('Выполнено'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: revenueCtrl,
                        decoration: InputDecoration(
                          hintText: 'Выручка',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: costCtrl,
                        decoration: InputDecoration(
                          hintText: 'Себестоимость',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Длительность',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: List.generate(4, (idx) {
                          final labels = ['30 сек', '1 мин', '2 мин', '3 мин'];
                          final selected = durationIndex == idx;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => setState(() => durationIndex = idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF8535A2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  labels[idx],
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Theme.of(context)
                                              .colorScheme
                                              .onBackground
                                              .withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () async {
                          final title = titleCtrl.text.isNotEmpty
                              ? titleCtrl.text
                              : (contractor.isNotEmpty ? contractor : 'Заявка');

                          final rev =
                              double.tryParse(
                                revenueCtrl.text.replaceAll(',', '.'),
                              ) ??
                              0.0;

                          final cost =
                              double.tryParse(
                                costCtrl.text.replaceAll(',', '.'),
                              ) ??
                              0.0;

                          final durationLabels = [
                            '30 сек',
                            '1 мин',
                            '2 мин',
                            '3 мин',
                          ];

                          final updated = RequestItem(
                            id: item.id,
                            title: title,
                            description: '',
                            contractor: contractor,
                            serviceType: serviceType,
                            durationLabel: durationLabels[durationIndex],
                            revenue: rev,
                            cost: cost,
                            isDone: isDone,
                          );

                          // Если запись с таким id уже есть — удаляем её (редактирование).
                          // Иначе — просто добавляем (создание новой).
                          final existing = RequestStore()
                              .getRequests(widget.date)
                              .any((r) => r.id == item.id);
                          if (existing) {
                            await RequestStore().removeRequest(widget.date, item);
                          }
                          await RequestStore().addRequest(widget.date, updated);

                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          _load();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Сохранить изменения'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8535A2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Закрыть'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.date.day} ${_monthName(widget.date.month)} ${widget.date.year}',
        ),
        backgroundColor: const Color(0xFF8535A2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Создаём новую пустую заявку и открываем редактор
                _openEditor(
                  item: RequestItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: '',
                    description: '',
                    contractor: '',
                    serviceType: 'individual',
                    durationLabel: '1 мин',
                    revenue: 0,
                    cost: 0,
                    isDone: false,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Добавить заявку', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: _requests.isNotEmpty
                  ? ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, idx) {
                        final r = _requests[idx];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (r.contractor.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8535A2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          r.contractor,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  '${r.durationLabel} • ${r.serviceType}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onBackground.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Text(
                                      '${r.revenue.toStringAsFixed(0)} ₽',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Text(
                                      'Себестоимость: ${r.cost.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.amber,
                                      ),
                                      tooltip: 'Редактировать',
                                      onPressed: () => _openEditor(item: r),
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Удалить',
                                      onPressed: () async => _delete(r),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Нет заявок на этот день',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return names[m];
  }
}
