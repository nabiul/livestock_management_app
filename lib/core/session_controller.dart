import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class SessionController extends ChangeNotifier {
  static String get defaultBaseUrl =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://livestockos.bizzsmart.xyz/public/api/v1'
      : 'http://localhost/Livestock_management/public/api/v1';

  late SharedPreferences _preferences;
  late ApiClient api;
  bool initializing = true;
  Map<String, dynamic>? user;
  Map<String, dynamic>? tenant;
  List<String> permissions = [];

  bool get isAuthenticated => api.token != null && user != null;
  String get baseUrl => api.baseUrl;
  String get userName => user?['name']?.toString() ?? 'User';
  String get tenantName => tenant?['name']?.toString() ?? 'Farm workspace';

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    api = ApiClient(
      baseUrl: _preferences.getString('api_base_url') ?? defaultBaseUrl,
      token: _preferences.getString('api_token'),
    );
    if (api.token != null) {
      try {
        await refreshIdentity();
      } catch (_) {
        await _preferences.remove('api_token');
        api.token = null;
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await api.post('auth/login', {
      'email': email,
      'password': password,
    });
    final map = Map<String, dynamic>.from(response as Map);
    api.token = map['token']?.toString();
    user = map['user'] is Map ? Map<String, dynamic>.from(map['user']) : null;
    tenant = map['tenant'] is Map
        ? Map<String, dynamic>.from(map['tenant'])
        : null;
    permissions = _stringList(map['permissions']);
    await _preferences.setString('api_token', api.token!);
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> payload) async {
    final response = await api.post('auth/register', payload);
    final map = Map<String, dynamic>.from(response as Map);
    api.token = map['token']?.toString();
    user = map['user'] is Map ? Map<String, dynamic>.from(map['user']) : null;
    tenant = map['tenant'] is Map
        ? Map<String, dynamic>.from(map['tenant'])
        : null;
    permissions = ['*'];
    await _preferences.setString('api_token', api.token!);
    notifyListeners();
  }

  Future<void> refreshIdentity() async {
    final response = await api.get('auth/me');
    final map = Map<String, dynamic>.from(response as Map);
    user = map['user'] is Map ? Map<String, dynamic>.from(map['user']) : null;
    tenant = map['tenant'] is Map
        ? Map<String, dynamic>.from(map['tenant'])
        : null;
    permissions = _stringList(map['permissions']);
  }

  bool can(String permission) =>
      permissions.contains('*') || permissions.contains(permission);

  Future<void> logout() async {
    try {
      await api.post('auth/logout');
    } catch (_) {}
    api.token = null;
    user = null;
    tenant = null;
    permissions = [];
    await _preferences.remove('api_token');
    notifyListeners();
  }

  Future<void> setBaseUrl(String value) async {
    api.baseUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    await _preferences.setString('api_base_url', api.baseUrl);
    notifyListeners();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }
}
