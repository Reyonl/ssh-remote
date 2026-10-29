import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal _terminal;
  SSHSession? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pause background CPU/RAM metric polling to dedicate 100% SSH bandwidth to interactive shell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServerProvider>().pausePolling();
      }
    });

    _terminal = Terminal(maxLines: 5000);
    _initShell();
  }

  Future<void> _initShell() async {
    final provider = context.read<ServerProvider>();
    if (!provider.sshService.isConnected) {
      setState(() {
        _isLoading = false;
        _error = 'Koneksi SSH belum aktif. Silakan hubungkan dari dashboard.';
      });
      return;
    }

    try {
      final session = await provider.sshService.createInteractiveShell(
        width: 80,
        height: 25,
      );
      _session = session;

      // Pipe server output to terminal UI immediately
      session.stdout.listen(
        (data) => _terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (err) => _terminal.write('\r\n[Stream Error: $err]\r\n'),
      );
      session.stderr.listen(
        (data) => _terminal.write(utf8.decode(data, allowMalformed: true)),
      );

      // Pipe terminal UI user input to server stdin with instant transmission
      _terminal.onOutput = (data) {
        session.stdin.add(utf8.encode(data));
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal membuka shell: $e';
      });
    }
  }

  void _sendKey(String key) {
    if (_session != null) {
      _session!.stdin.add(utf8.encode(key));
    }
  }

  @override
  void dispose() {
    // Resume background monitoring when leaving terminal
    try {
      context.read<ServerProvider>().resumePolling();
    } catch (_) {}
    _session?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = context.watch<ServerProvider>().activeServer?.name ?? 'Terminal';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(
          '$serverName (CMD)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Screen',
            icon: const Icon(Icons.cleaning_services_rounded, size: 20),
            onPressed: () {
              _sendKey('clear\n');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accentCyan),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : TerminalView(
                          _terminal,
                          backgroundOpacity: 1.0,
                          autofocus: true,
                        ),
            ),
            // Mobile Keyboard Accessory Bar (Ctrl, Esc, Tab, Arrows, etc.)
            _buildAccessoryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessoryBar() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKeyButton('ESC', () => _sendKey('\x1b')),
            _buildKeyButton('TAB', () => _sendKey('\t')),
            _buildKeyButton('CTRL+C', () => _sendKey('\x03'), isAccent: true),
            _buildKeyButton('CTRL+D', () => _sendKey('\x04')),
            _buildKeyButton('CTRL+Z', () => _sendKey('\x1a')),
            _buildKeyButton('↑', () => _sendKey('\x1b[A')),
            _buildKeyButton('↓', () => _sendKey('\x1b[B')),
            _buildKeyButton('←', () => _sendKey('\x1b[D')),
            _buildKeyButton('→', () => _sendKey('\x1b[C')),
            _buildKeyButton('|', () => _sendKey('|')),
            _buildKeyButton('/', () => _sendKey('/')),
            _buildKeyButton('~', () => _sendKey('~')),
            _buildKeyButton('-', () => _sendKey('-')),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton(String label, VoidCallback onTap, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: isAccent ? const Color(0xFFDC2626) : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
