import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/http_exception.dart';
import '../contants.dart' as Constants;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavorite = false,
  });

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();

    try {
      final Uri url = Constants.getApiUrl(
          append: '/userFavorites/$userId/$id.json?auth=$token');

      final response = await http.put(
        url,
        body: json.encode(
          isFavorite,
        ),
      );

      if (response.statusCode >= 400) {
        isFavorite = oldStatus;

        print(json.decode(response.body));

        throw new HttpException(
            'Unable to update favorite status. Please try again later');
      }
    } catch (error) {
      print(error);
      isFavorite = oldStatus;
      notifyListeners();
    }
  }
}

class ProductJson {
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  ProductJson({
    this.title,
    this.description,
    this.price,
    this.imageUrl,
    this.isFavorite = false,
  });

  ProductJson.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        price = json['price'],
        imageUrl = json['imageUrl'],
        isFavorite = json['isFavorite'];
}
