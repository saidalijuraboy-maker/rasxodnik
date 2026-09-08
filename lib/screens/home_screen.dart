import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance.dart';
import '../providers/finance_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final data = provider.data;

    final transactions = data.transactions
        .whereType<TransactionItem>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recent = transactions.take(4).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _Header(),

              const SizedBox(height: 20),

              _BalanceCard(provider: provider),

              const SizedBox(height: 22),

              const _SectionTitle(title: 'Быстрые действия'),

              const SizedBox(height: 12),

              _QuickActions(),

              const SizedBox(height: 26),

              const _SectionTitle(title: 'Мои счета'),

              const SizedBox(height: 12),

              _AccountsGrid(provider: provider),

              const SizedBox(height: 28),

              const _SectionTitle(title: 'Последние операции'),

              const SizedBox(height: 12),

              if (recent.isEmpty)
                _EmptyTransactions()
              else
                _RecentTransactions(
                  transactions: recent,
                  provider: provider,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];

    final months = [
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

    final hour = now.hour;

    String greeting;

    if (hour < 6) {
      greeting = 'Доброй ночи';
    } else if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 18) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${weekdays[now.weekday - 1]}, '
                '${now.day} ${months[now.month - 1]}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.55),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'Р',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BALANCE
// -----------------------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  final FinanceProvider provider;

  const _BalanceCard({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ОБЩИЙ БАЛАНС',
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(.65),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            formatMoney(provider.totalBalance),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Доходы',
                  amount: provider.incomeTotal,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: _BalanceItem(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Расходы',
                  amount: provider.expenseTotal,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final Color color;

  const _BalanceItem({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color.withOpacity(.85),
          size: 19,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatShortMoney(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// QUICK ACTIONS
// -----------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.arrow_upward_rounded,
            title: 'Потратил',
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              _openTransactionSheet(
                context,
                TransactionType.expense,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.arrow_downward_rounded,
            title: 'Получил',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              _openTransactionSheet(
                context,
                TransactionType.income,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.swap_horiz_rounded,
            title: 'Перевод',
            color: Colors.blueGrey,
            onTap: () {
              _openTransactionSheet(
                context,
                TransactionType.transfer,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.handshake_outlined,
            title: 'Долг',
            color: Colors.orange,
            onTap: () {
              _openDebtSheet(context);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withOpacity(.12),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ACCOUNTS
// -----------------------------------------------------------------------------

class _AccountsGrid extends StatelessWidget {
  final FinanceProvider provider;

  const _AccountsGrid({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = provider.data.accounts;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final balance = provider.accountBalance(account.id);

        return _AccountCard(
          account: account,
          balance: balance,
          onTap: () {
            _openTransactionSheet(
              context,
              TransactionType.expense,
              initialAccountId: account.id,
            );
          },
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final double balance;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.balance,
    required this.onTap,
  });

  Color _accountColor() {
    final hex = account.color.replaceFirst('#', '');

    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _accountColor();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withOpacity(.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                formatShortMoney(balance),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RECENT TRANSACTIONS
// -----------------------------------------------------------------------------

class _RecentTransactions extends StatelessWidget {
  final List<TransactionItem> transactions;
  final FinanceProvider provider;

  const _RecentTransactions({
    required this.transactions,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withOpacity(.12),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            _TransactionRow(
              transaction: transactions[i],
              provider: provider,
            ),
            if (i != transactions.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionItem transaction;
  final FinanceProvider provider;

  const _TransactionRow({
    required this.transaction,
    required this.provider,
  });

  Account? _findAccount(String id) {
    for (final account in provider.data.accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final account = _findAccount(transaction.accountId);

    final isIncome = transaction.type == TransactionType.income ||
        (transaction.type == TransactionType.debt &&
            transaction.debtDirection == DebtDirection.receivable);

    final isTransfer = transaction.type == TransactionType.transfer;

    final color = isTransfer
        ? Theme.of(context).colorScheme.primary
        : isIncome
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    String title;

    if (isTransfer) {
      final toAccount = _findAccount(
        transaction.toAccountId ?? '',
      );

      title =
          '${account?.name ?? 'Счёт'} → ${toAccount?.name ?? 'Счёт'}';
    } else if (transaction.subcategory != null &&
        transaction.subcategory!.isNotEmpty) {
      title = transaction.subcategory!;
    } else if (transaction.category != null &&
        transaction.category!.isNotEmpty) {
      title = transaction.category!;
    } else if (transaction.note != null &&
        transaction.note!.isNotEmpty) {
      title = transaction.note!;
    } else {
      title = isIncome ? 'Доход' : 'Расход';
    }

    final sign = isTransfer
        ? ''
        : isIncome
            ? '+'
            : '−';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        account?.name ?? 'Счёт',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '$sign${formatShortMoney(transaction.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EMPTY
// -----------------------------------------------------------------------------

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withOpacity(.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(.35),
          ),
          const SizedBox(height: 12),
          const Text(
            'Пока нет операций',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Добавьте первую операцию',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(.5),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION TITLE
// -----------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRANSACTION SHEET
// -----------------------------------------------------------------------------

void _openTransactionSheet(
  BuildContext context,
  TransactionType type, {
  String? initialAccountId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _TransactionSheet(
        initialType: type,
        initialAccountId: initialAccountId,
      );
    },
  );
}

class _TransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final String? initialAccountId;

  const _TransactionSheet({
    required this.initialType,
    this.initialAccountId,
  });

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  late TransactionType type;

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String? accountId;
  String? toAccountId;
  String? category;
  String? subcategory;

  @override
  void initState() {
    super.initState();

    type = widget.initialType;
    accountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.data.accounts;
    final categories = provider.data.categories;

    accountId ??= accounts.isNotEmpty ? accounts.first.id : null;

    final categoryObject = categories.where(
      (item) => item.name == category,
    );

    final subcategories = categoryObject.isNotEmpty
        ? categoryObject.first.items
        : <String>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .92,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Новая операция',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 18),

            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Расход'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Доход'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Перевод'),
                  icon: Icon(Icons.swap_horiz_rounded),
                ),
              ],
              selected: {type},
              onSelectionChanged: (value) {
                setState(() {
                  type = value.first;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: accountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Счёт',
                border: OutlineInputBorder(),
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  accountId = value;
                });
              },
            ),

            if (type == TransactionType.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: toAccountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Куда',
                  border: OutlineInputBorder(),
                ),
                items: accounts
                    .where((account) => account.id != accountId)
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    toAccountId = value;
                  });
                },
              ),
            ],

            if (type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    category = value;
                    subcategory = null;
                  });
                },
              ),

              if (subcategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: subcategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Подкатегория',
                    border: OutlineInputBorder(),
                  ),
                  items: subcategories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      subcategory = value;
                    });
                  },
                ),
              ],
            ],

            const SizedBox(height: 12),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Например: Обед с друзьями',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final provider = context.read<FinanceProvider>();

    final amount = double.tryParse(
      amountController.text.replaceAll(',', '.').trim(),
    );

    if (amount == null || amount <= 0) {
      _error('Введите корректную сумму');
      return;
    }

    if (accountId == null) {
      _error('Выберите счёт');
      return;
    }

    if (type == TransactionType.transfer) {
      if (toAccountId == null) {
        _error('Выберите счёт назначения');
        return;
      }

      if (toAccountId == accountId) {
        _error('Счета должны отличаться');
        return;
      }
    }

    provider.addTransaction(
      type: type,
      amount: amount,
      accountId: accountId!,
      toAccountId: toAccountId,
      category: category,
      subcategory: subcategory,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      date: DateTime.now(),
    );

    Navigator.pop(context);
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

// -----------------------------------------------------------------------------
// DEBT
// -----------------------------------------------------------------------------

void _openDebtSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DebtSheet(),
  );
}

class _DebtSheet extends StatefulWidget {
  const _DebtSheet();

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  DebtDirection direction = DebtDirection.receivable;

  final personController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void dispose() {
    personController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Новый долг',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 18),

            SegmentedButton<DebtDirection>(
              segments: const [
                ButtonSegment(
                  value: DebtDirection.receivable,
                  label: Text('Мне должны'),
                ),
                ButtonSegment(
                  value: DebtDirection.payable,
                  label: Text('Я должен'),
                ),
              ],
              selected: {direction},
              onSelectionChanged: (value) {
                setState(() {
                  direction = value.first;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: personController,
              decoration: const InputDecoration(
                labelText: 'Человек',
                hintText: 'Например: Фарход',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Например: До следующей недели',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Сохранить долг',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final provider = context.read<FinanceProvider>();

    final person = personController.text.trim();

    final amount = double.tryParse(
      amountController.text.replaceAll(',', '.').trim(),
    );

    if (person.isEmpty) {
      _error('Введите имя человека');
      return;
    }

    if (amount == null || amount <= 0) {
      _error('Введите корректную сумму');
      return;
    }

    provider.addDebt(
      person: person,
      amount: amount,
      direction: direction,
      note: noteController.text.trim(),
    );

    Navigator.pop(context);
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}