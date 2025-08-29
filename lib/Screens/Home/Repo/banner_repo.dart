import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../Model/banner_model.dart';

class BannerRepo {
  Future<List<Banner>> fetchAllIBanners() async {
    final uri = Uri.parse('${APIConfig.url}/banners');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      
      // Laravel API returns: {"message": "...", "data": [...]}
      if (parsedData is Map<String, dynamic> && parsedData.containsKey('data')) {
        final responseData = parsedData['data'];
        
        List<dynamic> bannerList;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          // Paginated response
          bannerList = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // Direct array response
          bannerList = responseData;
        } else {
          throw Exception('Invalid banner data structure: ${responseData.runtimeType}');
        }
        
        return bannerList.map((banner) => Banner.fromJson(banner)).toList();
      } else {
        throw Exception('Invalid API response structure: ${parsedData.runtimeType}');
      }
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Users');
    }
  }
}
