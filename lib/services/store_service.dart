import 'package:shared_preferences/shared_preferences.dart';

List<String> availableStores = [
  'Lidl',
  'Aldi',
  'Rewe',
  'Edeka',
  'Coop',
  'Migros',
  'Denner',
];

Future<void> saveAvailableStores() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setStringList(
    'availableStores',
    availableStores,
  );
}

Future<void> loadAvailableStores() async {
  final prefs = await SharedPreferences.getInstance();

  final data = prefs.getStringList('availableStores');

  if (data == null) {
    availableStores = [
      'Lidl',
      'Aldi',
      'Rewe',
      'Edeka',
      'Coop',
      'Migros',
      'Denner',
    ];

    await saveAvailableStores();
    return;
  }

  availableStores = List<String>.from(data);
}
