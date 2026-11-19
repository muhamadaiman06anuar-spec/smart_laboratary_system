import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

final DatabaseReference alertStatusRef = FirebaseDatabase.instanceFor(
  app: FirebaseDatabase.instance.app,
  databaseURL:
  'https://smart-laboratory-safety-53979-default-rtdb.asia-southeast1.firebasedatabase.app',
).ref();

class AlertSystemStatusPage extends StatelessWidget {
  const AlertSystemStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alert & System Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: alertStatusRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Firebase connection error'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final rawData = snapshot.data!.snapshot.value;

          final root = rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{};

          final sensors = root['sensors'] is Map
              ? Map<String, dynamic>.from(root['sensors'])
              : <String, dynamic>{};

          final alerts = root['alerts'] is Map
              ? Map<String, dynamic>.from(root['alerts'])
              : <String, dynamic>{};

          final outputs = root['outputs'] is Map
              ? Map<String, dynamic>.from(root['outputs'])
              : <String, dynamic>{};

          final wifi = root['wifi'] is Map
              ? Map<String, dynamic>.from(root['wifi'])
              : <String, dynamic>{};

          final gasAlert = alerts['gas'] == true;
          final motionAlert = alerts['motion'] == true;
          final distanceAlert = alerts['distance'] == true;

          final systemSafe =
              !gasAlert && !motionAlert && !distanceAlert;

          final gasValue = sensors['gasValue'] ?? 0;
          final distance = sensors['distance'] ?? 0;
          final motion = sensors['motion'] == true;

          final led = outputs['led'] == true;
          final relay = outputs['relay'] == true;

          final wifiConnected = wifi['connected'] == true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall Safety Status
              Card(
                color: systemSafe
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        systemSafe
                            ? Icons.verified_user
                            : Icons.warning_amber_rounded,
                        size: 55,
                        color: systemSafe
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        systemSafe ? 'SYSTEM SAFE' : 'WARNING DETECTED',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: systemSafe
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        systemSafe
                            ? 'No active safety alerts'
                            : 'One or more safety alerts are active',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Safety Alert Indicators',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _alertCard(
                'Gas Detection',
                gasAlert,
                Icons.gas_meter,
              ),

              _alertCard(
                'Motion Detection',
                motionAlert,
                Icons.directions_run,
              ),

              _alertCard(
                'Distance Detection',
                distanceAlert,
                Icons.social_distance,
              ),

              const SizedBox(height: 20),

              const Text(
                'Current Sensor Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _infoCard(
                'MQ-2 Gas Value',
                '$gasValue',
                Icons.sensors,
              ),

              _infoCard(
                'PIR Motion',
                motion ? 'MOTION DETECTED' : 'NO MOTION',
                Icons.directions_run,
              ),

              _infoCard(
                'Distance',
                '$distance cm',
                Icons.social_distance,
              ),

              const SizedBox(height: 20),

              const Text(
                'System Components',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _statusRow('Wi-Fi Connection', wifiConnected),
              _statusRow('LED Output', led),
              _statusRow('Relay Output', relay),

              const SizedBox(height: 20),

              const Text(
                'Live Status',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _alertCard(
      String title,
      bool active,
      IconData icon,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: active ? Colors.red : Colors.green,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          active ? 'ACTIVE' : 'NORMAL',
          style: TextStyle(
            color: active ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String title, bool active) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_circle : Icons.cancel,
              color: active ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(active ? 'ON' : 'OFF'),
          ],
        ),
      ),
    );
  }
}
