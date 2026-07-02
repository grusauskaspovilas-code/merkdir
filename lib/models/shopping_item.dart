class ShoppingItem {
  String name;
  List<String> stores;
  bool bought;
  String priority;

  ShoppingItem({
    required this.name,
    required this.stores,
    required this.priority,
    this.bought = false,
  });
}
