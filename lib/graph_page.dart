import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({
    super.key,
  });

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<double> data = [1];
  final databaseReference = FirebaseDatabase.instance.ref().child('ecg/data');
  late StreamSubscription subscription;
  late Timer timer;
  late Future<void> fetchDataFuture;

  @override
  void initState() {
    super.initState();

    fetchDataFuture = fetchData();

    // Set up a timer to fetch data every 500ms
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    // Fetch data from the database
    subscription = databaseReference.onValue.listen((event) {
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
        child: FutureBuilder(
          future: fetchDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Lottie.asset(
                  'assets/loading.json'); // Adjust the path based on your asset location
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Sparkline(
                      key: UniqueKey(),
                      data: data,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
