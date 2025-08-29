//ignore_for_file: file_names, unused_element, unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Income/Providers/all_income_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../Model/income_modle.dart';

class IncomeRepo {
  Future<List<Income>> fetchIncome() async {
    final uri = Uri.parse('${APIConfig.url}/incomes');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      
      // Laravel API returns: {"message": "...", "data": [...]}
      if (parsedData is Map<String, dynamic> && parsedData.containsKey('data')) {
        final responseData = parsedData['data'];
        
        List<dynamic> incomeList;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          // Paginated response
          incomeList = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // Direct array response
          incomeList = responseData;
        } else {
          throw Exception('Invalid income data structure: ${responseData.runtimeType}');
        }
        
        return incomeList.map((income) => Income.fromJson(income)).toList();
      } else {
        throw Exception('Invalid API response structure: ${parsedData.runtimeType}');
      }
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch incomes list');
    }
  }

  Future<void> createIncome({
    required WidgetRef ref,
    required BuildContext context,
    required num amount,
    required num expenseCategoryId,
    required String expanseFor,
    required String paymentType,
    required String referenceNo,
    required String expenseDate,
    required String note,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/incomes');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
    final requestBody = jsonEncode({
      'amount': amount,
      'income_category_id': expenseCategoryId,
      'incomeFor': expanseFor,
      'referenceNo': referenceNo,
      'incomeDate': expenseDate,
      'note': note,
      'payment_type_id': paymentType,
    });

    try {
      var responseData = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);

      EasyLoading.dismiss();

      if (responseData.statusCode == 200) {
        var data1 = ref.refresh(incomeProvider);
        var data2 = ref.refresh(businessInfoProvider);
        ref.refresh(summaryInfoProvider);
        Navigator.pop(context);
        // return PurchaseTransaction.fromJson(parsedData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Income creation failed: ${parsedData['message']}')));
        return;
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      // return null;
    }
  }
}
