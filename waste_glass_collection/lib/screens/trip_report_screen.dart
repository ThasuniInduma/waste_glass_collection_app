import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:waste_glass_collection/models/collection_record_model.dart';
import 'package:waste_glass_collection/models/supplier_model.dart';
import 'package:waste_glass_collection/providers/trip_provider.dart';
import 'package:waste_glass_collection/services/sqlite_service.dart';
import 'package:waste_glass_collection/utils/colors.dart';


class TripReportScreen extends StatefulWidget {
  const TripReportScreen({super.key});

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
  final _local = SqliteService();

  List<CollectionRecord> _records = [];
  bool  _loading     = true;
  bool  _syncing     = false;
  bool? _syncSuccess;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _local.getAllCollections();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  double get _totalKg =>
      _records.fold(0, (sum, r) => sum + r.clearKg + r.colouredKg);

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final hours   = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool _hasShortfall(CollectionRecord record, List<Supplier> suppliers) {
    final supplier = suppliers.firstWhere(
      (s) => s.id == record.supplierId,
      orElse: () => Supplier(
        id: '', name: '', lat: 0, lng: 0,
        expectedKg: 0, barcodeId: '',
        status: '', stopOrder: 0,
      ),
    );
    if (supplier.id.isEmpty) return false;
    return (record.clearKg + record.colouredKg) < supplier.expectedKg;
  }

  Future<void> _sync() async {
    setState(() {
      _syncing     = true;
      _syncSuccess = null;
    });

    final success = await context.read<TripProvider>().syncToServer();

    setState(() {
      _syncing     = false;
      _syncSuccess = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Report'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.read<TripProvider>().loadRoute();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, trip, _) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Total kg collected
                _buildSummaryRow(
                  label: 'Total kg Collected',
                  value: '${_totalKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 8),

                // Total stops
                _buildSummaryRow(
                  label: 'Total Stops',
                  value: '${trip.totalStops}',
                ),
                const SizedBox(height: 8),

                // Route distance
                _buildSummaryRow(
                  label: 'Route Distance',
                  value: '${trip.routeDistanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(height: 8),

                // Trip duration
                _buildSummaryRow(
                  label: 'Trip Duration',
                  value: _formatDuration(trip.tripDuration),
                ),
                const SizedBox(height: 8),

                // Trip date
                _buildSummaryRow(
                  label: 'Date',
                  value: DateFormat('d MMM yyyy').format(DateTime.now()),
                ),
                const Divider(height: 32),

                // Per supplier breakdown
                const Text(
                  'Collection Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                ..._records.map(
                  (r) => _buildSupplierCard(r, trip.suppliers),
                ),

                const SizedBox(height: 24),

                // Sync result
                if (_syncSuccess == true)
                  _buildBanner(
                    message: 'All records synced successfully.',
                    color: AppColors.success,
                    icon: Icons.cloud_done,
                  ),

                if (_syncSuccess == false)
                  _buildBanner(
                    message:
                        'Sync failed. Data is safe locally. Try again.',
                    color: AppColors.danger,
                    icon: Icons.cloud_off,
                  ),

                const SizedBox(height: 12),

                // Sync to server button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _syncing ? null : _sync,
                    child: _syncing
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Sync to Server',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(
    CollectionRecord record,
    List<Supplier> suppliers,
  ) {
    final supplier = suppliers.firstWhere(
      (s) => s.id == record.supplierId,
      orElse: () => Supplier(
        id: record.supplierId,
        name: record.supplierId,
        lat: 0, lng: 0,
        expectedKg: 0,
        barcodeId: '',
        status: 'Collected',
        stopOrder: 0,
      ),
    );

    final totalCollected = record.clearKg + record.colouredKg;
    final shortfall      = _hasShortfall(record, suppliers);
    final time           = DateFormat('hh:mm a').format(
      DateTime.parse(record.timestamp),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: shortfall
            ? const BorderSide(color: AppColors.warning, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Supplier name + shortfall badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    supplier.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (shortfall)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: const Text(
                      '⚠ Shortfall',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 8),

            // Clear, coloured, total
            Text('Clear Glass:    ${record.clearKg} kg'),
            Text('Coloured Glass: ${record.colouredKg} kg'),
            Text(
              'Total Collected: ${totalCollected.toStringAsFixed(1)} kg',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('Condition: ${record.condition}'),
            Text(
              'Time: $time',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            // Shortfall detail
            if (shortfall) ...[
              const SizedBox(height: 8),
              Text(
                'Expected ${supplier.expectedKg} kg — '
                '${(supplier.expectedKg - totalCollected).toStringAsFixed(1)} kg short',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}