// lib/services/backend_client.dart

import 'package:http/http.dart' as http;

// Add this line
typedef TokenProvider = Future<String?> Function();

class BackendClient extends http.BaseClient {
  final String baseUrl;

  // Add this line
  final TokenProvider? tokenProvider;
  final _client = http.Client();

  BackendClient({
    required this.baseUrl,
    // Add this parameter
    this.tokenProvider,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Get the token if a provider is available
    final token = await tokenProvider?.call();

    // Add the Authorization header if the token exists
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Ensure other necessary headers are present
    request.headers['Content-Type'] = 'application/json';

    // Construct the full URL
    final url = Uri.parse('$baseUrl${request.url}');
    final updatedRequest = http.Request(request.method, url)
      ..headers.addAll(request.headers)
      ..bodyBytes = (request is http.Request)
          ? request.bodyBytes
          : await request.finalize().toBytes();

    return _client.send(updatedRequest);
  }
}