import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import 'activity_entry_screen.dart';
import 'notification_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _reminderShownForVehicleId;
  bool _suppressReminder = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DashboardProvider>();
    Future.microtask(() {
      provider.fetchVehicles();
      provider.addListener(_onDashboardUpdate);
    });
  }

  @override
  void dispose() {
    // Remove listener safely
    try {
      context.read<DashboardProvider>().removeListener(_onDashboardUpdate);
    } catch (_) {}
    super.dispose();
  }

  void _onDashboardUpdate() {
    final provider = context.read<DashboardProvider>();
    
    if (provider.forceReminder) {
      _reminderShownForVehicleId = null;
      provider.consumeReminder();
    }

    if (provider.dashboardData != null && provider.selectedVehicle != null && !provider.isLoading) {
      if (provider.suppressWashReminder) {
        provider.suppressWashReminder = false;
        return;
      }
      if (_suppressReminder) {
        _suppressReminder = false;
        return;
      }
      _showWashReminder(provider);
    }
  }

  void _showWashReminder(DashboardProvider provider) {
    if (_suppressReminder) return;
    
    final currentVehicleId = provider.selectedVehicle!.id;
    final data = provider.dashboardData!;
    if (data['active_period'] == null) return;
    
    final washCount = data['active_period']['wash_count'] as int;

    // Create a unique key for the reminder state
    final reminderKey = '\$currentVehicleId-\$washCount';
    if (_reminderShownForVehicleId == reminderKey) return;
    _reminderShownForVehicleId = reminderKey;

    final vehicleName = provider.selectedVehicle!.namaKendaraan;
    final nextWash = washCount + 1;

    String title;
    String message;
    IconData icon;
    Color accentColor;

    if (washCount == 2) {
      title = 'Cuci ke-$washCount dari 6';
      message = 'Cuci berikutnya (ke-3) untuk $vehicleName adalah Wax Bodi! Jangan lupa aplikasikan wax.';
      icon = Icons.auto_awesome;
      accentColor = const Color(0xFF8CE0FA); // Light Teal
    } else if (washCount == 5) {
      title = 'Cuci ke-$washCount dari 6';
      message = 'Cuci berikutnya (ke-6) untuk $vehicleName adalah Full Wax! Waktunya poles total.';
      icon = Icons.auto_awesome;
      accentColor = const Color(0xFFFF8F00); // Orange warning
    } else {
      title = 'Cuci ke-$washCount dari 6';
      message = '$vehicleName — Cuci berikutnya adalah cuci ke-$nextWash.';
      icon = Icons.local_car_wash_rounded;
      accentColor = const Color(0xFF8CE0FA); // Light Teal
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            // Blur background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
            // Centered popup
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2B34),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 30, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF253440), // App surface color
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF386B7E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleSelector(BuildContext context, DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2B34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...provider.vehicles.map((vehicle) {
                final isSelected = provider.selectedVehicle?.id == vehicle.id;
                return GestureDetector(
                  onTap: () {
                    _reminderShownForVehicleId = null;
                    provider.selectVehicle(vehicle);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF386B7E) : const Color(0xFF253440),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all(color: const Color(0xFF8CE0FA), width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          vehicle.tipe == 'Mobil' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                          color: const Color(0xFF8CE0FA),
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            vehicle.namaKendaraan,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF8CE0FA), size: 22),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: provider.isLoading && provider.vehicles.isEmpty
            ? _buildShimmerLoading()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeGreeting(),
                    const SizedBox(height: 32),
                    _buildTopHeader(provider),
                    const SizedBox(height: 24),
                    _buildBannerCard(provider),
                    const SizedBox(height: 32),
                    const Text(
                      'Status Perawatan',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (provider.selectedVehicle != null) ...[
                      if (provider.isLoading)
                        _buildGridShimmer()
                      else if (provider.dashboardData != null)
                        _buildStatusGrid(provider)
                      else
                        const Center(
                          child: Text('Gagal memuat data dashboard', style: TextStyle(color: Colors.white70)),
                        ),
                    ] else ...[
                      const Center(
                        child: Text('Pilih atau tambah kendaraan terlebih dahulu', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: provider.selectedVehicle != null ? Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF386B7E),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            _suppressReminder = true;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF1E2B34),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              builder: (context) => const ActivityEntryScreen(),
            );
          },
        ),
      ) : null,
    );
  }

  Widget _buildWelcomeGreeting() {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName.isNotEmpty
        ? auth.displayName.split(' ').first
        : 'User';

    final hour = DateTime.now().hour;
    String subGreeting;
    if (hour < 12) {
      subGreeting = 'Selamat pagi';
    } else if (hour < 15) {
      subGreeting = 'Selamat siang';
    } else if (hour < 18) {
      subGreeting = 'Selamat sore';
    } else {
      subGreeting = 'Selamat malam';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hallo, $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subGreeting,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _showNotificationHistory(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF386B7E), // Darker teal accent
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.vehicles.isNotEmpty) ...[
          const Text('Pilih Kendaraan', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showVehicleSelector(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2B34),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.selectedVehicle!.tipe == 'Mobil' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                    color: const Color(0xFF8CE0FA),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    provider.selectedVehicle!.namaKendaraan,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                ],
              ),
            ),
          ),
        ] else
          GestureDetector(
            onTap: () => _showVehicleSelector(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2B34),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white38),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pilih kendaraan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerCard(DashboardProvider provider) {
    final vehicle = provider.selectedVehicle;
    final vehicleName = vehicle?.namaKendaraan ?? 'Kendaraan';
    final vehicleType = vehicle?.tipe ?? 'Mobil';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              vehicleType == 'Mobil' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
              color: Colors.blue.shade700,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '✓ Terawat & Tercatat',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(DashboardProvider provider) {
    final data = provider.dashboardData!;
    final lastWashTimer = data['last_wash_timer'];
    final activePeriod = data['active_period'];
    final washCount = activePeriod['wash_count'] as int;

    String lastWashValue = 'Belum pernah dicuci';
    bool isOverdue = false;
    if (lastWashTimer != null && lastWashTimer['text'] != null) {
      lastWashValue = lastWashTimer['text'];
      isOverdue = lastWashTimer['is_overdue'] == true;
    }

    // Overdue warning
    String? washWarning;
    if (isOverdue) {
      washWarning = '⚠️ Sudah lama tidak dicuci!';
    }

    String nextAction = 'Cuci Biasa';
    Color actionColor = const Color(0xFF8CE0FA); // Light Blue
    if (washCount == 2) {
      nextAction = 'Wax Bodi (Cuci ke-3)';
      actionColor = const Color(0xFFE8D7F6); // Light Purple
    } else if (washCount == 5) {
      nextAction = 'Full Wax (Cuci ke-6)';
      actionColor = const Color(0xFFF9F871); // Light Yellow
    }

    return Column(
      children: [
        _buildInfoCard(
          title: 'Terakhir Dicuci',
          value: lastWashValue,
          subtitle: washWarning,
          icon: Icons.calendar_today,
          color: isOverdue ? const Color(0xFFFFCDD2) : const Color(0xFF8CE0FA),
          iconColor: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Siklus Saat Ini',
          value: 'Cuci ke-$washCount dari 6',
          subtitle: 'Sudah $washCount kali dicuci di periode ini',
          icon: Icons.local_car_wash,
          color: const Color(0xFFE8D7F6), // Light Purple
          iconColor: Colors.purple.shade700,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Aksi Berikutnya',
          value: nextAction,
          icon: Icons.star_border,
          color: actionColor,
          iconColor: Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  void _showNotificationHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
    );
  }

  Widget _buildShimmerLoading() {
    return RepaintBoundary(
      child: Shimmer.fromColors(
      baseColor: const Color(0xFF1E2B34),
      highlightColor: const Color(0xFF253440),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 160, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
                Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 32),
            Container(width: 180, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            _buildGridShimmerCore(),
          ],
        ),
      ),
    ));
  }

  Widget _buildGridShimmer() {
    return RepaintBoundary(
      child: Shimmer.fromColors(
      baseColor: const Color(0xFF1E2B34),
      highlightColor: const Color(0xFF253440),
      child: _buildGridShimmerCore(),
    ));
  }

  Widget _buildGridShimmerCore() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            const SizedBox(width: 16),
            Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
      ],
    );
  }
}
