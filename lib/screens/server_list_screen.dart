import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServerProvider>();
    final servers = provider.servers;
    final activeId = provider.activeServer?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Profil VPS'),
      ),
      body: servers.isEmpty
          ? const Center(
              child: Text(
                'Belum ada profil VPS tersimpan.\nTekan tombol + untuk menambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: servers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isActive = server.id == activeId;

                return Card(
                  elevation: isActive ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? AppTheme.primaryBlue
                          : Colors.grey.withAlpha(30),
                      foregroundColor: isActive ? Colors.white : Colors.grey,
                      child: Icon(
                        isActive ? Icons.check_rounded : Icons.dns_outlined,
                      ),
                    ),
                    title: Text(
                      server.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${server.username}@${server.host}:${server.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () => _showServerDialog(context, server: server),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Hapus',
                          onPressed: () => _confirmDelete(context, server),
                        ),
                      ],
                    ),
                    onTap: () {
                      provider.selectServer(server);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah VPS'),
        onPressed: () => _showServerDialog(context),
      ),
    );
  }

  void _showServerDialog(BuildContext context, {ServerProfile? server}) {
    final isEdit = server != null;
    final nameCtrl = TextEditingController(text: server?.name ?? '');
    final hostCtrl = TextEditingController(text: server?.host ?? '');
    final portCtrl = TextEditingController(text: server?.port.toString() ?? '22');
    final userCtrl = TextEditingController(text: server?.username ?? 'root');
    final passCtrl = TextEditingController(text: server?.password ?? '');
    final keyCtrl = TextEditingController(text: server?.privateKey ?? '');
    bool showKeyField = server?.privateKey != null && server!.privateKey!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Profil VPS' : 'Tambah Profil VPS Baru',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Server / Label',
                    hintText: 'Contoh: VPS Production Singapore',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: hostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Host / IP VPS',
                          hintText: '103.xxx.xxx.xxx',
                          prefixIcon: Icon(Icons.language_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: portCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '22',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'root atau ubuntu',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password SSH',
                    hintText: 'Password login VPS',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (!showKeyField)
                  TextButton.icon(
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('Gunakan SSH Private Key (Opsional)'),
                    onPressed: () => setModalState(() => showKeyField = true),
                  )
                else
                  TextField(
                    controller: keyCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Private Key (PEM)',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Profil'),
                  onPressed: () {
                    final host = hostCtrl.text.trim();
                    if (host.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Host / IP VPS tidak boleh kosong')),
                      );
                      return;
                    }

                    final newProfile = ServerProfile(
                      id: server?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim().isEmpty ? host : nameCtrl.text.trim(),
                      host: host,
                      port: int.tryParse(portCtrl.text.trim()) ?? 22,
                      username: userCtrl.text.trim().isEmpty ? 'root' : userCtrl.text.trim(),
                      password: passCtrl.text,
                      privateKey: keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim(),
                    );

                    context.read<ServerProvider>().saveServer(newProfile);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServerProfile server) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Profil VPS?'),
        content: Text('Profil server "${server.name}" (${server.host}) akan dihapus.'),
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
            child: const Text('Hapus'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ServerProvider>().deleteServer(server.id);
            },
          ),
        ],
      ),
    );
  }
}
