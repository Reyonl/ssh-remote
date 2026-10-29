import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_profile.dart';
import '../services/ssh_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error, rebooting }

class ServerProvider extends ChangeNotifier {
  final SshService _sshService = SshService();
  final List<ServerProfile> _servers = [];
  ServerProfile? _activeServer;
  ServerStats? _stats;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;
  Timer? _pollingTimer;

  List<ServerProfile> get servers => List.unmodifiable(_servers);
  ServerProfile? get activeServer => _activeServer;
  ServerStats? get stats => _stats;
  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  SshService get sshService => _sshService;

  ServerProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeStr = prefs.getString('theme_mode') ?? 'system';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load server profiles
    final rawServers = prefs.getStringList('server_profiles') ?? [];
    _servers.clear();
    for (var s in rawServers) {
      try {
        _servers.add(ServerProfile.fromJson(jsonDecode(s)));
      } catch (_) {}
    }

    // Default demo server if empty so UI is immediately testable
    if (_servers.isEmpty) {
      _servers.add(const ServerProfile(
        id: 'default-vps',
        name: 'Demo Ubuntu VPS',
        host: '103.187.147.20',
        port: 22,
        username: 'root',
      ));
    }

    // Set first server as active by default
    if (_servers.isNotEmpty) {
      _activeServer = _servers.first;
    }
    notifyListeners();
  }

  Future<void> _saveServersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _servers.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('server_profiles', rawList);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> saveServer(ServerProfile profile) async {
    final index = _servers.indexWhere((s) => s.id == profile.id);
    if (index >= 0) {
      _servers[index] = profile;
    } else {
      _servers.add(profile);
    }
    if (_activeServer?.id == profile.id) {
      _activeServer = profile;
    }
    await _saveServersToPrefs();
    notifyListeners();
  }

  Future<void> deleteServer(String id) async {
    _servers.removeWhere((s) => s.id == id);
    if (_activeServer?.id == id) {
      disconnect();
      _activeServer = _servers.isNotEmpty ? _servers.first : null;
    }
    await _saveServersToPrefs();
    notifyListeners();
  }

  void selectServer(ServerProfile profile) {
    if (_activeServer?.id != profile.id) {
      disconnect();
      _activeServer = profile;
      notifyListeners();
    }
  }

  Future<void> connect() async {
    if (_activeServer == null) return;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _sshService.connect(_activeServer!);
      _status = ConnectionStatus.connected;
      notifyListeners();

      // Immediately fetch initial stats
      await refreshStats();

      // Start automatic polling every 6 seconds
      _startPolling();
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_status == ConnectionStatus.connected && _sshService.isConnected) {
        await refreshStats(silent: true);
      }
    });
  }

  Future<void> refreshStats({bool silent = false}) async {
    if (!_sshService.isConnected) return;
    try {
      final newStats = await _sshService.fetchStats();
      _stats = newStats;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Gagal memuat stats: $e';
        notifyListeners();
      }
    }
  }

  Future<bool> restartServer() async {
    if (!_sshService.isConnected) return false;
    _status = ConnectionStatus.rebooting;
    notifyListeners();

    try {
      await _sshService.restartServer();
      _pollingTimer?.cancel();
      _stats = null;
      // Allow time for machine to reset
      await Future.delayed(const Duration(seconds: 15));
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = 'Gagal restart: $e';
      notifyListeners();
      return false;
    }
  }

  Future<String> restartService(String serviceName) async {
    if (!_sshService.isConnected) return 'Server belum terhubung';
    try {
      return await _sshService.restartService(serviceName);
    } catch (e) {
      return 'Error: $e';
    }
  }

  void disconnect() {
    _pollingTimer?.cancel();
    _sshService.disconnect();
    _status = ConnectionStatus.disconnected;
    _stats = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sshService.disconnect();
    super.dispose();
  }
}
