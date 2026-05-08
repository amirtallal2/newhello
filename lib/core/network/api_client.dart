import 'dart:convert';
import 'dart:io';
import 'dart:async';

import '../config/api_config.dart';
import 'api_exception.dart';

final class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final HttpClient _httpClient = HttpClient();
  String? _preferredBaseUrl;

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
    final candidates = <String>[
      ...?_preferredBaseUrl == null ? null : <String>[_preferredBaseUrl!],
      ...ApiConfig.candidateBaseUrls(),
    ];

    for (final baseUrl in candidates.toSet()) {
      try {
        final result = await _sendToBaseUrl(
          baseUrl,
          method,
          path,
          body: body,
          bearerToken: bearerToken,
        );
        _preferredBaseUrl = baseUrl;
        return result;
      } on SocketException {
        continue;
      } on HttpException {
        continue;
      } on HandshakeException {
        continue;
      } on TimeoutException {
        continue;
      }
    }

    throw ApiException(
      'Could not reach backend server. Checked: ${ApiConfig.candidateBaseUrls().join(', ')}',
    );
  }

  Future<Map<String, dynamic>> _sendToBaseUrl(
    String baseUrl,
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final HttpClientRequest request;

    switch (method) {
      case 'GET':
        request = await _httpClient
            .getUrl(uri)
            .timeout(const Duration(seconds: 4));
      case 'POST':
        request = await _httpClient
            .postUrl(uri)
            .timeout(const Duration(seconds: 4));
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (bearerToken != null && bearerToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
    }

    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }

    final response = await request.close().timeout(const Duration(seconds: 8));
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
