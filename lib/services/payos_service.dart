import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class PayosService {
  static const String clientId = 'cb5dba0e-2dd0-4f7a-a3cd-7bdbbac6c6ca';
  static const String apiKey = 'd9391fb8-1cd4-4003-95d8-c0ab6384b643';
  static const String checksumKey = '718656f13ec8df2810137a76047cf3cc649ba91aa6e433c95eaa78a48c45fd72';

  // Constants
  static const double usdToVndRate = 25000.0;
  static const String apiBaseUrl = 'https://api-merchant.payos.vn/v2';

  // Create signature for payOS payload
  String _calculateSignature(Map<String, dynamic> data) {
    // Sort keys alphabetically: amount, cancelUrl, description, orderCode, returnUrl
    final sortedKeys = ['amount', 'cancelUrl', 'description', 'orderCode', 'returnUrl'];
    final dataString = sortedKeys.map((key) => '$key=${data[key]}').join('&');

    final keyBytes = utf8.encode(checksumKey);
    final dataBytes = utf8.encode(dataString);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);

    return digest.toString();
  }

  // Create payment link on payOS
  Future<Map<String, dynamic>?> createPaymentLink({
    required int orderCode,
    required double totalUsd,
    required String itemName,
  }) async {
    final amountVnd = (totalUsd * usdToVndRate).round();
    
    // payOS description has a max length of 25 characters
    final String description = 'Thanh toan Luxura $orderCode'.substring(0, 25);
    
    final Map<String, dynamic> requestData = {
      'orderCode': orderCode,
      'amount': amountVnd,
      'description': description,
      'cancelUrl': 'https://cancel.luxurastore.com',
      'returnUrl': 'https://success.luxurastore.com',
    };

    final signature = _calculateSignature(requestData);

    final Map<String, dynamic> requestBody = {
      ...requestData,
      'signature': signature,
      'items': [
        {
          'name': itemName,
          'quantity': 1,
          'price': amountVnd,
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/payment-requests'),
        headers: {
          'x-client-id': clientId,
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final Map<String, dynamic> responseJson = json.decode(response.body);
      if (responseJson['code'] == '00') {
        return responseJson['data'] as Map<String, dynamic>;
      } else {
        debugPrint('payOS error: ${responseJson['desc']}');
        return null;
      }
    } catch (e) {
      debugPrint('payOS exceptions: $e');
      return null;
    }
  }

  // Retrieve payment status from payOS
  Future<String?> getPaymentStatus(int orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/payment-requests/$orderCode'),
        headers: {
          'x-client-id': clientId,
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseJson = json.decode(response.body);
      if (responseJson['code'] == '00') {
        return responseJson['data']['status'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('payOS fetch status exceptions: $e');
      return null;
    }
  }
}
