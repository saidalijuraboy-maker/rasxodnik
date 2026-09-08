import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance.dart';
import '../providers/finance_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState
    extends State<AnalyticsScreen> {
  String period = 'Месяц';

  List<TransactionItem> getPeriodTransactions(
    FinanceProvider provider,
  ) {
    final now = DateTime.now();

    DateTime start;

    switch (period) {
      case 'Неделя':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(
          const Duration(days: 6),
        );
        break;

      case 'Год':
        start = DateTime(
          now.year,
          1,
          1,
        );
        break;

      case 'Всё':
        return List<TransactionItem>.from(
          provider.data.transactions,
        );

      case 'Месяц':
      default:
        start = DateTime(
          now.year,
          now.month,
          1,
        );
    }

    return provider.data.transactions.where((tx) {
      return !tx.date.isBefore(start) &&
          !tx.date.isAfter(now);
    }).toList();
  }

  double income(
    List<TransactionItem> transactions,
  ) {
    return transactions
        .where(
          (e) => e.type == TransactionType.income,
        )
        .fold(
          0,
          (sum, e) => sum + e.amount,
        );
  }

  double expense(
    List<TransactionItem> transactions,
  ) {
    return transactions
        .where(
          (e) => e.type == TransactionType.expense,
        )
        .fold(
          0,
          (sum, e) => sum + e.amount,
        );
  }

  Map<String, double> categoryExpenses(
    List<TransactionItem> transactions,
  ) {
    final result = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type !=
          TransactionType.expense) {
        continue;
      }

      final category =
          transaction.category ?? 'Другое';

      result[category] =
          (result[category] ?? 0) +
              transaction.amount;
    }

    return result;
  }

  String accountName(
    FinanceProvider provider,
    String id,
  ) {
    for (final account in provider.accounts) {
      if (account.id == id) {
        return account.name;
      }
    }

    return 'Счёт';
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FinanceProvider>();

    final transactions =
        getPeriodTransactions(provider);

    final totalIncome =
        income(transactions);

    final totalExpense =
        expense(transactions);

    final difference =
        totalIncome - totalExpense;

    final categories =
        categoryExpenses(transactions);

    final sortedCategories =
        categories.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Аналитика',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30,
        ),
        children: [
          _PeriodSelector(
            selected: period,
            onChanged: (value) {
              setState(() {
                period = value;
              });
            },
          ),

          const SizedBox(height: 16),

          _BalanceCard(
            balance: provider.totalBalance,
            income: totalIncome,
            expense: totalExpense,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Доходы',
                  value:
                      '+${formatMoney(totalIncome)}',
                  icon:
                      Icons.arrow_downward_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Расходы',
                  value:
                      '-${formatMoney(totalExpense)}',
                  icon:
                      Icons.arrow_upward_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _DifferenceCard(
            difference: difference,
          ),

          const SizedBox(height: 24),

          const _SectionTitle(
            title: 'Расходы по категориям',
          ),

          const SizedBox(height: 10),

          if (sortedCategories.isEmpty)
            const _EmptyAnalytics(
              text:
                  'Нет расходов за выбранный период',
            )
          else
            _CategoryCard(
              categories: sortedCategories,
              total: totalExpense,
            ),

          const SizedBox(height: 24),

          const _SectionTitle(
            title: 'Счета',
          ),

          const SizedBox(height: 10),

          ...provider.accounts.map(
            (account) {
              final balance =
                  provider.accountBalance(
                account.id,
              );

              final accountIncome =
                  transactions
                      .where(
                        (e) =>
                            e.accountId ==
                                account.id &&
                            e.type ==
                                TransactionType
                                    .income,
                      )
                      .fold(
                        0.0,
                        (sum, e) =>
                            sum + e.amount,
                      );

              final accountExpense =
                  transactions
                      .where(
                        (e) =>
                            e.accountId ==
                                account.id &&
                            e.type ==
                                TransactionType
                                    .expense,
                      )
                      .fold(
                        0.0,
                        (sum, e) =>
                            sum + e.amount,
                      );

              return _AccountAnalyticsCard(
                name: account.name,
                balance: balance,
                income: accountIncome,
                expense: accountExpense,
                color:
                    _hexColor(account.color),
              );
            },
          ),

          const SizedBox(height: 20),

          _TransactionsCount(
            count: transactions.length,
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const periods = [
      'Неделя',
      'Месяц',
      'Год',
      'Всё',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((value) {
          return Padding(
            padding:
                const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(value),
              selected:
                  selected == value,
              onSelected: (_) {
                onChanged(value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'БАЛАНС',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color:
                    colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              formatMoney(balance),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    title: 'Доходы',
                    value:
                        '+${formatMoney(income)}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    title: 'Расходы',
                    value:
                        '-${formatMoney(expense)}',
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  final double difference;

  const _DifferenceCard({
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final positive = difference >= 0;

    final color = positive
        ? Colors.green
        : Theme.of(context)
            .colorScheme
            .error;

    return Card(
      child: ListTile(
        leading: Icon(
          positive
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: color,
          size: 32,
        ),
        title: const Text(
          'Изменение баланса',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Text(
          '${positive ? '+' : ''}${formatMoney(difference)}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final List<MapEntry<String, double>>
      categories;
  final double total;

  const _CategoryCard({
    required this.categories,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: categories.map((entry) {
            final percent = total <= 0
                ? 0.0
                : entry.value / total;

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatMoney(entry.value),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child:
                            LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          borderRadius:
                              BorderRadius
                                  .circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${(percent * 100).round()}%',
                          textAlign:
                              TextAlign.end,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AccountAnalyticsCard
    extends StatelessWidget {
  final String name;
  final double balance;
  final double income;
  final double expense;
  final Color color;

  const _AccountAnalyticsCard({
    required this.name,
    required this.balance,
    required this.income,
    required this.expense,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatMoney(balance),
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '+${formatMoney(income)} доход',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '-${formatMoney(expense)} расход',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsCount
    extends StatelessWidget {
  final int count;

  const _TransactionsCount({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Операций за период: $count',
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyAnalytics
    extends StatelessWidget {
  final String text;

  const _EmptyAnalytics({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

Color _hexColor(String hex) {
  var value = hex.replaceAll('#', '');

  if (value.length == 6) {
    value = 'FF$value';
  }

  return Color(
    int.parse(value, radix: 16),
  );
}