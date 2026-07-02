import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.notificationSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.notificationDistance,
            ),

            DropdownButton<double>(
              value: notificationDistance,
              isExpanded: true,
              items: const [

                DropdownMenuItem(
                  value: 30,
                  child: Text('30 m'),
                ),

                DropdownMenuItem(
                  value: 50,
                  child: Text('50 m'),
                ),

                DropdownMenuItem(
                  value: 100,
                  child: Text('100 m'),
                ),

                DropdownMenuItem(
                  value: 200,
                  child: Text('200 m'),
                ),

                DropdownMenuItem(
                  value: 300,
                  child: Text('300 m'),
                ),

                DropdownMenuItem(
                  value: 500,
                  child: Text('500 m'),
                ),

                DropdownMenuItem(
                  value: 750,
                  child: Text('750 m'),
                ),

                DropdownMenuItem(
                  value: 1000,
                  child: Text('1000 m'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  notificationDistance = value;
                });

                await saveNotificationSettings();
              },
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.checkInterval,
            ),

            DropdownButton<int>(
              value: checkIntervalMinutes,
              isExpanded: true,
              items: const [

                DropdownMenuItem(
                  value: 1,
                  child: Text('1 min'),
                ),

                DropdownMenuItem(
                  value: 2,
                  child: Text('2 min'),
                ),

                DropdownMenuItem(
                  value: 5,
                  child: Text('5 min'),
                ),

                DropdownMenuItem(
                  value: 10,
                  child: Text('10 min'),
                ),

                DropdownMenuItem(
                  value: 15,
                  child: Text('15 min'),
                ),

                DropdownMenuItem(
                  value: 30,
                  child: Text('30 min'),
                ),

                DropdownMenuItem(
                  value: 60,
                  child: Text('60 min'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  checkIntervalMinutes = value;
                });

                await saveNotificationSettings();
              },
            ),

            const Divider(height: 40),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                AppLocalizations.of(context)!.aboutApp,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ℹ️ MerkDir™'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.version} 1.0',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${AppLocalizations.of(context)!.createdBy}: Povilas Grušauskas',
                        ),
                        const SizedBox(height: 10),
                        const Text('© 2025 Povilas Grušauskas'),
                        Text(
                          AppLocalizations.of(context)!.allRightsReserved,
                        ),
                      ],
                    ),
                  ),
                );
                
              },
            )
          ],
        ),
      ),
      ),
    );
  }
}
