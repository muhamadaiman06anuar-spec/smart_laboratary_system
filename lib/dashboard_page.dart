import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ===== FIREBASE DATABASE =====
final DatabaseReference databaseRef = FirebaseDatabase.instanceFor(
  app: FirebaseDatabase.instance.app,
  databaseURL:
  'https://smart-laboratory-safety-53979-default-rtdb.asia-southeast1.firebasedatabase.app',
).ref();

// ===== CONVERT FIREBASE DATA =====
Map<String, dynamic> toMap(dynamic value) {
  if (value is Map) {
    return value.map(
          (key, value) => MapEntry(key.toString(), value),
    );
  }
  return {};
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Lab Safety',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
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

          final root = toMap(snapshot.data!.snapshot.value);

          final sensors = toMap(root['sensors']);
          final alerts = toMap(root['alerts']);
          final outputs = toMap(root['outputs']);

          final gasValue =
              (sensors['gas'] as num?)?.toInt() ?? 0;

          final motion =
              sensors['motion'] == true;

          final distance =
          (sensors['distance'] as num?)?.toDouble();

          final gasAlert =
              alerts['gas'] == true;

          final motionAlert =
              alerts['motion'] == true;

          final distanceAlert =
              alerts['distance'] == true;

          final led =
              outputs['led'] == true;

          final relay =
              outputs['relay'] == true;

          final wifi =
              root['wifi']?.toString() ?? 'UNKNOWN';

          final alarm =
              gasAlert || motionAlert || distanceAlert;

          final systemStatus =
              alerts['status']?.toString() ??
                  (alarm ? 'WARNING' : 'SAFE');

          final screenWidth = MediaQuery.of(context).size.width;

          final columns = screenWidth >= 1000
              ? 3
              : screenWidth >= 600
              ? 2
              : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== WELCOME =====
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Smart Laboratory Safety Monitoring System',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SYSTEM STATUS =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: alarm
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: alarm
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            alarm
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user,
                            color: alarm
                                ? Colors.red
                                : Colors.green,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SYSTEM STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        systemStatus,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: alarm
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        alarm
                            ? 'Safety alert detected. Check the laboratory.'
                            : 'All monitored conditions are normal.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ===== SENSOR SECTION =====
                const Text(
                  'Sensor Readings',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio:
                  screenWidth < 600 ? 1.65 : 1.8,
                  children: [
                    _sensorCard(
                      title: 'MQ-2 Gas Sensor',
                      value: '$gasValue',
                      subtitle: 'Gas concentration value',
                      icon: Icons.air,
                      alert: gasAlert,
                      alertText: 'GAS DETECTED',
                    ),

                    _sensorCard(
                      title: 'PIR Motion Sensor',
                      value: motion ? 'DETECTED' : 'CLEAR',
                      subtitle: 'Motion detection',
                      icon: Icons.directions_walk,
                      alert: motionAlert,
                      alertText: 'MOTION DETECTED',
                    ),

                    _sensorCard(
                      title: 'Ultrasonic Sensor',
                      value: distance == null
                          ? 'NO ECHO'
                          : '${distance.toStringAsFixed(2)} cm',
                      subtitle: 'Object distance',
                      icon: Icons.social_distance,
                      alert: distanceAlert,
                      alertText: 'OBJECT TOO CLOSE',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ===== OUTPUT SECTION =====
                const Text(
                  'Actuator Status',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: screenWidth < 600 ? 2 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _outputCard(
                      title: 'LED',
                      isOn: led,
                      icon: Icons.lightbulb,
                    ),

                    _outputCard(
                      title: 'Relay',
                      isOn: relay,
                      icon: Icons.power,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ===== WIFI STATUS =====
                const Text(
                  'Connection Status',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      wifi.toUpperCase() == 'CONNECTED'
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color:
                      wifi.toUpperCase() == 'CONNECTED'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: const Text('ESP32 Wi-Fi'),
                    subtitle: Text(wifi),
                    trailing: Icon(
                      Icons.circle,
                      size: 12,
                      color:
                      wifi.toUpperCase() == 'CONNECTED'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== SENSOR CARD =====
  Widget _sensorCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required bool alert,
    required String alertText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: alert ? Colors.red : Colors.blue,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: alert ? Colors.red : Colors.green,
              ),
            ),

            Text(
              alert ? alertText : subtitle,
              style: TextStyle(
                fontSize: 11,
                color: alert ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== OUTPUT CARD =====
  Widget _outputCard({
    required String title,
    required bool isOn,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: isOn ? Colors.orange : Colors.grey,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOn ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
