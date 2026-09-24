import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  String baseUrl;
  String? token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceFirst(RegExp(r'^/+'), '');
    final uri = Uri.parse('$base/$cleanPath');
    if (query == null) return uri;
    return uri.replace(
      queryParameters: query.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      _decode(await http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async =>
      _decode(
        await http.post(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body ?? {}),
        ),
      );

  Future<dynamic> put(String path, Map<String, dynamic> body) async => _decode(
    await http.put(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<dynamic> delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: _headers));

  List<Map<String, dynamic>> listFrom(dynamic response) {
    dynamic value = response is Map ? response['data'] : response;
    if (value is Map && value['data'] is List) value = value['data'];
    if (value is! List) return [];
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Map<String, dynamic> objectFrom(dynamic response) {
    final value = response is Map && response['data'] is Map
        ? response['data']
        : response;
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data ?? {};
    }
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final errors = map['errors'] is Map
        ? Map<String, dynamic>.from(map['errors'] as Map)
        : <String, dynamic>{};
    final firstError = errors.values.isEmpty
        ? null
        : errors.values.first is List
        ? (errors.values.first as List).first.toString()
        : errors.values.first.toString();
    throw ApiException(
      firstError ?? map['message']?.toString() ?? 'Request failed.',
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
