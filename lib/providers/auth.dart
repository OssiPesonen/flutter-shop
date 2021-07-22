import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/models/http_exception.dart';

import '../contants.dart' as Constants;

class Auth with ChangeNotifier {
  String _token;
  DateTime _expires;
  String _userId;
  String _refreshToken;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expires != null &&
        _expires.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }

    return null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(String email, String password, Uri url) async {
    try {
      var response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );

      var decoded = json.decode(response.body) as Map<String, dynamic>;

      if (decoded.containsKey('error')) {
        throw HttpException(decoded['error']['message']);
      }

      _userId = decoded['localId'];
      _token = decoded['idToken'];
      _refreshToken = decoded['refreshToken'];

      _expires = DateTime.now().add(Duration(
        seconds: int.parse(decoded['expiresIn']),
      ));

      _autoLogout();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      prefs.setString(
        'userData',
        json.encode({
          'token': _token,
          'userId': _userId,
          'refreshToken': _refreshToken,
          'expires': _expires.toIso8601String()
        }),
      );
    } catch (error) {
      throw error;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, Constants.signUpUrl());
  }

  Future<void> signIn(String email, String password) async {
    return _authenticate(email, password, Constants.signInUrl());
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('userData')) {
      return false;
    }

    var userData =
        json.decode(prefs.getString('userData')) as Map<String, dynamic>;

    final expiryData = DateTime.parse(userData['expires']);

    if (expiryData.isBefore(DateTime.now())) {
      return false;
    }

    _token = userData['token'];
    _refreshToken = userData['refreshToken'];
    _expires = DateTime.parse(userData['expires']);
    _userId = userData['userId'];

    notifyListeners();
    _autoLogout();
    return true;
  }

  void logout() async {
    _token = null;
    _userId = null;
    _expires = null;

    if (_authTimer != null) {
      _authTimer = null;
    }

    var prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('userData')) {
      prefs.remove('userData');
    }

    notifyListeners();
  }

  /// Automatically log user out once token expires
  /// Todo: Token should be refreshed, user should not be thrown out.
  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }

    print("Initiating autologout..");

    final int tokenExpiresIn = _expires.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: tokenExpiresIn), logout);
  }
}
