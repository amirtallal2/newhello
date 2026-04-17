import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import 'api_exception.dart';

final class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final HttpClient _httpClient = HttpClient();

  Future<Map<String, dynamic>> get(String path, {String? bearerToken}) async {
    return _send('GET', path, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    return _send('POST', path, body: body, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    late final HttpClientRequest request;

    switch (method) {
      case 'GET':
        request = await _httpClient.getUrl(uri);
      case 'POST':
        request = await _httpClient.postUrl(uri);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }

    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (bearerToken != null && bearerToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Invalid response from server.',
        statusCode: response.statusCode,
      );
    }

    final success = decoded['success'] == true;
    final message = decoded['message']?.toString() ?? 'Unknown error.';

    if (!success || response.statusCode >= 400) {
      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }
}
