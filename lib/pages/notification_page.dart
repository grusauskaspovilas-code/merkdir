import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_data.dart';

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
                              Text(
                                '${data.createdAt!.hour.toString().padLeft(2, '0')}:'
                                '${data.createdAt!.minute.toString().padLeft(2, '0')}',
                              ),
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
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Po 1 val.'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Po 2 val.'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Po 5 val.'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Po 8 val.'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Po 10 val.'),
                              onTap: () {},
                            ),

                            const Divider(),

                            ListTile(
                              leading: const Icon(Icons.today),
                              title: const Text('Rytoj'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('Kai vėl būsiu prie šios parduotuvės'),
                              onTap: () {},
                            ),

                            ListTile(
                              leading: const Icon(Icons.notifications_off),
                              title: const Text('Nebepriminti šiandien'),
                              onTap: () {},
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
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
