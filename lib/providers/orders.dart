import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/providers/products.dart';
import '../contants.dart' as Constants;

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  final String authToken;
  final String userId;

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    print(authToken);

    final response = await http.get(
        Constants.getApiUrl(append: '/orders/$userId.json?auth=$authToken'));
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;

    if (extractedData.length > 0) {
      extractedData.forEach((orderId, orderData) {
        loadedOrders.add(
          OrderItem(
            id: orderId,
            amount: orderData['amount'] is int
                ? orderData['amount'].toDouble()
                : orderData['amount'],
            products: (orderData['products'] as List<dynamic>)
                .map(
                  (item) => CartItem(
                    id: item['id'],
                    price: item['price'],
                    quantity: item['quantity'],
                    title: item['title'],
                  ),
                )
                .toList(),
            dateTime: DateTime.parse(orderData['dateTime']),
          ),
        );
      });
    }

    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final DateTime timestamp = DateTime.now();

    final response = await http.post(
      Constants.getApiUrl(append: '/orders/$userId.json?auth=$authToken'),
      body: json.encode({
        'total': total,
        'dateTime': timestamp.toIso8601String(),
        'products': cartProducts
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'quantity': e.quantity,
                'price': e.price,
              },
            )
            .toList()
      }),
    );

    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    var apiResponse = APIAddResponse.fromJson(extractedData);

    _orders.insert(
      0,
      OrderItem(
        id: apiResponse.name,
        amount: total,
        dateTime: timestamp,
        products: cartProducts,
      ),
    );

    notifyListeners();
  }
}
