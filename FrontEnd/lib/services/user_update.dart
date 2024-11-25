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
    final url = 'https://func-fitapp-backend.azurewebsites.net/update/$userId/';  // Added trailing slash

    try {
      Map<String, dynamic> requestBody = {};
      if (email != null) requestBody['email'] = email;
      if (password != null) requestBody['password'] = password;
      if (height != null) requestBody['height'] = height;
      if (weight != null) requestBody['weight'] = weight;
      if (age != null) requestBody['age'] = age;
      if (gender != null) requestBody['gender'] = gender;

      print('Update Request URL: $url');
      print('Update Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      // Verify the update was successful by fetching updated data
      final verificationResponse = await http.get(
        Uri.parse('https://func-fitapp-backend.azurewebsites.net/users/$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Verification Response: ${verificationResponse.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update: ${response.body}');
      }
    } catch (e) {
      print('Update Error: $e');
      rethrow;
    }
  }
}
