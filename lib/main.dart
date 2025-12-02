import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:av_volunteer_app/firebase_options.dart';
import 'package:av_volunteer_app/models/volunteer_model.dart';
import 'package:av_volunteer_app/models/event_model.dart';
import 'package:av_volunteer_app/screens/events_screen.dart';
import 'package:av_volunteer_app/screens/schedule_screen.dart';
import 'package:av_volunteer_app/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  final List<Event> _events = [
    Event(title: '週日主日崇拜', date: DateTime.now().add(const Duration(days: 2)), roles: ['音控', 'PPT', '燈控']),
    Event(title: '週五青年團契', date: DateTime.now().add(const Duration(days: 7)), roles: ['音控', 'PPT']),
    Event(title: '特別聚會：聖誕晚會', date: DateTime.now().add(const Duration(days: 30)), roles: ['音控', 'PPT', '燈控', '直播']),
  ];

  final List<String> _allRoles = ['音控', 'PPT', '燈控', '直播', '攝影'];

  @override
  void initState() {
    super.initState();
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        if (user == null) {
          _currentUser = null;
        } else {
          // Temporary rule: if email contains 'admin', set as admin.
          final bool isAdmin = user.email?.contains('admin') ?? false;
          _currentUser = Volunteer(
            id: user.uid,
            name: user.displayName ?? '匿名使用者',
            email: user.email ?? 'no-email@example.com',
            isAdmin: isAdmin,
          );
        }
      });
    });
  }

  void _addEvent(Event newEvent) {
    setState(() {
      _events.add(newEvent);
    });
  }

  void _deleteEvent(Event event) {
    setState(() {
      _events.remove(event);
    });
  }

  void _addRole(String role) {
    if (role.isNotEmpty && !_allRoles.contains(role)) {
      setState(() {
        _allRoles.add(role);
      });
    }
  }

  void _deleteRole(String role) {
    setState(() {
      _allRoles.remove(role);
    });
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
    final List<Widget> widgetOptions = <Widget>[
      EventsScreen(
        currentUser: _currentUser,
        events: _events,
        onAddEvent: _addEvent,
        onDeleteEvent: _deleteEvent,
        allRoles: _allRoles,
      ),
      const ScheduleScreen(),
      ProfileScreen(
        currentUser: _currentUser,
        allRoles: _allRoles,
        onAddRole: _addRole,
        onDeleteRole: _deleteRole,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_widgetTitles[_selectedIndex]),
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
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
