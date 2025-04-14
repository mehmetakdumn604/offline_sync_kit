import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_client.dart';

class DefaultNetworkClient implements NetworkClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  DefaultNetworkClient({
    required this.baseUrl,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
    this.timeout = const Duration(seconds: 30),
  });

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final apiUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final uri = Uri.parse('$apiUrl$cleanEndpoint');

    if (queryParameters != null) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    return uri;
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...defaultHeaders, ...?headers};
  }

  @override
  Future<NetworkResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await http
          .get(uri, headers: _mergeHeaders(headers))
          .timeout(timeout);

      return NetworkResponse(
        statusCode: response.statusCode,
        data: _parseResponseBody(response.body),
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResponse(statusCode: 0, error: e.toString());
    }
  }

  @override
  Future<NetworkResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http
          .post(uri, headers: _mergeHeaders(headers), body: encodedBody)
          .timeout(timeout);

      return NetworkResponse(
        statusCode: response.statusCode,
        data: _parseResponseBody(response.body),
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResponse(statusCode: 0, error: e.toString());
    }
  }

  @override
  Future<NetworkResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http
          .put(uri, headers: _mergeHeaders(headers), body: encodedBody)
          .timeout(timeout);

      return NetworkResponse(
        statusCode: response.statusCode,
        data: _parseResponseBody(response.body),
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResponse(statusCode: 0, error: e.toString());
    }
  }

  @override
  Future<NetworkResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .delete(uri, headers: _mergeHeaders(headers))
          .timeout(timeout);

      return NetworkResponse(
        statusCode: response.statusCode,
        data: _parseResponseBody(response.body),
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResponse(statusCode: 0, error: e.toString());
    }
  }

  dynamic _parseResponseBody(String body) {
    if (body.isEmpty) return null;

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
