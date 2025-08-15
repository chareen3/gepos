import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../add_new_warehouse.dart';
import '../warehouse_model/warehouse_list_model.dart';

class WarehouseRepo {
  // Create Warehouse
  Future<bool> createWareHouse({required CreateWareHouseModel data}) async {
    EasyLoading.show(status: 'Creating Warehouse...');
    final url = Uri.parse('${APIConfig.url}/warehouses');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    request.fields['name'] = data.name.toString();
    request.fields['phone'] = data.phone.toString();
    request.fields['email'] = data.email.toString();
    request.fields['address'] = data.address.toString();
    try {
      var response = await request.send();

      var responseData = await http.Response.fromStream(response);
      EasyLoading.dismiss();
      print('warehouse create ${response.statusCode}');
      print('warehouse create ${response.request}');
      if (response.statusCode == 200) {
        return true;
      } else {
        var data = jsonDecode(responseData.body);
        EasyLoading.showError(data['message'] ?? 'Failed to create warehouse');
        print('Error: ${data['message']}');
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      print('Error: ${e.toString()}');
      return false;
    }
  }

  // warehouse List
  Future<WarehouseListModel> fetchWareHouseList() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    final url = Uri.parse('${APIConfig.url}/warehouses');
    final headers = {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    };
    try {
      var response = await http.get(url, headers: headers);
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return WarehouseListModel.fromJson(jsonData);
      } else {
        var data = jsonDecode(response.body);
        EasyLoading.showError(data['message'] ?? 'Failed to fetch warehouse');
        throw Exception(data['message'] ?? 'Failed to fetch warehouse');
      }
    } catch (e) {
      // Hide loading indicator and show error
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Update Warehouse
  Future<bool> updateWareHouse({required CreateWareHouseModel data}) async {
    EasyLoading.show(status: 'Updating Warehouse...');
    final url = Uri.parse('${APIConfig.url}/warehouses/${data.warehouseId}');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });
    request.fields['name'] = data.name.toString();
    request.fields['phone'] = data.phone.toString();
    request.fields['email'] = data.email.toString();
    request.fields['address'] = data.address.toString();
    request.fields['_method'] = 'put';
    try {
      var response = await request.send();

      var responseData = await http.Response.fromStream(response);
      EasyLoading.dismiss();
      print(response.statusCode);
      if (response.statusCode == 200) {
        return true;
      } else {
        var data = jsonDecode(responseData.body);
        EasyLoading.showError(data['message'] ?? 'Failed to update');
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  // delete warehouse
  Future<bool> deleteWarehouse({required String id}) async {
    EasyLoading.show(status: 'Processing');
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    final url = Uri.parse('${APIConfig.url}/warehouses/$id');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      var response = await http.delete(
        url,
        headers: headers,
      );
      EasyLoading.dismiss();
      print(response.statusCode);
      if (response.statusCode == 200) {
        return true;
      } else {
        var data = jsonDecode(response.body);
        EasyLoading.showError(data['message'] ?? 'Failed to delete');
        print(data['message']);
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      print(e.toString());
      return false;
    }
  }
}
