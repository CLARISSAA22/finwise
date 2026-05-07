import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier 
{
  String baseUrl = ApiConstants.baseUrl; //base url of the backend
  String? _token; //token of the user
  User? _user; //user object

  String? get token => _token; //getter for token
  User? get currentUser => _user; //getter for user
  bool get isAuthenticated => _token != null; //getter for authentication status

  Future<void> loadToken() async 
  {
    final prefs = await SharedPreferences.getInstance(); //get the shared preferences
    _token = prefs.getString('jwt_token'); //get the token from shared preferences
    if (_token != null) //if the token is not null
    {
      await fetchProfile();
    }
  }
  // Stores the last login error so the UI can show a specific message
  String _lastLoginError = '';//last login error
  String get lastLoginError => _lastLoginError;//getter for last login error

  Future<bool> login(String email, String password) async
  {
    _lastLoginError = '';//clear the last login error
    try {
      debugPrint('Attempting Login at $baseUrl/login...'); //debug print for login
      final res = await http.post(
        Uri.parse('$baseUrl/login'), //url to post the login credentials
        headers: {'Content-Type': 'application/json'},//content type of the request
        body: jsonEncode({'email': email, 'password': password}),//body of the request
      ).timeout(const Duration(seconds: 60));
      
      debugPrint('Login Status: ${res.statusCode}'); //status code of the request
      if (res.statusCode == 200) //if the status code is 200
      {
        final data = jsonDecode(res.body);//decode the response body
        _token = data['token'];//get the token from the response body
        final prefs = await SharedPreferences.getInstance();//get the shared preferences
        await prefs.setString('jwt_token', _token!);//store the token in shared preferences
        await fetchProfile();//fetch the profile
        return true;
      }
      else if (res.statusCode == 401) //if the status code is 401
      {
        _lastLoginError = 'Wrong email or password.';//wrong email or password
      } 
      else
      {
        _lastLoginError = 'Server error (${res.statusCode}). Try again.';//server error
      }
    } 
    on Exception catch (e) //catch the exception
    {
      debugPrint('Login Error: $e');
      _lastLoginError = 'Cannot connect to server.\nMake sure the backend is running and your IP/USB is correct in constants.dart';//server error
    }
    return false;
  }
  //register function
  Future<String?> register(String name, String email, String password) async 
  {
    try 
    {
      debugPrint('Attempting Registration at $baseUrl/register...');//debug print for registration
      final res = await http.post(
        Uri.parse('$baseUrl/register'),//url to post the registration credentials
        headers: {'Content-Type': 'application/json'},//content type of the request
        body: jsonEncode({'name': name, 'email': email, 'password': password}),//body of the request
      ).timeout(const Duration(seconds: 60));//timeout for the request
      debugPrint('Registration Status: ${res.statusCode}');//status code of the request
      debugPrint('Registration Body: ${res.body}');
      if (res.statusCode == 201) 
      {
        return null; // Success
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Registration failed';
    } 
    catch (e) 
    {
      debugPrint('Registration Error: $e');
      return 'Could not connect to server. Check your IP and Firewall.';
    }
  }

  // reset password function
  Future<String?> resetPassword(String email, String newPassword) async 
  {
    try 
    {
      debugPrint('Attempting Password Reset at $baseUrl/reset-password...');
      final res = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'new_password': newPassword}),
      ).timeout(const Duration(seconds: 60));
      
      if (res.statusCode == 200) 
      {
        return null; // Success
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Password reset failed';
    } 
    catch (e) 
    {
      debugPrint('Reset Password Error: $e');
      return 'Could not connect to server.';
    }
  }

  //fetch profile function
  Future<void> fetchProfile() async
  {
    if (_token == null) 
    {
      return; //return if token is null
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) 
      {
        _user = User.fromJson(jsonDecode(res.body));
        notifyListeners();
      } 
      else 
      {
        await logout(); // Token might be expired
      }
    } 
    catch (e) 
    {
      print(e);
    }
  }
  //update profile function
  Future<bool> updateProfile({String? name, String? upiId}) async 
  {
    if (_token == null) 
    {
      return false; //return false if token is null
    }
    try 
    {
      final res = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode(
          {
          if (name != null) 'name': name,
          if (upiId != null) 'upi_id': upiId,
          }
        ),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) 
      {
        await fetchProfile();
        return true;
      }
    } 
    catch (e) 
    {
      print(e);
    }
    return false;
  }
  //logout function
  Future<void> logout() async 
  {
    _token = null; //set token to null
    _user = null; //set user to null
    final prefs = await SharedPreferences.getInstance();//get the shared preferences
    await prefs.remove('jwt_token'); //remove the token from shared preferences
    notifyListeners(); //notify the listeners
  }
}