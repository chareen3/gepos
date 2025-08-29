import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../Model/currency_model.dart';

class CurrencyRepo {
  Future<List<CurrencyModel>> fetchAllCurrency() async {
    final uri = Uri.parse('${APIConfig.url}/currencies');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      
      // Laravel API returns: {"message": "...", "data": [...]}
      if (parsedData is Map<String, dynamic> && parsedData.containsKey('data')) {
        final responseData = parsedData['data'];
        
        List<dynamic> currencyList;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          // Paginated response
          currencyList = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // Direct array response
          currencyList = responseData;
        } else {
          throw Exception('Invalid currency data structure: ${responseData.runtimeType}');
        }
        
        // Filter and map the list
        return currencyList
            .where((category) => category['status'] == true) // Filter by status
            .map((category) => CurrencyModel.fromJson(category))
            .toList();
      } else {
        throw Exception('Invalid API response structure: ${parsedData.runtimeType}');
      }
    } else {
      throw Exception('Failed to fetch Currency');
    }
  }

  // Future<List<CurrencyModel>> fetchAllCurrency() async {
  //   final uri = Uri.parse('${APIConfig.url}/currencies');
  //
  //   final response = await http.get(uri, headers: {
  //     'Accept': 'application/json',
  //     'Authorization': await getAuthToken(),
  //   });
  //
  //   if (response.statusCode == 200) {
  //     final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
  //
  //     final partyList = parsedData['data'] as List<dynamic>;
  //     return partyList.map((category) => CurrencyModel.fromJson(category)).toList();
  //     // Parse into Party objects
  //   } else {
  //     throw Exception('Failed to fetch Currency');
  //   }
  // }

  Future<bool> setDefaultCurrency({required num id}) async {
    final uri = Uri.parse('${APIConfig.url}/currencies/$id');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
