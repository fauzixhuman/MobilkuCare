import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/vehicle.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF203C50),
      appBar: AppBar(
        title: const Text('Kelola Kendaraan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF203C50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: provider.isLoading && provider.vehicles.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : provider.vehicles.isEmpty
              ? const Center(child: Text('Belum ada kendaraan.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: provider.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = provider.vehicles[index];
                    return _buildVehicleCard(context, vehicle, provider);
                  },
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF8CE0FA), // Light Blue
          child: const Icon(Icons.add, color: Color(0xFF0F1B23)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VehicleFormScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle, DashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8D7F6), // Light Purple
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            vehicle.tipe == 'Mobil' ? Icons.directions_car : Icons.two_wheeler,
            color: const Color(0xFF0F1B23),
          ),
        ),
        title: Text(
          vehicle.namaKendaraan,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          vehicle.tipe,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF8CE0FA)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleFormScreen(vehicle: vehicle),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFF6A8A8)),
              onPressed: () {
                _confirmDelete(context, vehicle.id, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2B34),
        title: const Text('Hapus Kendaraan', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus kendaraan ini?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFF6A8A8))),
            onPressed: () {
              provider.deleteVehicle(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
