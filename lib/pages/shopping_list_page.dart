import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/shopping_item.dart';
import '../services/shopping_list_service.dart';
import '../services/store_service.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final controller = TextEditingController();

  List<String> selectedStores = [];
  String selectedPriority = 'Normal';

  void addItem() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      shoppingList.add(
        ShoppingItem(
          name: controller.text.trim(),
          stores: List.from(selectedStores),
          priority: selectedPriority,
        ),
      );
    });

    saveShoppingList();

    controller.clear();
    selectedStores.clear();
  }

  void addStore() {
    print('ADD STORE PRESSED');
    print(controller.text);

    if (controller.text.trim().isEmpty) return;

    setState(() {
      if (!availableStores.contains(controller.text.trim())) {
        availableStores.add(controller.text.trim());
        print('STORE ADDED');
      }
    });

    saveAvailableStores();

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.shoppingList,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.product,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          DropdownButton<String>(     
            value: selectedPriority,
            items: const [
              DropdownMenuItem(
                value: 'Wichtig',
                child: Text('🔴 Wichtig'),
              ),
              DropdownMenuItem(
                value: 'Normal',
                child: Text('🟡 Normal'),
              ),
              DropdownMenuItem(
                value: 'Später',
                child: Text('⚪ Später'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedPriority = value!;
              });
            },
          ),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: addItem,
                  child: Text(
                    AppLocalizations.of(context)!.addProduct,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: addStore,
                  child: Text(
                    AppLocalizations.of(context)!.addStore,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.stores,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: availableStores.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
              ),
              itemBuilder: (context, index) {
                final store = availableStores[index];

                return Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        dense: true,
                        title: Text(
                          store,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selectedStores.contains(store),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedStores.add(store);
                            } else {
                              selectedStores.remove(store);
                            }
                          });
                        },
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          availableStores.remove(store);
                          selectedStores.remove(store);
                        });

                        saveAvailableStores();
                      },
                    ),
                  ],
                );
              },
            ),
          ),



          Expanded(
            child: ListView.builder(
              itemCount: shoppingList.length,
              itemBuilder: (context, index) {
                final item = shoppingList[index];

                return CheckboxListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.bought
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                      color: item.bought ? Colors.grey : null,
                    ),
                  ),

                  subtitle: Text(
                    '🏪 ${item.stores.join(", ")}',
                  ),

                  secondary: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      setState(() {
                        shoppingList.removeAt(index);
                      });

                      await saveShoppingList();
                    },
                  ),

                  value: item.bought,

                  onChanged: (value) async {
                    setState(() {
                      item.bought = value ?? false;
                    });

                    await saveShoppingList();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
