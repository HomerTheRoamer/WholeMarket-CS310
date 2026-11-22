import 'package:wholemarket/models/product.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'create_promotion_screen.dart';

class PromotionPlannerScreen extends StatefulWidget {
  final List<Product> products;
  final bool initialShowActiveOnly;

  const PromotionPlannerScreen({
    super.key,
    required this.products,
    this.initialShowActiveOnly = false,
  });

  @override
  State<PromotionPlannerScreen> createState() => _PromotionPlannerScreenState();
}

class _PromotionPlannerScreenState extends State<PromotionPlannerScreen> {
  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late bool showActiveOnly;

  bool _isActive(Map<String, dynamic> promotion) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = promotion['startDate'] as DateTime;
    final end = promotion['endDate'] as DateTime;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !today.isBefore(startDay) && !today.isAfter(endDay);
  }

  @override
  void initState() {
    super.initState();
    showActiveOnly = widget.initialShowActiveOnly;
    _loadPromotions();
  }

  // We will replace this with real promotions later.
  final List<Map<String, dynamic>> promotions = [];

  Future<void> _savePromotions() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedPromotions = promotions.map((promotion) {
      return {
        ...promotion,
        'startDate': (promotion['startDate'] as DateTime).toIso8601String(),
        'endDate': (promotion['endDate'] as DateTime).toIso8601String(),
      };
    }).toList();

    await prefs.setString('saved_promotions', jsonEncode(encodedPromotions));
  }

  Future<void> _loadPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_promotions');

    if (savedData == null) return;

    final decodedData = jsonDecode(savedData) as List<dynamic>;

    final loadedPromotions = decodedData.map((item) {
      final promotion = Map<String, dynamic>.from(item as Map);

      promotion['startDate'] = DateTime.parse(promotion['startDate'] as String);

      promotion['endDate'] = DateTime.parse(promotion['endDate'] as String);

      return promotion;
    }).toList();

    if (!mounted) return;

    setState(() {
      promotions
        ..clear()
        ..addAll(loadedPromotions);
    });
  }

  void _previousMonth() {
    setState(() {
      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);

    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    // Monday = 1, Sunday = 7
    final emptyDays = firstDay.weekday - 1;
    final totalCells = emptyDays + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_monthName(displayedMonth.month)} '
              '${displayedMonth.year}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Calendar day grid
        Column(
          children: List.generate(rowCount, (rowIndex) {
            return Row(
              children: List.generate(7, (columnIndex) {
                final cellIndex = rowIndex * 7 + columnIndex;
                final dayNumber = cellIndex - emptyDays + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }

                final date = DateTime(
                  displayedMonth.year,
                  displayedMonth.month,
                  dayNumber,
                );

                final today = DateTime.now();
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final hasPromotion = promotions.any((promotion) {
                  final start = promotion['startDate'] as DateTime;
                  final end = promotion['endDate'] as DateTime;

                  return !date.isBefore(start) && !date.isAfter(end);
                });

                return Expanded(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasPromotion
                          ? Theme.of(context).colorScheme.primary
                          : isToday
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: hasPromotion
                            ? Theme.of(context).colorScheme.onPrimary
                            : isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePromotions = showActiveOnly
        ? promotions.where(_isActive).toList()
        : promotions;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Expanded(
                        child: Text(
                          'Promotion planner',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  const Text('Plan and manage your promotions'),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildCalendar(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          showActiveOnly
                              ? 'Active offers'
                              : 'Scheduled promotions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (showActiveOnly)
                        TextButton(
                          onPressed: () =>
                              setState(() => showActiveOnly = false),
                          child: const Text('Show all'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: visiblePromotions.isEmpty
                        ? Center(
                            child: Text(
                              showActiveOnly ? 'No active promotions today.' : 'No promotions scheduled yet.\nCreate your first promotion!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: visiblePromotions.length,
                            itemBuilder: (context, index) {
                              final promotion = visiblePromotions[index];

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    promotion['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(promotion['dates'] as String),

                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${(promotion['discount'] as double).toStringAsFixed(0)}% OFF',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        tooltip: 'Edit promotion',
                                        onPressed: () async {
                                          final updatedPromotion =
                                              await Navigator.push<
                                                Map<String, dynamic>
                                              >(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreatePromotionScreen(
                                                        products:
                                                            widget.products,
                                                        existingPromotion:
                                                            promotion,
                                                        existingPromotions:
                                                            promotions,
                                                      ),
                                                ),
                                              );

                                          if (!context.mounted) return;

                                          if (updatedPromotion != null) {
                                            setState(() {
                                              promotions[promotions.indexOf(
                                                    promotion,
                                                  )] =
                                                  updatedPromotion;
                                            });
                                            await _savePromotions();
                                            if (!context.mounted) return;

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Promotion updated successfully!',
                                                    ),
                                                  ),
                                                );
                                          }
                                        },
                                      ),

                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        tooltip: 'Delete promotion',
                                        onPressed: () async {
                                          final shouldDelete =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (dialogContext) =>
                                                    AlertDialog(
                                                      title: const Text(
                                                        'Delete promotion?',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this promotion?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                dialogContext,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                dialogContext,
                                                                true,
                                                              ),
                                                          child: const Text(
                                                            'Delete',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                          if (!mounted) return;

                                          if (shouldDelete == true) {
                                            setState(() {
                                              promotions.remove(promotion);
                                            });

                                            await _savePromotions();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final promotion =
                          await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePromotionScreen(
                                products: widget.products,
                                existingPromotions: promotions,
                              ),
                            ),
                          );

                      if (!context.mounted) return;

                      if (promotion != null) {
                        setState(() {
                          promotions.add(promotion);
                        });

                        await _savePromotions();
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promotion added to planner!'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create promotion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
