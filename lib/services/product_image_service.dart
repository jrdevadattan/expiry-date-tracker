import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductImageService {
  // Search for product image using DuckDuckGo or similar free API
  static Future<String?> searchProductImage(String productName) async {
    try {
      // Use DuckDuckGo Instant Answer API (free, no API key required)
      final query = Uri.encodeComponent('$productName product');
      final url = 'https://api.duckduckgo.com/?q=$query&format=json&t=expirytracker';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Try to get image from various sources
        if (data['Image'] != null && (data['Image'] as String).isNotEmpty) {
          return data['Image'];
        }
        
        // Try RelatedTopics
        if (data['RelatedTopics'] != null) {
          final topics = data['RelatedTopics'] as List;
          for (var topic in topics) {
            if (topic is Map && topic['Icon'] != null) {
              final icon = topic['Icon'] as Map;
              if (icon['URL'] != null && (icon['URL'] as String).isNotEmpty) {
                final imageUrl = icon['URL'] as String;
                if (imageUrl.startsWith('http')) {
                  return imageUrl;
                }
              }
            }
          }
        }
      }
      
      // Fallback: Use placeholder image service
      return _getPlaceholderImage(productName);
    } catch (e) {
      print('Error fetching product image: $e');
      return _getPlaceholderImage(productName);
    }
  }
  
  static String _getPlaceholderImage(String productName) {
    // Use a placeholder service with product name
    final encoded = Uri.encodeComponent(productName);
    return 'https://via.placeholder.com/400x400.png?text=$encoded';
  }
  
  // Enhanced search using multiple sources
  static Future<ProductInfo?> searchProduct(String productName) async {
    try {
      final imageUrl = await searchProductImage(productName);
      
      return ProductInfo(
        name: productName,
        imageUrl: imageUrl,
        description: null,
      );
    } catch (e) {
      print('Error searching product: $e');
      return null;
    }
  }
}

class ProductInfo {
  final String name;
  final String? imageUrl;
  final String? description;
  
  ProductInfo({
    required this.name,
    this.imageUrl,
    this.description,
  });
}
