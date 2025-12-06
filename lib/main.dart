import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:av_volunteer_app/firebase_options.dart';
import 'package:av_volunteer_app/models/volunteer_model.dart';
import 'package:av_volunteer_app/models/event_model.dart';
import 'package:av_volunteer_app/models/shift_model.dart';
import 'package:av_volunteer_app/screens/events_screen.dart';
import 'package:av_volunteer_app/screens/schedule_screen.dart';
import 'package:av_volunteer_app/screens/profile_screen.dart';

// --- Globals for notification --- 
const String _serverKey = 'AIzaSyCKFJ0dAhCVKmOXArvLjTNARjryu_nxY2s';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _setupFCM();
  runApp(const MyApp());
}

Future<void> _setupFCM() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
  await messaging.subscribeToTopic("new_event");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '視聽義工管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
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

  final List<String> _allRoles = ['音控', 'PPT', '燈控', '直播', '攝影'];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user == null) {
        setState(() => _currentUser = null);
      } else {
        final token = await FirebaseMessaging.instance.getToken();
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        var userDoc = await userRef.get();
        if (!userDoc.exists) {
          final defaultUserData = {
            'name': user.displayName ?? '匿名使用者',
            'email': user.email,
            'isAdmin': user.email?.contains('admin') ?? false,
            'skills': [],
            'fcmToken': token,
          };
          await userRef.set(defaultUserData);
          userDoc = await userRef.get();
        } else {
          await userRef.update({'fcmToken': token});
        }
        setState(() {
          _currentUser = Volunteer.fromFirestore(userDoc, null);
        });
      }
    });
  }

  Future<void> _sendNewEventNotification(Event event) async {
    if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
      print('FCM Server Key has not been set in main.dart');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'to': '/topics/new_event',
          'notification': {
            'title': '有新的活動發佈了！',
            'body': event.title,
          },
        }),
      );
      if (response.statusCode == 200) {
        print('Notification sent successfully.');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _addEvent(Event newEvent) async {
    await FirebaseFirestore.instance.collection('events').add(newEvent.toFirestore());
  }

  Future<void> _updateEvent(Event event) async {
    if (event.id != null) {
      await FirebaseFirestore.instance.collection('events').doc(event.id).update(event.toFirestore());
    }
  }

  Future<void> _deleteEvent(Event event, String? reason) async {
    if (event.id == null) return;

    final firestore = FirebaseFirestore.instance;
    final shiftsQuery = await firestore.collection('shifts').where('eventId', isEqualTo: event.id).get();
    final notifiedUsers = shiftsQuery.docs.map((doc) => doc.data()['volunteerId'] as String).toList();

    if (reason != null && notifiedUsers.isNotEmpty) {
      await firestore.collection('cancellations').doc(event.id).set({
        'eventId': event.id,
        'eventTitle': event.title,
        'reason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
        'notifiedUsers': notifiedUsers,
      });
    } else {
        final WriteBatch batch = firestore.batch();
        for (final doc in shiftsQuery.docs) {
          batch.delete(doc.reference);
        }
        final eventRef = firestore.collection('events').doc(event.id);
        batch.delete(eventRef);
        await batch.commit();
    }
  }

  Future<void> _signUpForShift(Event event, String role) async {
    if (_currentUser == null || event.id == null) return;
    final newShift = Shift(
        eventId: event.id!,
        eventTitle: event.title,
        eventDate: event.date,
        role: role,
        volunteerId: _currentUser!.id,
        volunteerName: _currentUser!.name);
    await FirebaseFirestore.instance.collection('shifts').add(newShift.toFirestore());
  }

  Future<void> _cancelSignUp(Shift shift) async {
    if (shift.id != null) {
      await FirebaseFirestore.instance.collection('shifts').doc(shift.id).delete();
    }
  }
  
  Future<void> _updateShiftStatus(Shift shift, String status, String notes) async {
    if (shift.id != null) {
      await FirebaseFirestore.instance.collection('shifts').doc(shift.id).update({
        'status': status,
        'notes': notes,
      });
    }
  }

  void _addRole(String role) {
    if (role.isNotEmpty && !_allRoles.contains(role)) {
      setState(() => _allRoles.add(role));
    }
  }

  void _deleteRole(String role) {
    setState(() => _allRoles.remove(role));
  }

  Future<void> _updateUserProfile(String uid, String newName, List<String> newSkills) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': newName,
      'skills': newSkills,
    });
  }

  static const List<String> _widgetTitles = <String>[
    '活動列表',
    '我的班表',
    '個人資料',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final eventsStream = FirebaseFirestore.instance.collection('events').orderBy('date', descending: false).withConverter(fromFirestore: Event.fromFirestore, toFirestore: (Event e, _) => e.toFirestore()).snapshots();
    final shiftsStream = FirebaseFirestore.instance.collection('shifts').withConverter(fromFirestore: Shift.fromFirestore, toFirestore: (Shift s, _) => s.toFirestore()).snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent the UI from resizing when keyboard appears
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_widgetTitles[_selectedIndex]),
      ),
      body: StreamBuilder<List<Object>>(
        stream: CombineLatestStream.list([eventsStream, shiftsStream]),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('讀取資料時發生錯誤'));
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = (snapshot.data![0] as QuerySnapshot<Event>).docs.map((doc) => doc.data()).toList();
          final shifts = (snapshot.data![1] as QuerySnapshot<Shift>).docs.map((doc) => doc.data()).toList();

          final List<Widget> widgetOptions = <Widget>[
            EventsScreen(
              currentUser: _currentUser,
              events: events,
              shifts: shifts,
              onAddEvent: _addEvent,
              onUpdateEvent: _updateEvent,
              onDeleteEvent: _deleteEvent,
              onSignUp: _signUpForShift,
              onCancelSignUp: _cancelSignUp,
              onSendNotification: _sendNewEventNotification,
              allRoles: _allRoles,
            ),
            ScheduleScreen(
              currentUser: _currentUser,
              shifts: shifts,
              onUpdateShift: _updateShiftStatus,
            ),
            ProfileScreen(
              currentUser: _currentUser,
              allRoles: _allRoles,
              onAddRole: _addRole,
              onDeleteRole: _deleteRole,
              onUpdateProfile: _updateUserProfile,
            ),
          ];

          return Center(child: widgetOptions.elementAt(_selectedIndex));
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '活動'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: '班表'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人資料'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Changed to blue
        onTap: _onItemTapped,
      ),
    );
  }
}

class CombineLatestStream {
  static Stream<List<T>> list<T>(Iterable<Stream<T>> streams) {
    return Stream.multi((controller) {
      final List<T?> values = List<T?>.filled(streams.length, null);
      final List<bool> hasValue = List<bool>.filled(streams.length, false);
      int M = streams.length;
      int m = 0;

      for (var i = 0; i < streams.length; i++) {
        streams.elementAt(i).listen((value) {
          values[i] = value;
          if (!hasValue[i]) {
            hasValue[i] = true;
            m++;
          }
          if (m == M) controller.add(values.cast<T>());
        });
      }
    });
  }
}
