import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_client.dart';

typedef EncryptionHandler =
    Map<String, dynamic> Function(Map<String, dynamic> data);
typedef DecryptionHandler =
    Map<String, dynamic> Function(Map<String, dynamic> data);

/// Default implementation of the NetworkClient interface using the http package
class DefaultNetworkClient implements NetworkClient {
  /// Base URL for all requests
  final String baseUrl;

  /// HTTP client for making requests
  final http.Client _client;

  /// Default headers to apply to all requests
  final Map<String, String> _defaultHeaders;

  /// Optional encryption handler to encrypt outgoing requests
  EncryptionHandler? _encryptionHandler;

  /// Optional decryption handler to decrypt incoming responses
  DecryptionHandler? _decryptionHandler;

  /// Creates a new NetworkClient instance
  ///
  /// Parameters:
  /// - [baseUrl]: The base URL for all requests
  /// - [client]: Optional custom HTTP client
  /// - [defaultHeaders]: Optional default headers to include in all requests
  DefaultNetworkClient({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
  }) : _client = client ?? http.Client(),
       _defaultHeaders =
           defaultHeaders ??
           {'Content-Type': 'application/json', 'Accept': 'application/json'};

  /// Sets the encryption handler for outgoing requests
  ///
  /// [handler] The function to encrypt data before sending
  void setEncryptionHandler(EncryptionHandler handler) {
    _encryptionHandler = handler;
  }

  /// Sets the decryption handler for incoming responses
  ///
  /// [handler] The function to decrypt data after receiving
  void setDecryptionHandler(DecryptionHandler handler) {
    _decryptionHandler = handler;
  }

  /// Builds a URL from an endpoint and query parameters
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [queryParams]: Optional query parameters to include in the URL
  ///
  /// Returns the full URL as a string
  String _buildUrl(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse('$cleanBaseUrl$cleanEndpoint');

    if (queryParams == null || queryParams.isEmpty) {
      return uri.toString();
    }

    final queryString = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');

    return '$uri${uri.toString().contains('?') ? '&' : '?'}$queryString';
  }

  /// Sends a GET request to the specified endpoint
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [queryParameters]: Optional query parameters to include in the URL
  /// - [headers]: Optional headers to include in the request
  ///
  /// Returns a [NetworkResponse] with the result of the request
  @override
  Future<NetworkResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint, queryParameters);
    final response = await _client.get(
      Uri.parse(url),
      headers: {..._defaultHeaders, ...?headers},
    );

    final data = _parseResponseBody(response);
    return NetworkResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  /// Sends a POST request to the specified endpoint
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [body]: Optional request body as a map
  /// - [headers]: Optional headers to include in the request
  ///
  /// Returns a [NetworkResponse] with the result of the request
  @override
  Future<NetworkResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final bodyJson = body != null ? jsonEncode(_encryptIfEnabled(body)) : null;

    final response = await _client.post(
      Uri.parse(url),
      headers: {..._defaultHeaders, ...?headers},
      body: bodyJson,
    );

    final data = _parseResponseBody(response);
    return NetworkResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  /// Sends a PUT request to the specified endpoint
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [body]: Optional request body as a map
  /// - [headers]: Optional headers to include in the request
  ///
  /// Returns a [NetworkResponse] with the result of the request
  @override
  Future<NetworkResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final bodyJson = body != null ? jsonEncode(_encryptIfEnabled(body)) : null;

    final response = await _client.put(
      Uri.parse(url),
      headers: {..._defaultHeaders, ...?headers},
      body: bodyJson,
    );

    final data = _parseResponseBody(response);
    return NetworkResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  /// Sends a PATCH request to the specified endpoint
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [body]: Optional request body as a map
  /// - [headers]: Optional headers to include in the request
  ///
  /// Returns a [NetworkResponse] with the result of the request
  Future<NetworkResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final bodyJson = body != null ? jsonEncode(_encryptIfEnabled(body)) : null;

    final response = await _client.patch(
      Uri.parse(url),
      headers: {..._defaultHeaders, ...?headers},
      body: bodyJson,
    );

    final data = _parseResponseBody(response);
    return NetworkResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  /// Sends a DELETE request to the specified endpoint
  ///
  /// Parameters:
  /// - [endpoint]: The API endpoint
  /// - [headers]: Optional headers to include in the request
  ///
  /// Returns a [NetworkResponse] with the result of the request
  @override
  Future<NetworkResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final response = await _client.delete(
      Uri.parse(url),
      headers: {..._defaultHeaders, ...?headers},
    );

    final data = _parseResponseBody(response);
    return NetworkResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  /// Parses the response body as JSON if possible
  ///
  /// Parameters:
  /// - [response]: The HTTP response
  ///
  /// Returns the parsed data or null if parsing failed
  dynamic _parseResponseBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      final jsonData = jsonDecode(response.body);

      // Apply decryption if needed
      if (jsonData is Map<String, dynamic>) {
        return _decryptIfNeeded(jsonData);
      }
      return jsonData;
    } catch (e) {
      return response.body;
    }
  }

  /// Encrypts data if an encryption handler is set
  ///
  /// [data] The data to encrypt
  /// Returns the encrypted data or original data if no handler is set
  Map<String, dynamic> _encryptIfEnabled(Map<String, dynamic> data) {
    if (_encryptionHandler != null) {
      return _encryptionHandler!(data);
    }
    return data;
  }

  /// Decrypts data if a decryption handler is set
  ///
  /// [data] The data to decrypt
  /// Returns the decrypted data or original data if no handler is set
  Map<String, dynamic> _decryptIfNeeded(Map<String, dynamic> data) {
    if (_decryptionHandler != null) {
      return _decryptionHandler!(data);
    }
    return data;
  }
}
