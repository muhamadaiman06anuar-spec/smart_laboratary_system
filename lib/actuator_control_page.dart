import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

final DatabaseReference actuatorRef = FirebaseDatabase.instanceFor(
  app: FirebaseDatabase.instance.app,
  databaseURL: 'https://smart-laboratory-safety-53979-default-rtdb.asia-southeast1.firebasedatabase.app',
).ref();

class ActuatorControlPage extends StatefulWidget {
  const ActuatorControlPage({super.key});

  @override
  State<ActuatorControlPage> createState() =>
      _ActuatorControlPageState();
}

class _ActuatorControlPageState
    extends State<ActuatorControlPage> {

  bool _updatingLed = false;
  bool _updatingRelay = false;

  Future<void> updateCommand(
      String actuator,
      bool value,
      ) async {
    setState(() {
      if (actuator == 'led') {
        _updatingLed = true;
      } else {
        _updatingRelay = true;
      }
    });

    try {
      await actuatorRef.child('commands/$actuator').set(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $actuator: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (actuator == 'led') {
            _updatingLed = false;
          } else {
            _updatingRelay = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Actuator Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: actuatorRef.onValue,
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

          final data = snapshot.data!.snapshot.value;

          final root = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};

          final commands = root['commands'] is Map
              ? Map<String, dynamic>.from(root['commands'])
              : <String, dynamic>{};

          final outputs = root['outputs'] is Map
              ? Map<String, dynamic>.from(root['outputs'])
              : <String, dynamic>{};

          final alerts = root['alerts'] is Map
              ? Map<String, dynamic>.from(root['alerts'])
              : <String, dynamic>{};

          final ledCommand = commands['led'] == true;
          final relayCommand = commands['relay'] == true;

          final ledOutput = outputs['led'] == true;
          final relayOutput = outputs['relay'] == true;

          final alarm =
              alerts['gas'] == true ||
                  alerts['motion'] == true ||
                  alerts['distance'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Manual Actuator Control',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Control the laboratory safety devices.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // SAFETY NOTICE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: alarm
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alarm
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alarm
                            ? Icons.warning_amber_rounded
                            : Icons.shield,
                        color: alarm
                            ? Colors.red
                            : Colors.green,
                        size: 30,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          alarm
                              ? 'SAFETY ALERT ACTIVE: Automatic actuator control has priority.'
                              : 'SYSTEM SAFE: Manual actuator control is available.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alarm
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Available Actuators',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // LED CONTROL
                _actuatorCard(
                  title: 'LED Indicator',
                  description: 'Laboratory warning LED',
                  icon: Icons.lightbulb,
                  command: ledCommand,
                  output: ledOutput,
                  loading: _updatingLed,
                  onChanged: (value) {
                    updateCommand('led', value);
                  },
                ),

                const SizedBox(height: 15),

                // RELAY CONTROL
                _actuatorCard(
                  title: 'Relay Module',
                  description: 'Connected electrical output',
                  icon: Icons.power,
                  command: relayCommand,
                  output: relayOutput,
                  loading: _updatingRelay,
                  onChanged: (value) {
                    updateCommand('relay', value);
                  },
                ),

                const SizedBox(height: 25),

                // OUTPUT STATUS
                const Text(
                  'Actual Output Status',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _statusRow('LED Output', ledOutput),
                _statusRow('Relay Output', relayOutput),

                const SizedBox(height: 15),

                Text(
                  'Note: Automatic safety activation overrides manual OFF commands.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ACTUATOR CARD
  Widget _actuatorCard({
    required String title,
    required String description,
    required IconData icon,
    required bool command,
    required bool output,
    required bool loading,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            Row(
              children: [
                Icon(
                  icon,
                  size: 35,
                  color: output ? Colors.orange : Colors.grey,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Switch(
                  value: command,
                  onChanged: onChanged,
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manual Command'),

                Text(
                  command ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: command ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Physical Output'),

                Text(
                  output ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: output ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OUTPUT STATUS ROW
  Widget _statusRow(String title, bool isOn) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: isOn ? Colors.green : Colors.grey,
            ),

            const SizedBox(width: 8),

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
    );
  }
}
