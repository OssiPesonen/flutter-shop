import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/http_exception.dart';

import '../contants.dart' as Constants;
import './product.dart';

class APIAddResponse {
  final String name;

  APIAddResponse(this.name);

  APIAddResponse.fromJson(Map<String, dynamic> json) : name = json['name'];
  Map<String, dynamic> toJson() => {'name': name};
}

class Products with ChangeNotifier {
  final String authenticationToken;
  final String userId;

  Products(this.authenticationToken, this.userId, this._items);

  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  /// Fetch all products and inject to state
  Future<void> fetchProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="userId"&equalTo="$userId"' : '';

    try {
      final response = await http.get(
        Constants.getApiUrl(
            append: '/products.json?auth=$authenticationToken&$filterString'),
      );

      final extractedData = json.decode(response.body) as Map<String, dynamic>;

      if (extractedData.containsKey('error')) {
        throw new HttpException("Permission denied. You must sign in first.");
      }

      final userFavoritesResponse = await http.get(Constants.getApiUrl(
        append: '/userFavorites/$userId.json?auth=$authenticationToken',
      ));

      final favoriteData =
          json.decode(userFavoritesResponse.body) as Map<String, dynamic>;

      final List<Product> loadedProducts = [];

      if (extractedData.length > 0) {
        extractedData.forEach((String productId, value) {
          final ProductJson product = ProductJson.fromJson(value);

          loadedProducts.add(
            Product(
              id: productId,
              title: product.title,
              description: product.description,
              imageUrl: product.imageUrl,
              price: product.price,
              isFavorite: favoriteData == null
                  ? false
                  : favoriteData[productId] ?? false,
            ),
          );

          _items = loadedProducts;
          notifyListeners();
        });
      }
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final response = await http.post(
        Constants.getApiUrl(append: '/products.json?auth=$authenticationToken'),
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'id': DateTime.now().toString(),
            'userId': userId
          },
        ),
      );

      final Map<String, dynamic> decoded = json.decode(response.body);
      var apiResponse = APIAddResponse.fromJson(decoded);

      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: apiResponse.name,
      );

      _items.add(newProduct);

      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);

    if (prodIndex >= 0) {
      try {
        final Uri url = Constants.getApiUrl(
            append: '/products/$id.json?auth=$authenticationToken');

        await http.patch(
          url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl
          }),
        );

        _items[prodIndex] = newProduct;

        notifyListeners();
      } catch (error) {
        throw error;
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);

    var existingProduct = _items[existingProductIndex];

    if (existingProductIndex > -1) {
      _items.removeAt(existingProductIndex);
      notifyListeners();

      await http
          .delete(Constants.getApiUrl(
              append: '/products/$id?auth=$authenticationToken'))
          .then((response) {
        if (response.statusCode >= 400) {
          _items.insert(existingProductIndex, existingProduct);

          throw HttpException(
              'Unable to delete product. Please try again later.');
        }

        existingProduct = null;
      });
    }
  }
}
