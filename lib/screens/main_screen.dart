import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import 'vehicle_list_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const HistoryScreen(),
    const VehicleListScreen(),
    const ProfileScreen(),
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.history_rounded,
    Icons.directions_car_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = [
    'Home',
    'Riwayat',
    'Kendaraan',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF203C50),
      body: Stack(
        children: [
          // Soft radial background glow
          RepaintBoundary(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    Color(0xFF203C50), // Slightly lighter glow
                    Color(0xFF203C50), // Base color
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      extendBody: true, // This allows the background to flow under the floating nav bar
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B34), // Match the card color of the app
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          return Stack(
            children: [
              // Sliding highlight indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: _currentIndex * itemWidth + 8,
                top: 8,
                bottom: 8,
                width: itemWidth - 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF386B7E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              // Icons & labels row
              Row(
                children: List.generate(4, (index) {
                  final isSelected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (index == 0) {
                          context.read<DashboardProvider>().requestReminder();
                        }
                        if (_currentIndex != index) {
                          setState(() => _currentIndex = index);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icons[index],
                              color: isSelected ? Colors.white : Colors.white38,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labels[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white38,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
