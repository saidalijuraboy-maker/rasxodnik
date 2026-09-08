enum TransactionType {
  income,
  expense,
  transfer,
  debt,
}

enum DebtDirection {
  receivable,
  payable,
}

class Account {
  final String id;
  final String name;
  final double initialBalance;
  final String color;

  const Account({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.color,
  });

  Account copyWith({
    String? id,
    String? name,
    double? initialBalance,
    String? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialBalance': initialBalance,
        'color': color,
      };

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
      color: json['color'] as String,
    );
  }
}

class TransactionItem {
  final String id;
  final TransactionType type;
  final double amount;
  final String? category;
  final String? subcategory;
  final String? source;
  final String accountId;
  final String? toAccountId;
  final String? note;
  final DateTime date;
  final String? debtId;
  final String? paymentId;
  final DebtDirection? debtDirection;

  const TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    this.category,
    this.subcategory,
    this.source,
    required this.accountId,
    this.toAccountId,
    this.note,
    required this.date,
    this.debtId,
    this.paymentId,
    this.debtDirection,
  });

  TransactionItem copyWith({
    String? id,
    TransactionType? type,
    double? amount,
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
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      source: source ?? this.source,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      date: date ?? this.date,
      debtId: debtId ?? this.debtId,
      paymentId: paymentId ?? this.paymentId,
      debtDirection: debtDirection ?? this.debtDirection,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'subcategory': subcategory,
        'source': source,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'note': note,
        'date': date.toIso8601String(),
        'debtId': debtId,
        'paymentId': paymentId,
        'debtDirection': debtDirection?.name,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      source: json['source'] as String?,
      accountId: json['accountId'] as String,
      toAccountId: json['toAccountId'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      debtId: json['debtId'] as String?,
      paymentId: json['paymentId'] as String?,
      debtDirection: json['debtDirection'] == null
          ? null
          : DebtDirection.values.byName(json['debtDirection'] as String),
    );
  }
}

class DebtPayment {
  final String id;
  final double amount;
  final String accountId;
  final DateTime date;
  final String? note;

  const DebtPayment({
    required this.id,
    required this.amount,
    required this.accountId,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

class Debt {
  final String id;
  final String person;
  final double originalAmount;
  final double remainingAmount;
  final String? note;
  final DateTime createdAt;
  final DebtDirection direction;
  final List<DebtPayment> payments;

  const Debt({
    required this.id,
    required this.person,
    required this.originalAmount,
    required this.remainingAmount,
    this.note,
    required this.createdAt,
    required this.direction,
    required this.payments,
  });

  Debt copyWith({
    String? id,
    String? person,
    double? originalAmount,
    double? remainingAmount,
    String? note,
    DateTime? createdAt,
    DebtDirection? direction,
    List<DebtPayment>? payments,
  }) {
    return Debt(
      id: id ?? this.id,
      person: person ?? this.person,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      direction: direction ?? this.direction,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'originalAmount': originalAmount,
        'remainingAmount': remainingAmount,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'direction': direction.name,
        'payments': payments.map((e) => e.toJson()).toList(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      person: json['person'] as String,
      originalAmount: (json['originalAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      direction: DebtDirection.values.byName(json['direction'] as String),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => DebtPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryGroup {
  final String name;
  final String color;
  final List<String> items;

  const CategoryGroup({
    required this.name,
    required this.color,
    required this.items,
  });

  CategoryGroup copyWith({
    String? name,
    String? color,
    List<String>? items,
  }) {
    return CategoryGroup(
      name: name ?? this.name,
      color: color ?? this.color,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'items': items,
      };

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      name: json['name'] as String,
      color: json['color'] as String,
      items: List<String>.from(json['items'] as List<dynamic>),
    );
  }
}

class AppSettings {
  final String theme;
  final bool faceIdEnabled;

  const AppSettings({
    required this.theme,
    required this.faceIdEnabled,
  });

  AppSettings copyWith({
    String? theme,
    bool? faceIdEnabled,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'faceIdEnabled': faceIdEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] as String? ?? 'system',
      faceIdEnabled: json['faceIdEnabled'] as bool? ?? false,
    );
  }
}

class FinanceData {
  final List<Account> accounts;
  final List<TransactionItem> transactions;
  final List<Debt> debts;
  final List<CategoryGroup> categories;
  final AppSettings settings;

  const FinanceData({
    required this.accounts,
    required this.transactions,
    required this.debts,
    required this.categories,
    required this.settings,
  });

  FinanceData copyWith({
    List<Account>? accounts,
    List<TransactionItem>? transactions,
    List<Debt>? debts,
    List<CategoryGroup>? categories,
    AppSettings? settings,
  }) {
    return FinanceData(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      debts: debts ?? this.debts,
      categories: categories ?? this.categories,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'debts': debts.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    return FinanceData(
      accounts: (json['accounts'] as List<dynamic>)
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      debts: (json['debts'] as List<dynamic>)
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => CategoryGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: AppSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
    );
  }
}