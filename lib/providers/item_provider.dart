import 'package:flutter/foundation.dart';
import 'package:tracker/data/db_helper.dart';
import 'package:tracker/models/item.dart';

// Simple heuristics to auto-categorize items
class ItemCategorizer {
  static String categorizeCategory(String name, String itemType) {
    final n = (name + ' ' + itemType).toLowerCase();
    final freshKeywords = ['apple', 'banana', 'orange', 'tomato', 'lettuce', 'carrot', 'spinach', 'potato', 'fruit', 'vegetable'];
    for (final k in freshKeywords) if (n.contains(k)) return 'fresh';
    return 'packaged';
  }

  static String categorizeFoodType(String name, String itemType) {
    final n = (name + ' ' + itemType).toLowerCase();
    final wetKeywords = ['milk', 'yogurt', 'juice', 'soup', 'broth', 'canned', 'sauce', 'honey', 'oil'];
    for (final k in wetKeywords) if (n.contains(k)) return 'wet';
    return 'dry';
  }
}

class ItemProvider extends ChangeNotifier {
  List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);

  Future<void> loadItems() async {
    _items = await DBHelper.instance.getItems();
    notifyListeners();
  }

  Future<void> addItem(Item item) async {
    // auto-categorize if not provided or default values
    try {
      if (item.category.isEmpty || item.category == 'packaged') {
        item.category = ItemCategorizer.categorizeCategory(item.name, item.itemType);
      }
      if (item.foodType.isEmpty || item.foodType == 'dry') {
        item.foodType = ItemCategorizer.categorizeFoodType(item.name, item.itemType);
      }
    } catch (_) {}
    await DBHelper.instance.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    try {
      if (item.category.isEmpty || item.category == 'packaged') {
        item.category = ItemCategorizer.categorizeCategory(item.name, item.itemType);
      }
      if (item.foodType.isEmpty || item.foodType == 'dry') {
        item.foodType = ItemCategorizer.categorizeFoodType(item.name, item.itemType);
      }
    } catch (_) {}
    await DBHelper.instance.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await DBHelper.instance.deleteItem(id);
    await loadItems();
  }
}
