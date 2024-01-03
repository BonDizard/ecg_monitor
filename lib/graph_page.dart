import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GraphPage extends StatefulWidget {
  const GraphPage({Key? key}) : super(key: key);

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<double> data = [];
  List<double> lastFiveData = [];
  List<double> exactValues = [];
  final databaseReference = FirebaseDatabase.instance.ref().child('ecg/sensor');
  late StreamSubscription subscription;

  // Function to normalize data between 0 and 1
  double normalizeData(double value, double minValue, double maxValue) {
    // Avoid division by zero
    if (minValue == maxValue) {
      return 0.0;
    }
    return (value - minValue) / (maxValue - minValue);
  }

  Future<void> fetchData() async {
    subscription = databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        double newValue = (event.snapshot.value as num).toDouble();
        exactValues.add(newValue);

        setState(() {
          data.add(newValue);
        });

        // Keep only the last 10 values
        if (data.length > 10) {
          lastFiveData = data.sublist(data.length - 10);
        } else {
          lastFiveData = List.from(data);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Sparkline(data: lastFiveData),
            ),
            Text('$lastFiveData'),
            ElevatedButton(
              onPressed: () async {
                double minValue = exactValues.reduce((a, b) => a < b ? a : b);
                double maxValue = exactValues.reduce((a, b) => a > b ? a : b);
                // Normalize data between 0 and 1
                List<double> normalizedData = data
                    .map((value) => normalizeData(value, minValue, maxValue))
                    .toList();
                print('$normalizedData');
                // Send the normalized data to the Flask server
                final response = await http.post(
                  Uri.parse(
                      'http://localhost:5000/predict'), // Adjust the port if needed
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'data': normalizedData}),
                );

                if (response.statusCode == 200) {
                  // Handle the response from the Flask server
                  var result = jsonDecode(response.body)['result'];
                  print('Prediction result: $result');
                } else {
                  print('Failed to connect to the Flask server');
                }
                print('$normalizedData');
              },
              child: const Text('Predict'),
            )
          ],
        ),
      ),
    );
  }
}
