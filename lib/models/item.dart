class Item {
  int? id;
  String name;
  String itemType;
  String quantity; // e.g. "1L" or "14 ounces (414ml)"
  String category; // 'packaged' or 'fresh'
  String foodType; // 'dry' or 'wet'
  DateTime purchased;
  DateTime expiry;
  String? imagePath;

  Item({
    this.id,
    required this.name,
    required this.itemType,
    required this.quantity,
    this.category = 'packaged',
    this.foodType = 'dry',
    required this.purchased,
    required this.expiry,
    this.imagePath,
  });

  factory Item.fromMap(Map<String, dynamic> m) => Item(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
    itemType: m['itemType'] as String? ?? '',
    quantity: m['quantity'] as String? ?? '',
    category: m['category'] as String? ?? 'packaged',
    foodType: m['foodType'] as String? ?? 'dry',
    purchased: DateTime.fromMillisecondsSinceEpoch(m['purchased'] as int),
    expiry: DateTime.fromMillisecondsSinceEpoch(m['expiry'] as int),
    imagePath: m['imagePath'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'itemType': itemType,
        'quantity': quantity,
    'category': category,
    'foodType': foodType,
        'purchased': purchased.millisecondsSinceEpoch,
        'expiry': expiry.millisecondsSinceEpoch,
        'imagePath': imagePath,
      };
}
