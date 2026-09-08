import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/finance_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const RashodnikApp());
}

class RashodnikApp extends StatelessWidget {
const RashodnikApp({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider(
create: (context) {
final provider = FinanceProvider();
provider.load();
return provider;
},
child: const RashodnikRoot(),
);
}
}

class RashodnikRoot extends StatelessWidget {
const RashodnikRoot({super.key});

@override
Widget build(BuildContext context) {
return Consumer<FinanceProvider>(
builder: (context, finance, child) {
if (!finance.ready) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Расходник',
home: Scaffold(
backgroundColor: const Color(0xFFF5F7F2),
body: Center(
child: CircularProgressIndicator(
color: const Color(0xFF1E6F50),
),
),
),
);
}

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Расходник',
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: _themeMode(finance.data.settings.theme),
      home: finance.locked
          ? const RashodnikLockScreen()
          : const RashodnikHome(),
    );
  },
);

}

ThemeMode _themeMode(String value) {
if (value == 'light') {
return ThemeMode.light;
}

if (value == 'dark') {
  return ThemeMode.dark;
}

return ThemeMode.system;

}

ThemeData _lightTheme() {
return ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xFF1E6F50),
brightness: Brightness.light,
),
scaffoldBackgroundColor: const Color(0xFFF5F7F2),
appBarTheme: const AppBarTheme(
elevation: 0,
backgroundColor: Color(0xFFF5F7F2),
foregroundColor: Color(0xFF16251E),
),
cardTheme: const CardThemeData(
elevation: 0,
color: Colors.white,
margin: EdgeInsets.zero,
),
);
}

ThemeData _darkTheme() {
return ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xFF82D1A6),
brightness: Brightness.dark,
),
scaffoldBackgroundColor: const Color(0xFF111A16),
appBarTheme: const AppBarTheme(
elevation: 0,
backgroundColor: Color(0xFF111A16),
foregroundColor: Color(0xFFF1F6F0),
),
cardTheme: const CardThemeData(
elevation: 0,
color: Color(0xFF1B2821),
margin: EdgeInsets.zero,
),
);
}
}

class RashodnikLockButton extends StatelessWidget {
const RashodnikLockButton({super.key});

@override
Widget build(BuildContext context) {
return const SizedBox.shrink();
}
}

class RashodnikLockScreen extends StatelessWidget {
const RashodnikLockScreen({super.key});

@override
Widget build(BuildContext context) {
final finance = context.read<FinanceProvider>();

return Scaffold(
  body: SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Расходник',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Приложение заблокировано',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () async {
                await finance.unlock();
              },
              icon: const Icon(Icons.face),
              label: const Text('Разблокировать'),
            ),
          ],
        ),
      ),
    ),
  ),
);

}
}

class RashodnikHome extends StatefulWidget {
const RashodnikHome({super.key});

@override
State<RashodnikHome> createState() => _RashodnikHomeState();
}

class _RashodnikHomeState extends State<RashodnikHome> {
int currentIndex = 0;

final List<Widget> pages = const [
HomeScreen(),
HistoryScreen(),
AnalyticsScreen(),
MoreScreen(),
];

@override
Widget build(BuildContext context) {
return Scaffold(
body: IndexedStack(
index: currentIndex,
children: pages,
),
bottomNavigationBar: NavigationBar(
selectedIndex: currentIndex,
onDestinationSelected: (index) {
setState(() {
currentIndex = index;
});
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: 'Главная',
),
NavigationDestination(
icon: Icon(Icons.history_outlined),
selectedIcon: Icon(Icons.history),
label: 'История',
),
NavigationDestination(
icon: Icon(Icons.bar_chart_outlined),
selectedIcon: Icon(Icons.bar_chart),
label: 'Аналитика',
),
NavigationDestination(
icon: Icon(Icons.more_horiz),
selectedIcon: Icon(Icons.more_horiz),
label: 'Ещё',
),
],
),
);
}
}
class MyApp extends RashodnikApp {
const MyApp({super.key});
}
