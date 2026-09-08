import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance.dart';
import '../providers/finance_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final settings = provider.data.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Ещё',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SectionTitle(title: 'Финансы'),

              _MenuCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Счета',
                subtitle: '${provider.accounts.length} счета',
                onTap: () => _showAccounts(context),
              ),

              _MenuCard(
                icon: Icons.account_balance_outlined,
                title: 'Долги',
                subtitle: '${provider.data.debts.length} активных',
                onTap: () => _showDebts(context),
              ),

              _MenuCard(
                icon: Icons.category_outlined,
                title: 'Категории',
                subtitle: '${provider.data.categories.length} категорий',
                onTap: () => _showCategories(context),
              ),

              const SizedBox(height: 20),

              _SectionTitle(title: 'Настройки'),

              _MenuCard(
                icon: Icons.palette_outlined,
                title: 'Тема',
                subtitle: _themeName(settings.theme),
                onTap: () => _showTheme(context),
              ),

              _MenuCard(
                icon: Icons.face_retouching_natural,
                title: 'Face ID',
                subtitle: settings.faceIdEnabled
                    ? 'Защита включена'
                    : 'Защита выключена',
                trailing: Switch(
                  value: settings.faceIdEnabled,
                  onChanged: (value) async {
                    final success =
                        await provider.setFaceIdEnabled(value);

                    if (!context.mounted) return;

                    if (value && !success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Не удалось включить Face ID',
                          ),
                        ),
                      );
                    }
                  },
                ),
                onTap: () async {
                  final success = await provider.setFaceIdEnabled(
                    !settings.faceIdEnabled,
                  );

                  if (!context.mounted) return;

                  if (!success && !settings.faceIdEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Не удалось включить Face ID',
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              _SectionTitle(title: 'Данные'),

              _MenuCard(
                icon: Icons.upload_file_outlined,
                title: 'Экспорт данных',
                subtitle: 'Создать резервную копию JSON',
                onTap: () => _exportData(context),
              ),

              _MenuCard(
                icon: Icons.download_outlined,
                title: 'Импорт данных',
                subtitle: 'Восстановить резервную копию',
                onTap: () => _importData(context),
              ),

              const SizedBox(height: 20),

              _SectionTitle(title: 'Опасная зона'),

              _MenuCard(
                icon: Icons.delete_forever_outlined,
                title: 'Сбросить данные',
                subtitle: 'Удалить все операции, долги и настройки',
                destructive: true,
                onTap: () => _resetData(context),
              ),

              const SizedBox(height: 28),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Расходник',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _themeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Светлая';
      case 'dark':
        return 'Тёмная';
      default:
        return 'Системная';
    }
  }

  static Future<void> _showAccounts(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AccountsSheet(),
    );
  }

  static Future<void> _showDebts(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _DebtsSheet(),
    );
  }

  static Future<void> _showCategories(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CategoriesSheet(),
    );
  }

  static Future<void> _showTheme(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ThemeSheet(),
    );
  }

  static Future<void> _exportData(BuildContext context) async {
    final provider = context.read<FinanceProvider>();

    try {
      final path = await provider.exportBackup();

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Экспорт готов'),
          content: SelectableText(
            'Резервная копия создана:\n\n$path',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось создать резервную копию'),
        ),
      );
    }
  }

  static Future<void> _importData(BuildContext context) async {
    final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['json'],
);

    if (result.isEmpty) return;

final path = result.first.path;
if (path == null) return;


    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Импорт данных'),
        content: const Text(
          'Текущие данные будут заменены данными из резервной копии. '
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<FinanceProvider>();

    final success = await provider.importBackupFromFile(
      File(path),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Данные успешно импортированы'
              : 'Не удалось импортировать файл',
        ),
      ),
    );
  }

  static Future<void> _resetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text(
          'Все операции, долги и пользовательские данные будут удалены. '
          'Стандартные счета и категории восстановятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<FinanceProvider>().resetData();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Данные сброшены'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MENU
// -----------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: destructive
                ? colors.error.withOpacity(.10)
                : colors.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: destructive ? colors.error : colors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(subtitle),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
            ),
        onTap: onTap,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ACCOUNTS
// -----------------------------------------------------------------------------

class _AccountsSheet extends StatelessWidget {
  const _AccountsSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Счета',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...provider.accountsWithBalance.map(
                        (item) => _AccountTile(
                          item: item,
                          onDelete: () =>
                              _deleteAccount(context, item.account),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            _addAccount(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить счёт'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _addAccount(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новый счёт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например, Visa',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Начальный баланс',
                suffixText: 'с',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance =
                  double.tryParse(balanceController.text) ?? 0;

              if (name.isEmpty) return;

              context.read<FinanceProvider>().addAccount(
                    name,
                    balance,
                  );

              Navigator.pop(dialogContext, true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    nameController.dispose();
    balanceController.dispose();

    if (result == true && context.mounted) {
      // Данные обновятся автоматически через Provider.
    }
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить «${account.name}»?'),
        content: const Text(
          'Счёт можно удалить только если он не используется '
          'в операциях.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = context
        .read<FinanceProvider>()
        .deleteAccount(account.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Счёт удалён'
              : 'Счёт нельзя удалить: он используется',
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountWithBalance item;
  final VoidCallback onDelete;

  const _AccountTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(item.color);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: color,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Начальный баланс: ${formatShortMoney(item.initialBalance)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatShortMoney(item.balance),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: item.balance >= 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');

    if (hex.length == 6) {
      return Color(
        int.parse('FF$hex', radix: 16),
      );
    }

    return Colors.green;
  }
}

// -----------------------------------------------------------------------------
// DEBTS
// -----------------------------------------------------------------------------

class _DebtsSheet extends StatefulWidget {
  const _DebtsSheet();

  @override
  State<_DebtsSheet> createState() => _DebtsSheetState();
}

class _DebtsSheetState extends State<_DebtsSheet> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final debts = provider.data.debts
            .where(
              (debt) =>
                  debt.direction ==
                  (selectedTab == 0
                      ? DebtDirection.receivable
                      : DebtDirection.payable),
            )
            .toList()
          ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

        final activeDebts = debts
            .where((debt) => debt.remainingAmount > 0)
            .toList();

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Долги',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Мне должны'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Я должен'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {selectedTab},
                    onSelectionChanged: (value) {
                      setState(() {
                        selectedTab = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: activeDebts.isEmpty
                        ? _EmptyState(
                            icon: Icons.handshake_outlined,
                            title: 'Долгов нет',
                            subtitle:
                                'Здесь будут отображаться активные долги',
                          )
                        : ListView.separated(
                            itemCount: activeDebts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final debt = activeDebts[index];

                              return _DebtCard(
                                debt: debt,
                                onPay: () => _payDebt(
                                  context,
                                  debt,
                                ),
                                onDelete: () => _deleteDebt(
                                  context,
                                  debt,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => _addDebt(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить долг'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addDebt(BuildContext context) async {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          selectedTab == 0 ? 'Мне должны' : 'Я должен',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Человек',
                  hintText: 'Имя',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  suffixText: 'с',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Примечание',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final person = personController.text.trim();
              final amount =
                  double.tryParse(amountController.text) ?? 0;
              final note = noteController.text.trim();

              if (person.isEmpty || amount <= 0) return;

              context.read<FinanceProvider>().addDebt(
                    person: person,
                    amount: amount,
                    note: note,
                    direction: selectedTab == 0
                        ? DebtDirection.receivable
                        : DebtDirection.payable,
                  );

              Navigator.pop(dialogContext, true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    personController.dispose();
    amountController.dispose();
    noteController.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _payDebt(
    BuildContext context,
    Debt debt,
  ) async {
    final amountController = TextEditingController(
      text: debt.remainingAmount.toStringAsFixed(0),
    );
    final noteController = TextEditingController();

    String? selectedAccountId =
        context.read<FinanceProvider>().accounts.isNotEmpty
            ? context.read<FinanceProvider>().accounts.first.id
            : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final provider = context.read<FinanceProvider>();

            return AlertDialog(
              title: Text('Погашение: ${debt.person}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Осталось: ${formatMoney(debt.remainingAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Сумма погашения',
                        suffixText: 'с',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Счёт',
                      ),
                      items: provider.accounts
                          .map(
                            (account) => DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAccountId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Примечание',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text) ?? 0;

                    if (amount <= 0 ||
                        selectedAccountId == null ||
                        amount > debt.remainingAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Проверьте сумму погашения',
                          ),
                        ),
                      );
                      return;
                    }

                    final success = provider.payDebt(
                      debt.id,
                      amount,
                      selectedAccountId!,
                      noteController.text.trim(),
                    );

                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Не удалось погасить долг',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Погасить'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteDebt(
    BuildContext context,
    Debt debt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить долг?'),
        content: Text(
          'Долг ${debt.person} будет удалён из списка.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.error,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<FinanceProvider>().deleteDebt(debt.id);
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isReceivable =
        debt.direction == DebtDirection.receivable;

    final progress = debt.originalAmount <= 0
        ? 0.0
        : (debt.remainingAmount / debt.originalAmount)
            .clamp(0.0, 1.0);

    final color = isReceivable
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(.12),
                  child: Icon(
                    isReceivable
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.person,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (debt.note != null &&
                          debt.note!.isNotEmpty)
                        Text(
                          debt.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Осталось',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                Text(
                  formatMoney(debt.remainingAmount),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPay,
                    child: const Text('Погасить'),
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

// -----------------------------------------------------------------------------
// CATEGORIES
// -----------------------------------------------------------------------------

class _CategoriesSheet extends StatelessWidget {
  const _CategoriesSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .85,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Категории',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: provider.data.categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final category =
                            provider.data.categories[index];

                        return Card(
                          elevation: 0,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _parseColor(category.color)
                                      .withOpacity(.14),
                              child: Icon(
                                Icons.category_outlined,
                                color:
                                    _parseColor(category.color),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${category.items.length} подкатегорий',
                            ),
                            children: [
                              ...category.items.map(
                                (item) => ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 20,
                                  ),
                                  title: Text(item),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.add),
                                title: const Text(
                                  'Добавить подкатегорию',
                                ),
                                onTap: () => _addSubcategory(
                                  context,
                                  category.name,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => _addCategory(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить категорию'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _addCategory(
    BuildContext context,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая категория'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Например, Спорт',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              context.read<FinanceProvider>().addCategory(name);

              Navigator.pop(dialogContext, true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Категория добавлена'),
        ),
      );
    }
  }

  static Future<void> _addSubcategory(
    BuildContext context,
    String categoryName,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая подкатегория'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Например, Спортзал',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              context.read<FinanceProvider>().addSubcategory(
                    categoryName,
                    name,
                  );

              Navigator.pop(dialogContext, true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подкатегория добавлена'),
        ),
      );
    }
  }

  static Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');

    if (hex.length == 6) {
      return Color(
        int.parse('FF$hex', radix: 16),
      );
    }

    return Colors.green;
  }
}

// -----------------------------------------------------------------------------
// THEME
// -----------------------------------------------------------------------------

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final current = provider.data.settings.theme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Тема приложения',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ThemeOption(
              icon: Icons.phone_android,
              title: 'Системная',
              value: 'system',
              current: current,
              onTap: () => provider.setTheme('system'),
            ),
            _ThemeOption(
              icon: Icons.light_mode_outlined,
              title: 'Светлая',
              value: 'light',
              current: current,
              onTap: () => provider.setTheme('light'),
            ),
            _ThemeOption(
              icon: Icons.dark_mode_outlined,
              title: 'Тёмная',
              value: 'dark',
              current: current,
              onTap: () => provider.setTheme('dark'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;

    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: selected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.circle_outlined),
        onTap: () {
          onTap();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EMPTY
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 54,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
