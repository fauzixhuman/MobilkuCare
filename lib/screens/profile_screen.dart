import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF203C50),
      appBar: AppBar(
        title: const Text('Profil Saya',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF203C50),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF386B7E), Color(0xFF8CE0FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: auth.user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        kIsWeb 
                          ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(auth.user!.photoURL!)}'
                          : auth.user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getInitials(auth.displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(auth.displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            // Name
            Text(
              auth.displayName.isNotEmpty ? auth.displayName : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Email
            Text(
              auth.user?.email ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 40),

            // Info cards
            _buildInfoTile(
              icon: Icons.person_outline,
              label: 'Nama',
              value: auth.displayName,
              onTapEdit: () => _editNameDialog(context, auth),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: auth.user?.email ?? '-',
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: auth.user?.emailVerified == true
                  ? 'Terverifikasi ✓'
                  : 'Aktif',
              valueColor: auth.user?.emailVerified == true ? const Color(0xFF4CAF50) : null,
            ),

            const Spacer(),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () => _confirmLogout(context, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: Colors.red.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTapEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF253440),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF8CE0FA), size: 20),
          ),
          const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: valueColor ?? Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (onTapEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                onPressed: onTapEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _editNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2B34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 8),
        title: const Text('Edit Nama',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Masukkan nama baru',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF253440),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != auth.displayName) {
                await auth.updateDisplayName(newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8CE0FA),
              foregroundColor: const Color(0xFF1E2B34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2B34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 8),
        title: const Text('Keluar?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: const Text('Yakin ingin keluar dari akun Anda?',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: Colors.red.withOpacity(0.5),
            ),
            child: const Text('Keluar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
