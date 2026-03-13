import 'package:flutter/material.dart';
import '../services/request_store.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _visibleMonth = DateTime.now();
  String _selectedContractor = 'Все';

  DateTime? _periodStart;
  DateTime? _periodEnd;

  DateTime get start =>
      _periodStart ?? DateTime(_visibleMonth.year, _visibleMonth.month, 1);

  DateTime get end =>
      _periodEnd ?? DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  List _allRequests() {
    final rs = RequestStore();
    List list = [];

    final days = end.difference(start).inDays + 1;

    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));

      final items = rs
          .getRequests(date)
          .where(
            (r) =>
                _selectedContractor == 'Все' ||
                r.contractor == _selectedContractor,
          );

      list.addAll(items);
    }

    return list;
  }

  double get revenue => _allRequests().fold(0.0, (p, e) => p + e.revenue);

  double get cost => _allRequests().fold(0.0, (p, e) => p + e.cost);

  double get profit => revenue - cost;

  int get orders => _allRequests().length;

  List<double> _dailyProfit() {
    final rs = RequestStore();

    final days = end.difference(start).inDays + 1;

    List<double> profits = List.filled(days, 0);

    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));

      final items = rs
          .getRequests(date)
          .where(
            (r) =>
                _selectedContractor == 'Все' ||
                r.contractor == _selectedContractor,
          );

      profits[i] = items.fold(0.0, (p, e) => p + (e.revenue - e.cost));
    }

    return profits;
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: start, end: end),
    );

    if (picked != null) {
      setState(() {
        _periodStart = picked.start;
        _periodEnd = picked.end;
      });
    }
  }

  String _monthName(int m) {
    const names = [
      '',
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    return names[m];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final contractors = ['Все', ...RequestStore().getContractors()];
    final profits = _dailyProfit();

    final monthLabel =
        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    return Scaffold(
      appBar: AppBar(title: const Text("Аналитика")),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// MONTH SWITCH
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// PERIOD BUTTON
          ElevatedButton.icon(
            onPressed: _selectPeriod,
            icon: const Icon(Icons.date_range),
            label: const Text("Выбрать период"),
          ),

          const SizedBox(height: 16),

          /// CONTRACTOR FILTER
          DropdownButtonFormField(
            value: _selectedContractor,
            decoration: const InputDecoration(
              labelText: "Подрядчик",
              border: OutlineInputBorder(),
            ),
            items: contractors
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedContractor = v!;
              });
            },
          ),

          const SizedBox(height: 20),

          /// STATS GRID
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _statCard("Заказы", "$orders"),
              _statCard("Выручка", "${revenue.toStringAsFixed(0)} ₽"),
              _statCard("Себестоимость", "${cost.toStringAsFixed(0)} ₽"),
              _statCard("Прибыль", "${profit.toStringAsFixed(0)} ₽"),
            ],
          ),

          const SizedBox(height: 24),

          /// CHART
          const Text(
            "Прибыль по дням",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(profits.length, (i) {
                  final max = profits.isEmpty
                      ? 1
                      : profits.reduce((a, b) => a > b ? a : b).abs() + 1;

                  final heightFactor = (profits[i] / max).abs();

                  return SizedBox(
                    width: 24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text("${i + 1}", style: const TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),

      /// BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushNamed(context, "/calendar");
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Календарь",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Аналитика",
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
