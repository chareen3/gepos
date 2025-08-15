import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';
import 'package:mobile_pos/model/todays_summary_model.dart';

import '../../http_client/subscription_expire_provider.dart';
import '../../model/business_info_model.dart';
import '../constant_functions.dart';

class BusinessRepository {
  Future<BusinessInformationModel> fetchBusinessData() async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken(); // Replace with your token retrieval logic

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Assuming Bearer token format
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      final BusinessInformationModel businessInformation = BusinessInformationModel.fromJson(parsedData['data']);

      return businessInformation;
    } else {
      throw Exception('Failed to fetch business data');
    }
  }

  Future<void> fetchSubscriptionExpireDate({required WidgetRef ref}) async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken(); // Replace with your token retrieval logic

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Assuming Bearer token format
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      final BusinessInformationModel businessInformation = BusinessInformationModel.fromJson(parsedData['data']);
      ref.read(subscriptionProvider.notifier).updateSubscription(businessInformation.willExpire);
      // ref.read(subscriptionProvider.notifier).updateSubscription("2025-01-05");
    } else {
      throw Exception('Failed to fetch business data');
    }
  }

  Future<BusinessSettingModel> businessSettingData() async {
    final uri = Uri.parse('${APIConfig.url}/business-settings');
    final token = await getAuthToken();
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    BusinessSettingModel businessSettingModel = BusinessSettingModel(message: null, pictureUrl: null);
    if (response.statusCode == 200) {
      final parseData = jsonDecode(response.body);
      businessSettingModel = BusinessSettingModel.fromJson(parseData);
    }
    return businessSettingModel;
  }

  Future<BusinessInformationModel?> checkBusinessData() async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken(); // Replace with your token retrieval logic

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Assuming Bearer token format
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      return BusinessInformationModel.fromJson(parsedData['data']); // Extract the "data" object from the response
    } else {
      return null;
    }
  }

  Future<TodaysSummaryModel> fetchTodaySummaryData() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final uri = Uri.parse('${APIConfig.url}/summary?date=$date');
    final token = await getAuthToken(); // Replace with your token retrieval logic

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Assuming Bearer token format
    });
    print('------------dashboard------${response.statusCode}--------------');
    if (response.statusCode == 200) {
      print(response.body);
      return TodaysSummaryModel.fromJson(jsonDecode(response.body)); // Extract the "data" object from the response
    } else {
      // await LogOutRepo().signOut();

      throw Exception('Failed to fetch business data');
    }
  }

  // Future<DashboardOverviewModel> dashboardData(String type) async {
  //   final uri = Uri.parse('${APIConfig.url}/dashboard?duration=$type');
  //   final token = await getAuthToken(); // Replace with your token retrieval logic
  //
  //   final response = await http.get(uri, headers: {
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer $token', // Assuming Bearer token format
  //   });
  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     return DashboardOverviewModel.fromJson(jsonDecode(response.body)); // Extract the "data" object from the response
  //   } else {
  //     // await LogOutRepo().signOut();
  //
  //     throw Exception('Failed to fetch business data ${response.statusCode}');
  //   }
  // }

  Future<DashboardOverviewModel> dashboardData(String type) async {
    final token = await getAuthToken();
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    Uri uri;

    if (type.startsWith('custom_date&')) {
      final uriParams = Uri.splitQueryString(type.replaceFirst('custom_date&', ''));
      final fromDate = uriParams['from_date'];
      final toDate = uriParams['to_date'];

      uri = Uri.parse('${APIConfig.url}/dashboard?duration=custom_date&from_date=$fromDate&to_date=$toDate');
    } else {
      uri = Uri.parse('${APIConfig.url}/dashboard?duration=$type');
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return DashboardOverviewModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch business data ${response.statusCode}');
    }
  }
}
