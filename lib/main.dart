import 'dart:async';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double> data = [1];
  final databaseReference = FirebaseDatabase.instance.ref().child('ecg/data');
  late StreamSubscription subscription; // Change DatabaseEvent to Event
  late Timer timer;

  @override
  void initState() {
    super.initState();

    // Set up a timer to fetch data every 500ms
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      fetchData();
    });
  }

  void fetchData() {
    // Fetch data from the database
    subscription = databaseReference.onValue.listen((event) {
      // Change DatabaseEvent to Event
      if (event.snapshot.value != null) {
        // Update the UI with the fetched data
        setState(() {
          data.add((event.snapshot.value as num).toDouble());
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer and unsubscribe from the database when the widget is disposed
    timer.cancel();
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'ECG monitor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Sparkline(
                key: UniqueKey(), // Add a unique key to force widget rebuild
                data: data,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
