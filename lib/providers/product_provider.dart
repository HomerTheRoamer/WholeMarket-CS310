
import '../models/product.dart';

class ProductProvider {
  final List<Product> _products = [];

  List<Product> get products => _products;

  void addProduct(Product product) {
    _products.add(product);
  }

  void updateProduct(Product updatedProduct) {
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].id == updatedProduct.id) {
        _products[i] = updatedProduct;
        break;
      }
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((product) => product.id == id);
  }

  Product? getProductById(String id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  List<Product> get expiringSoonProducts {
    return _products.where((product) {
      return product.isExpiringSoon;
    }).toList();
  }

  List<Product> get expiredProducts {
    return _products.where((product) {
      return product.isExpired;
    }).toList();
  }
}
