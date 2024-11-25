import 'dart:convert';


import 'package:http/http.dart' as http;

class UserUpdate {
  Future<void> updateUser({
    required int userId,
    String? email,
    String? password,
    double? height,
    double? weight,
    int? age,
    String? gender,
  }) async {
    try {
      final baseUrl = 'https://func-fitapp-backend.azurewebsites.net/update/$userId';

      // Build query parameters
      final queryParameters = <String, String>{};
      if (email != null) queryParameters['email'] = email;
      if (password != null) queryParameters['password'] = password;
      if (height != null) queryParameters['height'] = height.toString();
      if (weight != null) queryParameters['weight'] = weight.toString();
      if (age != null) queryParameters['age'] = age.toString();
      if (gender != null) queryParameters['gender'] = gender;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

      print('Update Request URL: $uri');

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update Error: $e');
      rethrow;
    }
  }
}
