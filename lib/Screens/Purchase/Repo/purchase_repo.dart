//ignore_for_file: prefer_typing_uninitialized_variables,unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../../Customers/Provider/customer_provider.dart';
import '../Model/purchase_transaction_model.dart';

class PurchaseRepo {
  Future<List<PurchaseTransaction>> fetchPurchaseList({bool? purchaseReturn}) async {
    final uri = Uri.parse('${APIConfig.url}/purchase${(purchaseReturn ?? false) ? "?returned-purchase=true" : ''}');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => PurchaseTransaction.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Purchase List');
    }
  }

  Future<PurchaseTransaction?> createPurchase({
    required WidgetRef ref,
    required BuildContext context,
    required num partyId,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num? vatId,
    required num totalAmount,
    required num vatAmount,
    required num vatPercent,
    required num dueAmount,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartProductModelPurchase> products,
    required String discountType,
    required num shippingCharge,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/purchase');

    final body = {
      'party_id': partyId,
      'vat_id': vatId,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'discount_percent': discountPercent,
      'totalAmount': totalAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'dueAmount': dueAmount,
      'paidAmount': totalAmount - dueAmount,
      'change_amount': changeAmount,
      'isPaid': isPaid,
      'payment_type_id': paymentType,
      'discount_type': discountType,
      'shipping_charge': shippingCharge,
      'products': products.map((e) => e.toJson()).toList(),
    };

    print('Purchase Posted data : ${jsonEncode(body)}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': await getAuthToken(),
        },
        body: jsonEncode(body),
      );

      final parsed = jsonDecode(response.body);

      print('Purchase Response : ${response.statusCode}');
      print('Purchase Response : $parsed');

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!');

        // Refresh providers
        ref
          ..refresh(productProvider)
          ..refresh(partiesProvider)
          ..refresh(purchaseTransactionProvider)
          ..refresh(businessInfoProvider)
          ..refresh(getExpireDateProvider(ref))
          ..refresh(summaryInfoProvider);

        print('Purchase Response: ${parsed['data']}');
        return PurchaseTransaction.fromJson(parsed['data']);
      } else {
        EasyLoading.dismiss();
        _showError(context, 'Purchase creation failed: ${parsed['message']}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      _showError(context, 'An error occurred: $e');
    }

    return null;
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<PurchaseTransaction?> updatePurchase({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required num partyId,
    required num? vatId,
    required num vatAmount,
    required num vatPercent,
    required String purchaseDate,
    required num discountAmount,
    required num totalAmount,
    required num dueAmount,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartProductModelPurchase> products,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/purchase/$id');
    final requestBody = jsonEncode({
      '_method': 'put',
      'party_id': partyId,
      'vat_id': vatId,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'dueAmount': dueAmount,
      'paidAmount': totalAmount - dueAmount,
      'change_amount': changeAmount,
      'isPaid': isPaid,
      'payment_type_id': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
    });

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
      var responseData = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);
      print(responseData.statusCode);
      print(parsedData);

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!');
        var data1 = ref.refresh(productProvider);
        var data2 = ref.refresh(partiesProvider);
        var data3 = ref.refresh(purchaseTransactionProvider);
        var data4 = ref.refresh(businessInfoProvider);
        ref.refresh(getExpireDateProvider(ref));
        Navigator.pop(context);
        return PurchaseTransaction.fromJson(parsedData);
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase creation failed: ${parsedData['message']}')));
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss();
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      return null;
    }
  }

  Future<void> deletePurchase({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/purchase/$id';

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));

        var data1 = ref.refresh(productProvider);

        Navigator.pop(context); // Assuming you want to close the screen after deletion
        Navigator.pop(context); // Assuming you want to close the screen after deletion
        // Navigator.pop(context); // Assuming you want to close the screen after deletion
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete product: ${parsedData['message']}')));
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class CartProductModelPurchase {
  num productId;
  num? stockId;
  String productName;
  String productType;
  String vatType;
  num vatRate;
  num vatAmount;
  String? brandName;
  String? batchNumber;
  num? productDealerPrice;
  num? productPurchasePrice;
  String? expireDate;
  String? mfgDate;
  num? productSalePrice;
  num? profitPercent;
  num? productWholeSalePrice;
  num? quantities;
  num? stock;

  CartProductModelPurchase({
    required this.productId,
    this.stockId,
    required this.productName,
    required this.productType,
    required this.vatRate,
    required this.vatAmount,
    required this.vatType,
    this.brandName,
    this.stock,
    this.profitPercent,
    required this.productDealerPrice,
    required this.productPurchasePrice,
    required this.productSalePrice,
    required this.productWholeSalePrice,
    required this.quantities,
    this.batchNumber,
    this.mfgDate,
    this.expireDate,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'productDealerPrice': productDealerPrice,
        'productPurchasePrice': productPurchasePrice,
        'productSalePrice': productSalePrice,
        'productWholeSalePrice': productWholeSalePrice,
        'quantities': quantities,
        'batch_no': batchNumber,
        'profit_percent': profitPercent,
        'expire_date': expireDate,
        'mfg_date': mfgDate,
      };
}
