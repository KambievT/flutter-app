import 'package:flutter/material.dart';
import '../services/request_store.dart';
import 'day_page.dart';
import 'settings_page.dart';
import '../models/request.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _visibleMonth = DateTime.now();
  DateTime? _selectedDate;

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

  void _openDay(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DayPage(date: date)),
    );
  }

  List<Widget> _buildCalendar() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final startWeekday = firstDay.weekday;
    final leading = startWeekday - 1;

    final totalCells = 42;

    List<Widget> cells = [];

    for (int i = 0; i < totalCells; i++) {
      int day = i - leading + 1;

      if (day < 1 || day > daysInMonth) {
        cells.add(const SizedBox());
        continue;
      }

      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);

      List<RequestItem> events = [];

      try {
        events = RequestStore().getRequests(date);
      } catch (e) {
        print("Hive error: $e");
      }

      final today = DateTime.now();

      final isToday =
          today.year == date.year &&
          today.month == date.month &&
          today.day == date.day;

      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
            _openDay(date);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(.15)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// DAY NUMBER
                Text(
                  "$day",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white70,
                  ),
                ),

                const SizedBox(height: 4),

                /// EVENTS
                ...events.take(4).map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: e.isDone ? Colors.green : const Color(0xFF8535A2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),

                if (events.length > 4)
                  Text(
                    "+${events.length - 4}",
                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return cells;
  }

  String _monthName(int m) {
    const months = [
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

    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final header = "${_monthName(_visibleMonth.month)} ${_visibleMonth.year}";

    final cells = _buildCalendar();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Календарь"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
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
                  header,
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

            const SizedBox(height: 8),

            /// WEEKDAYS
            Row(
              children: const [
                _WeekDay("ПН"),
                _WeekDay("ВТ"),
                _WeekDay("СР"),
                _WeekDay("ЧТ"),
                _WeekDay("ПТ"),
                _WeekDay("СБ"),
                _WeekDay("ВС"),
              ],
            ),

            const SizedBox(height: 6),

            /// CALENDAR GRID
            Expanded(
              child: GridView.builder(
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  mainAxisExtent: 170,
                ),
                itemBuilder: (_, i) => cells[i],
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, "/analytics");
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
}

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }
}
