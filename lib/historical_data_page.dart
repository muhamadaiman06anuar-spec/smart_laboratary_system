import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

final DatabaseReference historyRef = FirebaseDatabase.instanceFor(
  app: FirebaseDatabase.instance.app,
  databaseURL:
  'https://smart-laboratory-safety-53979-default-rtdb.asia-southeast1.firebasedatabase.app',
).ref().child('history');

class HistoricalDataPage extends StatelessWidget {
  const HistoricalDataPage({super.key});

  int getTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String formatDate(dynamic timestamp) {
    final milliseconds = getTimestamp(timestamp);

    if (milliseconds == 0) {
      return 'Time unavailable';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute:$second';
  }

  Color eventColor(String type) {
    switch (type.toUpperCase()) {
      case 'MOTION':
        return Colors.orange;
      case 'DISTANCE':
        return Colors.red;
      case 'GAS':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData eventIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MOTION':
        return Icons.directions_run;
      case 'DISTANCE':
        return Icons.social_distance;
      case 'GAS':
        return Icons.gas_meter;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historical Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: historyRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load historical data'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final rawData = snapshot.data?.snapshot.value;

          if (rawData == null || rawData is! Map) {
            return const Center(
              child: Text('No historical records available'),
            );
          }

          final records = <Map<String, dynamic>>[];

          rawData.forEach((key, value) {
            if (value is Map) {
              final record = Map<String, dynamic>.from(value);

              record['id'] = key.toString();
              records.add(record);
            }
          });

          records.sort((a, b) {
            return getTimestamp(b['timestamp'])
                .compareTo(getTimestamp(a['timestamp']));
          });

          final motionCount = records.where((record) {
            return (record['type'] ?? '').toString().toUpperCase() ==
                'MOTION';
          }).length;

          final distanceCount = records.where((record) {
            return (record['type'] ?? '').toString().toUpperCase() ==
                'DISTANCE';
          }).length;

          final gasCount = records.where((record) {
            return (record['type'] ?? '').toString().toUpperCase() ==
                'GAS';
          }).length;

          final totalEvents = records.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Event Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Total Events',
                      totalEvents.toString(),
                      Icons.history,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      'Motion',
                      motionCount.toString(),
                      Icons.directions_run,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Distance',
                      distanceCount.toString(),
                      Icons.social_distance,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      'Gas',
                      gasCount.toString(),
                      Icons.gas_meter,
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Event Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _eventBar(
                'Motion Events',
                motionCount,
                totalEvents,
                Colors.orange,
              ),

              _eventBar(
                'Distance Events',
                distanceCount,
                totalEvents,
                Colors.red,
              ),

              _eventBar(
                'Gas Events',
                gasCount,
                totalEvents,
                Colors.deepOrange,
              ),

              const SizedBox(height: 24),

              const Text(
                'Historical Records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (records.isEmpty)
                const Center(
                  child: Text('No records found'),
                ),

              ...records.map((record) {
                final type =
                (record['type'] ?? 'UNKNOWN').toString();

                final message =
                (record['message'] ?? 'No message').toString();

                final timestamp = record['timestamp'];

                final color = eventColor(type);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(
                        eventIcon(type),
                        color: color,
                      ),
                    ),
                    title: Text(
                      message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${type.toUpperCase()} • ${formatDate(timestamp)}',
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventBar(
      String title,
      int count,
      int total,
      Color color,
      ) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
