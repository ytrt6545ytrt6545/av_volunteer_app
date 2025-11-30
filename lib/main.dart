import 'package:flutter/material.dart';
import 'package:av_volunteer_app/models/volunteer_model.dart';
import 'package:av_volunteer_app/screens/events_screen.dart';
import 'package:av_volunteer_app/screens/schedule_screen.dart';
import 'package:av_volunteer_app/screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '視聽義工管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Volunteer? _currentUser;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      EventsScreen(currentUser: _currentUser),
      const ScheduleScreen(), // ScheduleScreen doesn't depend on user role for now
      ProfileScreen(
        currentUser: _currentUser,
        onLogin: _login,
        onLogout: _logout,
      ),
    ];
  }

  void _login(bool isAdmin) {
    setState(() {
      _currentUser = Volunteer(
        id: isAdmin ? 'uid-admin-456' : 'uid-user-123',
        name: isAdmin ? '管理員' : '王大明',
        email: isAdmin ? 'admin@example.com' : 'ming.wang@example.com',
        skills: isAdmin ? ['全部'] : ['音控', 'PPT'],
        isAdmin: isAdmin,
      );
      // Rebuild widget options with new user state
      _updateWidgetOptions();
    });
  }

  void _logout() {
    setState(() {
      _currentUser = null;
      // Rebuild widget options with new user state
      _updateWidgetOptions();
    });
  }
  
  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      EventsScreen(currentUser: _currentUser),
      const ScheduleScreen(), // ScheduleScreen doesn't depend on user role for now
      ProfileScreen(
        currentUser: _currentUser,
        onLogin: _login,
        onLogout: _logout,
      ),
    ];
  }

  static const List<String> _widgetTitles = <String>[
    '活動列表',
    '我的班表',
    '個人資料',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_widgetTitles[_selectedIndex]),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: '活動',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: '班表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '個人資料',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
