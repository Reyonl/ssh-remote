import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';
import 'server_list_screen.dart';
import 'terminal_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServerProvider>();
    final activeServer = provider.activeServer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terminal_rounded, size: 22, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              activeServer?.name ?? 'SSH Remote',
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ganti Tema',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : AppTheme.darkBlue,
            ),
            onPressed: () {
              provider.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          IconButton(
            tooltip: 'Daftar Server',
            icon: const Icon(Icons.dns_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerListScreen()),
              );
            },
          ),
        ],
      ),
      body: activeServer == null
          ? _buildNoServerView(context)
          : RefreshIndicator(
              onRefresh: () async => await provider.refreshStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConnectionCard(context, provider, activeServer),
                    const SizedBox(height: 16),
                    if (provider.status == ConnectionStatus.connected &&
                        provider.stats != null) ...[
                      _buildServerInfoCard(context, provider.stats!),
                      const SizedBox(height: 16),
                      _buildResourceMetrics(context, provider.stats!),
                      const SizedBox(height: 20),
                      _buildQuickActions(context, provider, activeServer),
                      const SizedBox(height: 16),
                      _buildTerminalLauncher(context),
                    ] else if (provider.status == ConnectionStatus.rebooting) ...[
                      _buildRebootingCard(context),
                    ] else if (provider.status == ConnectionStatus.connecting) ...[
                      _buildConnectingCard(context),
                    ] else if (provider.status == ConnectionStatus.error) ...[
                      _buildErrorCard(context, provider),
                    ] else ...[
                      _buildIdleCard(context, provider, activeServer),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoServerView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada profil VPS tersimpan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerListScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah VPS Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    ServerProvider provider,
    ServerProfile server,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (provider.status) {
      case ConnectionStatus.connected:
        statusColor = const Color(0xFF10B981);
        statusText = 'Terhubung';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.amber;
        statusText = 'Menghubungkan...';
        statusIcon = Icons.sync_rounded;
        break;
      case ConnectionStatus.rebooting:
        statusColor = Colors.orange;
        statusText = 'Rebooting VPS...';
        statusIcon = Icons.restart_alt_rounded;
        break;
      case ConnectionStatus.error:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Koneksi Gagal';
        statusIcon = Icons.error_outline_rounded;
        break;
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusText = 'Terputus';
        statusIcon = Icons.power_settings_new_rounded;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${server.username}@${server.host}:${server.port}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (provider.status == ConnectionStatus.connected)
              IconButton(
                tooltip: 'Putuskan Koneksi',
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
                onPressed: () => provider.disconnect(),
              )
            else if (provider.status != ConnectionStatus.connecting &&
                provider.status != ConnectionStatus.rebooting)
              FilledButton.tonal(
                onPressed: () => provider.connect(),
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard(BuildContext context, stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Sistem & Uptime',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Update: ${stats.lastUpdated.hour.toString().padLeft(2, '0')}:${stats.lastUpdated.minute.toString().padLeft(2, '0')}:${stats.lastUpdated.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              stats.osInfo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Uptime: ${stats.uptime}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceMetrics(BuildContext context, stats) {
    return Column(
      children: [
        _buildMetricItem(
          context,
          title: 'CPU Usage',
          value: '${stats.cpuPercent}%',
          subtitle: 'Load Avg: ${stats.cpuLoad}',
          percent: stats.cpuPercent / 100,
          icon: Icons.memory_rounded,
          color: _getColorForPercent(stats.cpuPercent),
        ),
        const SizedBox(height: 12),
        _buildMetricItem(
          context,
          title: 'RAM Usage',
          value: '${stats.ramUsedMb} MB / ${stats.ramTotalMb} MB (${stats.ramPercent.toStringAsFixed(1)}%)',
          subtitle: stats.ramTotalMb > 0
              ? 'Tersisa: ${stats.ramTotalMb - stats.ramUsedMb} MB'
              : '',
          percent: stats.ramPercent / 100,
          icon: Icons.speed_rounded,
          color: _getColorForPercent(stats.ramPercent),
        ),
        const SizedBox(height: 12),
        _buildMetricItem(
          context,
          title: 'Disk Storage (Root /)',
          value: '${stats.diskUsedGb} GB / ${stats.diskTotalGb} GB (${stats.diskPercent.toStringAsFixed(1)}%)',
          subtitle: stats.diskTotalGb > 0
              ? 'Tersisa: ${(stats.diskTotalGb - stats.diskUsedGb).toStringAsFixed(1)} GB'
              : '',
          percent: stats.diskPercent / 100,
          icon: Icons.storage_rounded,
          color: _getColorForPercent(stats.diskPercent),
        ),
      ],
    );
  }

  Color _getColorForPercent(double percent) {
    if (percent >= 85) return const Color(0xFFEF4444); // Red
    if (percent >= 70) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald Green
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required double percent,
    required IconData icon,
    required Color color,
  }) {
    final clampedPercent = percent.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${(clampedPercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedPercent,
                minHeight: 8,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ServerProvider provider,
    ServerProfile server,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, size: 20, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Quick Actions (Power & Services)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                // Restart VPS Button (Highlighted Red)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Restart VPS'),
                    onPressed: () => _confirmRestartVps(context, provider, server),
                  ),
                ),
                const SizedBox(width: 10),
                // Refresh Stats Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    onPressed: () => provider.refreshStats(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.public_rounded, size: 16),
                    label: const Text('Restart Nginx', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final res = await provider.restartService('nginx');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Nginx restart result: $res')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.developer_board_rounded, size: 16),
                    label: const Text('Restart Docker', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final res = await provider.restartService('docker');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Docker restart result: $res')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestartVps(
    BuildContext context,
    ServerProvider provider,
    ServerProfile server,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Restart VPS?'),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin me-reboot VPS "${server.name}" (${server.host})?\n\n'
          'Perintah "sudo reboot" akan dijalankan. Semua koneksi dan proses server akan terhenti sejenak hingga server selesai menyala kembali.',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Restart Sekarang'),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinyal reboot telah dikirim ke VPS...'),
                  backgroundColor: Colors.orange,
                ),
              );
              await provider.restartServer();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalLauncher(BuildContext context) {
    return Card(
      color: AppTheme.darkBlue,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TerminalScreen()),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.terminal_rounded, color: Colors.white, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka Interactive Terminal (CMD)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Akses full shell dengan tombol Ctrl, Esc, Tab',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingCard(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke VPS via SSH...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebootingCard(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'VPS sedang proses reboot...',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Tunggu sekitar 20-30 detik lalu hubungkan kembali.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ServerProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              'Gagal Terhubung',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              provider.errorMessage ?? 'Periksa IP, Port, Username, atau Password VPS.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.connect(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleCard(
    BuildContext context,
    ServerProvider provider,
    ServerProfile server,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.dns_rounded, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 14),
            Text(
              server.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${server.username}@${server.host}:${server.port}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => provider.connect(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Hubungkan Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
