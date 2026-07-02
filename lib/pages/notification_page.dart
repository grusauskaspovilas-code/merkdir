import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_data.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';

class NotificationPage extends StatelessWidget {
  final NotificationData data;

  const NotificationPage({
    super.key,
    required this.data,
  });

  String priorityEmoji(String priority) {
    final normalized = priority.toLowerCase();

    if (normalized == 'wichtig' || normalized == 'high') return '🔴';
    if (normalized == 'normal') return '🟡';
    return '⚪';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> scheduleReminder(
    BuildContext context,
    ReminderType type,
    String message,
  ) async {
    final scheduledAt = ReminderService.calculate(type);

    await scheduleReminderNotification(
      data: data,
      scheduledAt: scheduledAt,
    );

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 ${data.store}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏪 ${data.store}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (data.distance != null)
                        Row(
                          children: [
                            const Icon(Icons.place, size: 18),
                            const SizedBox(width: 6),
                            Text('${data.distance!.toStringAsFixed(0)} m'),
                          ],
                        ),
                      if (data.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18),
                              const SizedBox(width: 6),
                              Text(formatTime(data.createdAt!)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        data.items.length == 1
                            ? 'Reikia nupirkti 1 prekę'
                            : 'Reikia nupirkti ${data.items.length} prekes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...data.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                child: Text(priorityEmoji(item.priority)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(l10n.later),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (sheetContext) {
                      return DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.75,
                        minChildSize: 0.35,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) {
                          return SafeArea(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                const ListTile(
                                  title: Text(
                                    'Priminti dar kartą',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 30 min.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.minutes30,
                                    'Priminimas atidėtas 30 minučių',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 1 val.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.hour1,
                                    'Priminimas atidėtas 1 valandai',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 2 val.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.hours2,
                                    'Priminimas atidėtas 2 valandoms',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 5 val.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.hours5,
                                    'Priminimas atidėtas 5 valandoms',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 8 val.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.hours8,
                                    'Priminimas atidėtas 8 valandoms',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Po 10 val.'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.hours10,
                                    'Priminimas atidėtas 10 valandų',
                                  ),
                                ),

                                const Divider(),

                                ListTile(
                                  leading: const Icon(Icons.today),
                                  title: const Text('Rytoj 08:00'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.tomorrow,
                                    'Priminimas atidėtas iki rytojaus',
                                  ),
                                ),

                                ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: const Text(
                                    'Kai vėl būsiu prie šios parduotuvės',
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheetContext);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Geofence priminimas jau aktyvus',
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                ListTile(
                                  leading: const Icon(Icons.notifications_off),
                                  title: const Text('Nebepriminti šiandien'),
                                  onTap: () => scheduleReminder(
                                    sheetContext,
                                    ReminderType.ignoreToday,
                                    'Šiandien daugiau nebepriminsime',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.shoppingList);
                },
                icon: const Icon(Icons.shopping_cart),
                label: Text(l10n.toShoppingList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}