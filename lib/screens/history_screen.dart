import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance.dart';
import '../providers/finance_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String search = '';
  String filter = 'Все';

  List<TransactionItem> getTransactions(FinanceProvider provider) {
    var result = List<TransactionItem>.from(
      provider.data.transactions,
    );

    if (filter == 'Доходы') {
      result = result
          .where((e) => e.type == TransactionType.income)
          .toList();
    } else if (filter == 'Расходы') {
      result = result
          .where((e) => e.type == TransactionType.expense)
          .toList();
    } else if (filter == 'Переводы') {
      result = result
          .where((e) => e.type == TransactionType.transfer)
          .toList();
    } else if (filter == 'Долги') {
      result = result
          .where((e) => e.type == TransactionType.debt)
          .toList();
    }

    if (search.trim().isNotEmpty) {
      final query = search.toLowerCase().trim();

      result = result.where((e) {
        final text = [
          e.note ?? '',
          e.category ?? '',
          e.subcategory ?? '',
          e.source ?? '',
        ].join(' ').toLowerCase();

        return text.contains(query);
      }).toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));

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

  String transactionTitle(TransactionItem transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.category ?? 'Доход';

      case TransactionType.expense:
        return transaction.category ?? 'Расход';

      case TransactionType.transfer:
        return 'Перевод';

      case TransactionType.debt:
        return transaction.debtDirection ==
                DebtDirection.receivable
            ? 'Мне должны'
            : 'Я должен';
    }
  }

  IconData transactionIcon(TransactionItem transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;

      case TransactionType.expense:
        return Icons.arrow_upward_rounded;

      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;

      case TransactionType.debt:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color transactionColor(
    BuildContext context,
    TransactionItem transaction,
  ) {
    final colors = Theme.of(context).colorScheme;

    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;

      case TransactionType.expense:
        return colors.error;

      case TransactionType.transfer:
        return Colors.blue;

      case TransactionType.debt:
        return Colors.orange;
    }
  }

  String amountText(TransactionItem transaction) {
    final amount = formatMoney(transaction.amount);

    switch (transaction.type) {
      case TransactionType.income:
        return '+$amount';

      case TransactionType.expense:
        return '-$amount';

      case TransactionType.transfer:
        return amount;

      case TransactionType.debt:
        return transaction.debtDirection ==
                DebtDirection.receivable
            ? '+$amount'
            : '-$amount';
    }
  }

  String subtitle(
    FinanceProvider provider,
    TransactionItem transaction,
  ) {
    final parts = <String>[];

    if (transaction.subcategory != null &&
        transaction.subcategory!.isNotEmpty) {
      parts.add(transaction.subcategory!);
    }

    parts.add(
      accountName(
        provider,
        transaction.accountId,
      ),
    );

    if (transaction.type == TransactionType.transfer &&
        transaction.toAccountId != null) {
      parts.add(
        '→ ${accountName(
          provider,
          transaction.toAccountId!,
        )}',
      );
    }

    if (transaction.note != null &&
        transaction.note!.isNotEmpty) {
      parts.add(transaction.note!);
    }

    return parts.join(' • ');
  }

  void showDetails(
    BuildContext context,
    FinanceProvider provider,
    TransactionItem transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transactionTitle(transaction),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    amountText(transaction),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: transactionColor(
                        context,
                        transaction,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _DetailRow(
                  title: 'Дата',
                  value: formatDateLong(
                    transaction.date,
                  ),
                ),

                _DetailRow(
                  title: 'Счёт',
                  value: accountName(
                    provider,
                    transaction.accountId,
                  ),
                ),

                if (transaction.category != null)
                  _DetailRow(
                    title: 'Категория',
                    value: transaction.category!,
                  ),

                if (transaction.subcategory != null)
                  _DetailRow(
                    title: 'Подкатегория',
                    value:
                        transaction.subcategory!,
                  ),

                if (transaction.source != null &&
                    transaction.source!.isNotEmpty)
                  _DetailRow(
                    title: 'Источник',
                    value: transaction.source!,
                  ),

                if (transaction.note != null &&
                    transaction.note!.isNotEmpty)
                  _DetailRow(
                    title: 'Комментарий',
                    value: transaction.note!,
                  ),

                if (transaction.type ==
                        TransactionType.transfer &&
                    transaction.toAccountId != null)
                  _DetailRow(
                    title: 'Куда',
                    value: accountName(
                      provider,
                      transaction.toAccountId!,
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FinanceProvider>();

    final transactions =
        getTransactions(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'История',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск операций',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              children: [
                _FilterButton(
                  label: 'Все',
                  selected: filter == 'Все',
                  onTap: () {
                    setState(() {
                      filter = 'Все';
                    });
                  },
                ),
                _FilterButton(
                  label: 'Доходы',
                  selected: filter == 'Доходы',
                  onTap: () {
                    setState(() {
                      filter = 'Доходы';
                    });
                  },
                ),
                _FilterButton(
                  label: 'Расходы',
                  selected: filter == 'Расходы',
                  onTap: () {
                    setState(() {
                      filter = 'Расходы';
                    });
                  },
                ),
                _FilterButton(
                  label: 'Переводы',
                  selected: filter == 'Переводы',
                  onTap: () {
                    setState(() {
                      filter = 'Переводы';
                    });
                  },
                ),
                _FilterButton(
                  label: 'Долги',
                  selected: filter == 'Долги',
                  onTap: () {
                    setState(() {
                      filter = 'Долги';
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Expanded(
            child: transactions.isEmpty
                ? const _EmptyHistory()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          transactions[index];

                      final color =
                          transactionColor(
                        context,
                        transaction,
                      );

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: ListTile(
                          onTap: () {
                            showDetails(
                              context,
                              provider,
                              transaction,
                            );
                          },

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),

                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color:
                                  color.withOpacity(
                                .12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              transactionIcon(
                                transaction,
                              ),
                              color: color,
                            ),
                          ),

                          title: Text(
                            transactionTitle(
                              transaction,
                            ),
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          subtitle: Text(
                            subtitle(
                              provider,
                              transaction,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          trailing: Text(
                            amountText(transaction),
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
        bottom: 6,
      ),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          const Text(
            'Операций пока нет',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавленные операции появятся здесь',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}