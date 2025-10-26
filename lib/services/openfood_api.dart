import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodProduct {
  final String? name;
  final String? imageUrl;
  final Map<String, dynamic>? raw;

  OpenFoodProduct({this.name, this.imageUrl, this.raw});
}

class OpenFoodApi {
  /// Fetch product data from Open Food Facts by barcode (EAN/UPC).
  static Future<OpenFoodProduct?> fetchProduct(String barcode) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      if (map['status'] == 0) return null;
      final product = map['product'] as Map<String, dynamic>;
      final name = product['product_name'] as String? ?? product['generic_name'] as String?;
      final imageUrl = product['image_url'] as String? ?? product['image_small_url'] as String?;
      return OpenFoodProduct(name: name, imageUrl: imageUrl, raw: product);
    } catch (_) {
      return null;
    }
  }
}
