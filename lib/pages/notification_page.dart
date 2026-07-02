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
                      const SizedBox(height: 12),
                      Text(l10n.openShopping),
                      const SizedBox(height: 16),
                      ...data.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                priorityEmoji(item.priority),
                                style: const TextStyle(fontSize: 20),
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
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.later),
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
