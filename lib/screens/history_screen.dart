import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/period.dart';
import '../models/activity.dart';

import '../providers/dashboard_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Period> _periods = [];

  @override
  void initState() {
    super.initState();
    // Fetch happens in didChangeDependencies to ensure context is fully available and reactive
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vId = context.watch<DashboardProvider>().selectedVehicle?.id;
    _fetchHistory(vId);
  }

  Future<void> _fetchHistory(String? vId) async {
    if (vId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _periods = [];
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint('Fetching history for vehicle: $vId');

    try {
      final data = await DatabaseHelper().getHistory(vId);
      setState(() {
        _periods = data.map((model) => Period.fromJson(model)).toList();
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching history: $e\n$stackTrace');
      debugPrint('Data fetch attempt finished with error.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF203C50),
      appBar: AppBar(
        title: const Text('Riwayat Perawatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF203C50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _periods.isEmpty 
              ? const Center(child: Text('Belum ada riwayat perawatan.', style: TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: () {
                    final vId = context.read<DashboardProvider>().selectedVehicle?.id;
                    return _fetchHistory(vId);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _periods.length,
                    itemBuilder: (context, index) {
                      final period = _periods[index];
                      return _buildPeriodCard(period, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildPeriodCard(Period period, int index) {
    return Card(
      color: const Color(0xFF1E2B34),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: Text(
          'Periode ${period.noPeriode}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          'Total Cuci: ${period.activities?.where((a) => a.isWash).length ?? 0}',
          style: const TextStyle(color: Colors.white70),
        ),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: period.noPeriode == _periods.first.noPeriode ? const Color(0xFF386B7E) : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            period.noPeriode == _periods.first.noPeriode ? 'Berjalan' : 'Selesai',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        initiallyExpanded: index == 0,
        children: period.activities?.map((activity) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF253440),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activity.isWash ? const Color(0xFF8CE0FA).withOpacity(0.15) : const Color(0xFFF9F871).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activity.isWash ? const Color(0xFF8CE0FA).withOpacity(0.25) : const Color(0xFFF9F871).withOpacity(0.25),
                    ),
                  ),
                  child: Icon(
                    activity.isWash ? Icons.local_car_wash : Icons.build_circle,
                    color: activity.isWash ? const Color(0xFF8CE0FA) : const Color(0xFFF9F871),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildActivityTitle(activity),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activity.createdAt.day}/${activity.createdAt.month}/${activity.createdAt.year}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      if (activity.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.note,
                                style: const TextStyle(color: Colors.amber, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList() ?? [],
      ),
    );
  }

  String _buildActivityTitle(Activity activity) {
    List<String> actions = [];
    if (activity.isWash) actions.add('Cuci');
    if (activity.isWaxBody) actions.add('Wax Bodi');
    if (activity.isWaxGlass) actions.add('Wax Kaca');
    if (activity.isVacuum) actions.add('Vacuum');
    
    if (actions.isEmpty) return 'Tindakan Lainnya';
    return actions.join(', ');
  }
}
