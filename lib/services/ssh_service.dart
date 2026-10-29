import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/server_profile.dart';

class _FastSSHSocket implements SSHSocket {
  final Socket _socket;
  _FastSSHSocket(this._socket);

  @override
  Stream<Uint8List> get stream => _socket;

  @override
  StreamSink<List<int>> get sink => _socket;

  @override
  Future<void> close() => _socket.close();

  @override
  Future<void> get done => _socket.done;

  @override
  void destroy() => _socket.destroy();

  @override
  Future<void> flush() => _socket.flush();
}

class SshService {
  SSHClient? _client;
  ServerProfile? _currentProfile;

  bool get isConnected => _client != null && !_client!.isClosed;
  ServerProfile? get currentProfile => _currentProfile;

  Future<void> connect(ServerProfile profile) async {
    disconnect();
    _currentProfile = profile;

    // Use low-latency socket with Nagle's algorithm disabled (tcpNoDelay)
    final rawSocket = await Socket.connect(
      profile.host,
      profile.port,
      timeout: const Duration(seconds: 10),
    );
    rawSocket.setOption(SocketOption.tcpNoDelay, true);
    final socket = _FastSSHSocket(rawSocket);

    // Support both password & private key authentication
    List<SSHKeyPair>? identities;
    if (profile.privateKey != null && profile.privateKey!.trim().isNotEmpty) {
      try {
        identities = SSHKeyPair.fromPem(profile.privateKey!);
      } catch (_) {
        // Fallback to password if key parsing fails
      }
    }

    _client = SSHClient(
      socket,
      username: profile.username.isEmpty ? 'root' : profile.username,
      identities: identities,
      onPasswordRequest: () => profile.password,
    );

    await _client!.authenticated;
  }

  void disconnect() {
    try {
      _client?.close();
    } catch (_) {}
    _client = null;
  }

  Future<String> executeCommand(String command) async {
    if (_client == null || _client!.isClosed) {
      throw Exception('SSH Client tidak terhubung.');
    }
    final session = await _client!.execute(command);
    final stdoutFuture = utf8.decodeStream(session.stdout);
    final stderrFuture = utf8.decodeStream(session.stderr);
    final results = await Future.wait([stdoutFuture, stderrFuture]);
    final out = results[0];
    final err = results[1];
    return out.isNotEmpty ? out : err;
  }

  Future<SSHSession> createInteractiveShell({
    required int width,
    required int height,
  }) async {
    if (_client == null || _client!.isClosed) {
      throw Exception('SSH Client tidak terhubung.');
    }
    return await _client!.shell(
      pty: SSHPtyConfig(
        width: width > 0 ? width : 80,
        height: height > 0 ? height : 25,
      ),
    );
  }

  Future<ServerStats> fetchStats() async {
    const script = '''
echo "---MEM---"
free -m 2>/dev/null || cat /proc/meminfo
echo "---DISK---"
df -m / 2>/dev/null
echo "---LOAD---"
cat /proc/loadavg 2>/dev/null
echo "---CORES---"
nproc 2>/dev/null || echo 1
echo "---UPTIME---"
uptime -p 2>/dev/null || uptime
echo "---OS---"
uname -srm 2>/dev/null
grep PRETTY_NAME /etc/os-release 2>/dev/null
''';

    final output = await executeCommand(script);
    return parseStats(output);
  }

  static ServerStats parseStats(String raw) {
    int ramTotal = 0;
    int ramUsed = 0;
    double diskTotal = 0;
    double diskUsed = 0;
    String loadAvg = '0.00, 0.00, 0.00';
    double cpuPct = 0;
    int cores = 1;
    String uptime = 'Unknown';
    String osInfo = 'Linux';

    final lines = raw.split('\n');
    String currentSection = '';

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('---') && trimmed.endsWith('---')) {
        currentSection = trimmed;
        continue;
      }
      if (trimmed.isEmpty) continue;

      if (currentSection == '---MEM---') {
        if (trimmed.startsWith('Mem:')) {
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            ramTotal = int.tryParse(parts[1]) ?? 0;
            ramUsed = int.tryParse(parts[2]) ?? 0;
          }
        }
      } else if (currentSection == '---DISK---') {
        if (trimmed.contains('/') && !trimmed.contains('Filesystem')) {
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final totalMb = double.tryParse(parts[1]) ?? 0;
            final usedMb = double.tryParse(parts[2]) ?? 0;
            diskTotal = double.parse((totalMb / 1024).toStringAsFixed(1));
            diskUsed = double.parse((usedMb / 1024).toStringAsFixed(1));
          }
        }
      } else if (currentSection == '---LOAD---') {
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          loadAvg = '${parts[0]}, ${parts[1]}, ${parts[2]}';
          final oneMinLoad = double.tryParse(parts[0]) ?? 0.0;
          cpuPct = oneMinLoad;
        }
      } else if (currentSection == '---CORES---') {
        cores = int.tryParse(trimmed) ?? 1;
        if (cores <= 0) cores = 1;
      } else if (currentSection == '---UPTIME---') {
        uptime = trimmed.replaceFirst('up ', '');
      } else if (currentSection == '---OS---') {
        if (trimmed.startsWith('PRETTY_NAME=')) {
          final name = trimmed.replaceFirst('PRETTY_NAME=', '').replaceAll('"', '');
          if (osInfo == 'Linux') {
            osInfo = name;
          } else {
            osInfo = '$name ($osInfo)';
          }
        } else if (osInfo == 'Linux') {
          osInfo = trimmed;
        }
      }
    }

    final calculatedCpu = ((cpuPct / cores) * 100).clamp(0.0, 100.0);

    return ServerStats(
      cpuPercent: double.parse(calculatedCpu.toStringAsFixed(1)),
      cpuLoad: loadAvg,
      ramTotalMb: ramTotal,
      ramUsedMb: ramUsed,
      diskTotalGb: diskTotal,
      diskUsedGb: diskUsed,
      uptime: uptime,
      osInfo: osInfo,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> restartServer() async {
    if (_client == null || _client!.isClosed) {
      throw Exception('SSH Client tidak terhubung.');
    }
    try {
      await _client!
          .execute('sudo reboot || reboot')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
    } finally {
      disconnect();
    }
  }

  Future<String> restartService(String serviceName) async {
    return await executeCommand('sudo systemctl restart $serviceName || systemctl restart $serviceName');
  }
}
