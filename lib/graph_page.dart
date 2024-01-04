import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:firebase_database/firebase_database.dart';
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
  bool isLoading = false;
  String result = '';

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
            SizedBox(
              height: 200,
              width: 400,
              child: Center(
                child: Sparkline(
                  backgroundColor: Colors.grey,
                  fillColor: Colors.red,
                  data: lastFiveData,
                ),
              ),
            ),
            Text('$lastFiveData'),
            ElevatedButton(
              onPressed: () async {
                try {
                  double minValue = exactValues.reduce((a, b) => a < b ? a : b);
                  double maxValue = exactValues.reduce((a, b) => a > b ? a : b);

                  // Normalize data between 0 and 1
                  List<double> normalizedData = data
                      .map((value) => normalizeData(value, minValue, maxValue))
                      .toList();
                  if (kDebugMode) {
                    print('$normalizedData');
                  }

                  setState(() {
                    isLoading =
                        true; // Set loading to true before making the request
                  });

                  // Send the predefined data (noob) to the Flask server
                  final response = await http.post(
                    Uri.parse('http://10.176.240.78:5000/predict'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'data': normalizedData}),
                  );

                  if (response.statusCode == 200) {
                    var predictionResult = jsonDecode(response.body)['result'];
                    setState(() {
                      result = predictionResult.toString();
                      isLoading =
                          false; // Set loading to false after getting the result
                    });
                    if (kDebugMode) {
                      print('Prediction result: $result');
                    }
                  } else {
                    if (kDebugMode) {
                      print(
                          'Failed to connect to the Flask server. Status code: ${response.statusCode}');
                    }
                    if (kDebugMode) {
                      print('Server response: ${response.body}');
                    }
                    setState(() {
                      isLoading =
                          false; // Set loading to false in case of an error
                    });
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error connecting to the Flask server: $e');
                  }
                  setState(() {
                    isLoading =
                        false; // Set loading to false in case of an exception
                  });
                }
              },
              child: const Text('Predict'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Text('result: ${result.toString()}'),
          ],
        ),
      ),
    );
  }
}
