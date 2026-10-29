class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String? privateKey;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    this.username = 'root',
    this.password = '',
    this.privateKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'privateKey': privateKey,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'VPS Server',
        host: json['host'] as String? ?? '',
        port: (json['port'] as num?)?.toInt() ?? 22,
        username: json['username'] as String? ?? 'root',
        password: json['password'] as String? ?? '',
        privateKey: json['privateKey'] as String?,
      );

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKey,
  }) =>
      ServerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        privateKey: privateKey ?? this.privateKey,
      );
}

class ServerStats {
  final double cpuPercent;
  final String cpuLoad;
  final int ramTotalMb;
  final int ramUsedMb;
  final double diskTotalGb;
  final double diskUsedGb;
  final String uptime;
  final String osInfo;
  final DateTime lastUpdated;

  const ServerStats({
    required this.cpuPercent,
    required this.cpuLoad,
    required this.ramTotalMb,
    required this.ramUsedMb,
    required this.diskTotalGb,
    required this.diskUsedGb,
    required this.uptime,
    required this.osInfo,
    required this.lastUpdated,
  });

  double get ramPercent =>
      ramTotalMb > 0 ? ((ramUsedMb / ramTotalMb) * 100).clamp(0.0, 100.0) : 0.0;

  double get diskPercent =>
      diskTotalGb > 0 ? ((diskUsedGb / diskTotalGb) * 100).clamp(0.0, 100.0) : 0.0;
}
