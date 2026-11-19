import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveMonitoringPage extends StatefulWidget {
  const LiveMonitoringPage({super.key});

  @override
  State<LiveMonitoringPage> createState() =>
      _LiveMonitoringPageState();
}

class _LiveMonitoringPageState extends State<LiveMonitoringPage> {
  final DatabaseReference databaseRef =
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://smart-laboratory-safety-53979-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  Map<String, dynamic> toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Widget sensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$value $unit',
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sensor Monitoring'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Firebase connection error'));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final root = toMap(snapshot.data!.snapshot.value);
          final sensors = toMap(root['sensors']);
          final alerts = toMap(root['alerts']);

          final gas = sensors['gas'] ?? 0;
          final motion = sensors['motion'] ?? false;
          final distance = sensors['distance'] ?? 0;

          final gasAlert = alerts['gas'] == true;
          final motionAlert = alerts['motion'] == true;
          final distanceAlert = alerts['distance'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real-Time Sensor Readings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                sensorCard(
                  title: 'MQ-2 Gas Sensor',
                  value: '$gas',
                  unit: 'ADC',
                  icon: Icons.air,
                  color: gasAlert ? Colors.red : Colors.green,
                  status: gasAlert ? 'GAS WARNING' : 'NORMAL',
                ),

                sensorCard(
                  title: 'PIR Motion Sensor',
                  value: motion == true ? 'DETECTED' : 'NONE',
                  unit: '',
                  icon: Icons.directions_walk,
                  color: motionAlert ? Colors.red : Colors.green,
                  status:
                  motionAlert ? 'MOTION DETECTED' : 'NO MOTION',
                ),

                sensorCard(
                  title: 'HC-SR04 Distance Sensor',
                  value: '$distance',
                  unit: 'cm',
                  icon: Icons.social_distance,
                  color: distanceAlert ? Colors.red : Colors.green,
                  status:
                  distanceAlert ? 'OBJECT TOO CLOSE' : 'NORMAL',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
