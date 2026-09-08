import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance.dart';

class FinanceProvider extends ChangeNotifier {
  static const String _storageKey = '@rashodnik/finance-data-v1';

  final LocalAuthentication _localAuth = LocalAuthentication();

  FinanceData _data = _initialData();

  bool _ready = false;
  bool _locked = false;

  FinanceData get data => _data;
  bool get ready => _ready;
  bool get locked => _locked;

  List<Account> get accounts => _data.accounts;

  List<AccountWithBalance> get accountsWithBalance {
    return _data.accounts
        .map(
          (account) => AccountWithBalance(
            account: account,
            balance: accountBalance(account.id),
          ),
        )
        .toList();
  }

  double get totalBalance {
    return accountsWithBalance.fold<double>(
      0.0,
      (sum, item) => sum + item.balance,
    );
  }

  double get incomeTotal {
    double total = 0.0;

    for (final tx in _data.transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      }

      if (tx.type == TransactionType.debt &&
          tx.debtDirection == DebtDirection.receivable) {
        total += tx.amount;
      }
    }

    return total;
  }

  double get expenseTotal {
    double total = 0.0;

    for (final tx in _data.transactions) {
      if (tx.type == TransactionType.expense) {
        total += tx.amount;
      }

      if (tx.type == TransactionType.debt &&
          tx.debtDirection == DebtDirection.payable) {
        total += tx.amount;
      }
    }

    return total;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic> && _isValidData(decoded)) {
          _data = FinanceData.fromJson(decoded);
        }
      }
    } catch (_) {
      _data = _initialData();
    }

    _ready = true;

    if (_data.settings.faceIdEnabled) {
      _locked = true;
    }

    notifyListeners();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _storageKey,
        jsonEncode(_data.toJson()),
      );
    } catch (_) {}
  }

  bool _isValidData(Map<String, dynamic> json) {
    return json['accounts'] is List &&
        json['transactions'] is List &&
        json['debts'] is List &&
        json['categories'] is List &&
        json['settings'] is Map;
  }

  String _nextId(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }

  // ---------------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------------

  double accountBalance(String accountId) {
    final account = _data.accounts.where(
      (item) => item.id == accountId,
    );

    if (account.isEmpty) return 0.0;

    double balance = account.first.initialBalance;

    for (final tx in _data.transactions) {
      if (tx.type == TransactionType.income &&
          tx.accountId == accountId) {
        balance += tx.amount;
      }

      if (tx.type == TransactionType.expense &&
          tx.accountId == accountId) {
        balance -= tx.amount;
      }

      if (tx.type == TransactionType.transfer) {
        if (tx.accountId == accountId) {
          balance -= tx.amount;
        }

        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
      }

      if (tx.type == TransactionType.debt) {
        if (tx.accountId == accountId &&
            tx.debtDirection == DebtDirection.receivable) {
          balance += tx.amount;
        }

        if (tx.accountId == accountId &&
            tx.debtDirection == DebtDirection.payable) {
          balance -= tx.amount;
        }
      }
    }

    return balance;
  }

  void addAccount(
    String name,
    double initialBalance,
  ) {
    const palette = [
      '#1E6F50',
      '#D68A54',
      '#4E7D9A',
      '#8D6EAA',
      '#C95C5C',
      '#A3A64F',
    ];

    final color = palette[_data.accounts.length % palette.length];

    final account = Account(
      id: _nextId('account'),
      name: name,
      initialBalance: initialBalance,
      color: color,
    );

    _data = _data.copyWith(
      accounts: [..._data.accounts, account],
    );

    notifyListeners();
    save();
  }

  bool deleteAccount(String id) {
    if (_data.accounts.length <= 1) {
      return false;
    }

    final used = _data.transactions.any(
      (tx) =>
          tx.accountId == id ||
          tx.toAccountId == id,
    );

    if (used) {
      return false;
    }

    _data = _data.copyWith(
      accounts: _data.accounts
          .where((account) => account.id != id)
          .toList(),
    );

    notifyListeners();
    save();

    return true;
  }

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------

  void addTransaction({
    required TransactionType type,
    required double amount,
    required String accountId,
    String? category,
    String? subcategory,
    String? source,
    String? toAccountId,
    String? note,
    DateTime? date,
    String? debtId,
    String? paymentId,
    DebtDirection? debtDirection,
  }) {
    final tx = TransactionItem(
      id: _nextId('tx'),
      type: type,
      amount: amount,
      category: category,
      subcategory: subcategory,
      source: source,
      accountId: accountId,
      toAccountId: toAccountId,
      note: note,
      date: date ?? DateTime.now(),
      debtId: debtId,
      paymentId: paymentId,
      debtDirection: debtDirection,
    );

    _data = _data.copyWith(
      transactions: [
        ..._data.transactions,
        tx,
      ],
    );

    notifyListeners();
    save();
  }

  void updateTransaction(
    String id, {
    double? amount,
    TransactionType? type,
    String? category,
    String? subcategory,
    String? source,
    String? accountId,
    String? toAccountId,
    String? note,
    DateTime? date,
    String? debtId,
    String? paymentId,
    DebtDirection? debtDirection,
  }) {
    final index = _data.transactions.indexWhere(
      (tx) => tx.id == id,
    );

    if (index == -1) return;

    final old = _data.transactions[index];

    final updated = old.copyWith(
      amount: amount,
      type: type,
      category: category,
      subcategory: subcategory,
      source: source,
      accountId: accountId,
      toAccountId: toAccountId,
      note: note,
      date: date,
      debtId: debtId,
      paymentId: paymentId,
      debtDirection: debtDirection,
    );

    final transactions = [..._data.transactions];
    transactions[index] = updated;

    var debts = [..._data.debts];

    if (old.type == TransactionType.debt &&
        old.debtId != null &&
        old.paymentId != null &&
        amount != null) {
      final debtIndex = debts.indexWhere(
        (debt) => debt.id == old.debtId,
      );

      if (debtIndex != -1) {
        final debt = debts[debtIndex];

        final difference = amount - old.amount;

        var remaining = debt.remainingAmount;

        if (debt.direction == DebtDirection.receivable) {
          remaining -= difference;
        } else {
          remaining += difference;
        }

        if (remaining < 0) {
          remaining = 0;
        }

        final payments = debt.payments.map((payment) {
          if (payment.id == old.paymentId) {
            return DebtPayment(
              id: payment.id,
              amount: amount,
              accountId: payment.accountId,
              date: payment.date,
              note: payment.note,
            );
          }

          return payment;
        }).toList();

        debts[debtIndex] = debt.copyWith(
          remainingAmount: remaining.toDouble(),
          payments: payments,
        );
      }
    }

    _data = _data.copyWith(
      transactions: transactions,
      debts: debts,
    );

    notifyListeners();
    save();
  }

  void deleteTransaction(String id) {
    final tx = _data.transactions.firstWhere(
      (item) => item.id == id,
      orElse: () => throw StateError('Transaction not found'),
    );

    var debts = [..._data.debts];

    if (tx.type == TransactionType.debt &&
        tx.debtId != null &&
        tx.paymentId != null) {
      final debtIndex = debts.indexWhere(
        (debt) => debt.id == tx.debtId,
      );

      if (debtIndex != -1) {
        final debt = debts[debtIndex];

        final remaining =
            debt.direction == DebtDirection.receivable
                ? debt.remainingAmount + tx.amount
                : debt.remainingAmount - tx.amount;

        final payments = debt.payments
            .where((payment) => payment.id != tx.paymentId)
            .toList();

        debts[debtIndex] = debt.copyWith(
          remainingAmount: remaining
              .clamp(
                0.0,
                debt.originalAmount,
              )
              .toDouble(),
          payments: payments,
        );
      }
    }

    _data = _data.copyWith(
      transactions: _data.transactions
          .where((item) => item.id != id)
          .toList(),
      debts: debts,
    );

    notifyListeners();
    save();
  }

  // ---------------------------------------------------------------------------
  // DEBTS
  // ---------------------------------------------------------------------------

  void addDebt({
    required String person,
    required double amount,
    required String note,
    required DebtDirection direction,
  }) {
    final debt = Debt(
      id: _nextId('debt'),
      person: person,
      originalAmount: amount,
      remainingAmount: amount,
      note: note,
      createdAt: DateTime.now(),
      direction: direction,
      payments: const [],
    );

    _data = _data.copyWith(
      debts: [
        ..._data.debts,
        debt,
      ],
    );

    notifyListeners();
    save();
  }

  bool payDebt(
    String debtId,
    double amount,
    String accountId,
    String note,
  ) {
    final index = _data.debts.indexWhere(
      (debt) => debt.id == debtId,
    );

    if (index == -1) return false;

    final debt = _data.debts[index];

    if (amount <= 0 || amount > debt.remainingAmount) {
      return false;
    }

    final payment = DebtPayment(
      id: _nextId('payment'),
      amount: amount,
      accountId: accountId,
      date: DateTime.now(),
      note: note,
    );

    final newRemaining = (debt.remainingAmount - amount)
        .clamp(
          0.0,
          debt.originalAmount,
        )
        .toDouble();

    final updatedDebt = debt.copyWith(
      remainingAmount: newRemaining,
      payments: [
        ...debt.payments,
        payment,
      ],
    );

    final debts = [..._data.debts];
    debts[index] = updatedDebt;

    final transaction = TransactionItem(
      id: _nextId('tx'),
      type: TransactionType.debt,
      amount: amount,
      category: 'Долги',
      source: debt.person,
      accountId: accountId,
      note: note.isNotEmpty ? note : 'Погашение долга',
      date: DateTime.now(),
      debtId: debtId,
      paymentId: payment.id,
      debtDirection: debt.direction,
    );

    _data = _data.copyWith(
      debts: debts,
      transactions: [
        ..._data.transactions,
        transaction,
      ],
    );

    notifyListeners();
    save();

    return true;
  }

  void deleteDebt(String id) {
    _data = _data.copyWith(
      debts: _data.debts
          .where((debt) => debt.id != id)
          .toList(),
    );

    notifyListeners();
    save();
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  void addCategory(
    String name, {
    String? color,
  }) {
    final exists = _data.categories.any(
      (item) =>
          item.name.toLowerCase() ==
          name.trim().toLowerCase(),
    );

    if (exists) return;

    const palette = [
      '#1E6F50',
      '#D68A54',
      '#4E7D9A',
      '#8D6EAA',
      '#C95C5C',
      '#A3A64F',
    ];

    final category = CategoryGroup(
      name: name.trim(),
      color: color ??
          palette[
              _data.categories.length % palette.length],
      items: const ['Другое'],
    );

    _data = _data.copyWith(
      categories: [
        ..._data.categories,
        category,
      ],
    );

    notifyListeners();
    save();
  }

  void addSubcategory(
    String categoryName,
    String name,
  ) {
    final index = _data.categories.indexWhere(
      (item) => item.name == categoryName,
    );

    if (index == -1) return;

    final category = _data.categories[index];

    final exists = category.items.any(
      (item) =>
          item.toLowerCase() ==
          name.trim().toLowerCase(),
    );

    if (exists) return;

    final categories = [..._data.categories];

    categories[index] = category.copyWith(
      items: [
        ...category.items,
        name.trim(),
      ],
    );

    _data = _data.copyWith(
      categories: categories,
    );

    notifyListeners();
    save();
  }

  // ---------------------------------------------------------------------------
  // SETTINGS
  // ---------------------------------------------------------------------------

  Future<void> setTheme(String theme) async {
    if (!['system', 'light', 'dark'].contains(theme)) {
      return;
    }

    _data = _data.copyWith(
      settings: _data.settings.copyWith(
        theme: theme,
      ),
    );

    notifyListeners();
    await save();
  }

  Future<bool> setFaceIdEnabled(bool value) async {
    if (!value) {
      _data = _data.copyWith(
        settings: _data.settings.copyWith(
          faceIdEnabled: false,
        ),
      );

      _locked = false;

      notifyListeners();
      await save();

      return true;
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!supported && !canCheck) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Подтвердите личность для включения защиты Расходника',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        return false;
      }

      _data = _data.copyWith(
        settings: _data.settings.copyWith(
          faceIdEnabled: true,
        ),
      );

      notifyListeners();
      await save();

      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> unlock() async {
    if (!_data.settings.faceIdEnabled) {
      _locked = false;
      notifyListeners();
      return true;
    }

    if (kIsWeb) {
      _locked = false;
      notifyListeners();
      return true;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Разблокируйте Расходник с помощью Face ID',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        _locked = false;
        notifyListeners();
      }

      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  void lock() {
    if (_data.settings.faceIdEnabled) {
      _locked = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // BACKUP
  // ---------------------------------------------------------------------------

  Future<String> exportBackup() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/rashodnik-backup.json',
    );

    await file.writeAsString(
      jsonEncode(_data.toJson()),
    );

    return file.path;
  }

  Future<bool> importBackupFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      if (!_isValidData(decoded)) {
        return false;
      }

      _data = FinanceData.fromJson(decoded);

      await save();

      notifyListeners();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_storageKey);

    _data = _initialData();
    _locked = false;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INITIAL DATA
  // ---------------------------------------------------------------------------

  static FinanceData _initialData() {
    return FinanceData(
      accounts: const [
        Account(
          id: 'cash',
          name: 'Наличные',
          initialBalance: 0,
          color: '#1E6F50',
        ),
        Account(
          id: 'dc',
          name: 'DC',
          initialBalance: 0,
          color: '#D68A54',
        ),
        Account(
          id: 'amonat',
          name: 'Амонатбанк',
          initialBalance: 0,
          color: '#4E7D9A',
        ),
        Account(
          id: 'alif',
          name: 'Алиф',
          initialBalance: 0,
          color: '#8D6EAA',
        ),
      ],
      transactions: [],
      debts: [],
      categories: [
        CategoryGroup(
          name: 'Еда',
          color: '#1E6F50',
          items: [
            'Продукты',
            'Ресторан',
            'Кафе',
            'Доставка',
          ],
        ),
        CategoryGroup(
          name: 'Транспорт',
          color: '#D68A54',
          items: [
            'Такси',
            'Автобус',
            'Маршрутка',
            'Бензин',
            'Ремонт',
          ],
        ),
        CategoryGroup(
          name: 'Развлечения',
          color: '#4E7D9A',
          items: [
            'Компьютерные игры',
            'Бильярд',
            'Кино',
            'Игры',
          ],
        ),
        CategoryGroup(
          name: 'Дом',
          color: '#8D6EAA',
          items: [
            'Коммунальные услуги',
            'Интернет',
            'Телефон',
            'Ремонт',
          ],
        ),
        CategoryGroup(
          name: 'Покупки',
          color: '#C95C5C',
          items: [
            'Одежда',
            'Обувь',
            'Электроника',
            'Другое',
          ],
        ),
        CategoryGroup(
          name: 'Здоровье',
          color: '#A3A64F',
          items: [
            'Аптека',
            'Врач',
            'Другое',
          ],
        ),
        CategoryGroup(
          name: 'Другое',
          color: '#1E6F50',
          items: ['Другое'],
        ),
      ],
      settings: const AppSettings(
        theme: 'system',
        faceIdEnabled: false,
      ),
    );
  }
}

class AccountWithBalance {
  final Account account;
  final double balance;

  const AccountWithBalance({
    required this.account,
    required this.balance,
  });

  String get id => account.id;
  String get name => account.name;
  double get initialBalance => account.initialBalance;
  String get color => account.color;
}

String formatMoney(double value) {
  final rounded = value.round();

  final text = rounded
      .toString()
      .replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ' ',
      );

  return '$text сомони';
}

String formatShortMoney(double value) {
  final rounded = value.round();

  final text = rounded
      .toString()
      .replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ' ',
      );

  return '$text с';
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

String formatDateLong(DateTime date) {
  const months = [
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

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String typeLabel(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return 'Доход';

    case TransactionType.expense:
      return 'Расход';

    case TransactionType.transfer:
      return 'Перевод';

    case TransactionType.debt:
      return 'Погашение долга';
  }
}