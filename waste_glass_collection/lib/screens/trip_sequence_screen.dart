import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_glass_collection/models/supplier_model.dart';
import 'package:waste_glass_collection/providers/trip_provider.dart';
import 'package:waste_glass_collection/screens/scan_collect_screen.dart';
import 'package:waste_glass_collection/screens/trip_report_screen.dart';
import 'package:waste_glass_collection/utils/colors.dart';


class TripSequenceScreen extends StatefulWidget {
  const TripSequenceScreen({super.key});

  @override
  State<TripSequenceScreen> createState() => _TripSequenceScreenState();
}

class _TripSequenceScreenState extends State<TripSequenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Sequence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TripProvider>().loadRoute(),
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, trip, _) {

          // Loading
          if (trip.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (trip.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(trip.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => trip.loadRoute(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty
          if (trip.suppliers.isEmpty) {
            return const Center(
              child: Text('No suppliers for today.'),
            );
          }

          // Trip complete — navigate to report
          if (trip.tripComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const TripReportScreen(),
                ),
              );
            });
          }

          return Column(
            children: [
              // Header — total route distance and remaining stops
              _buildHeader(trip),

              // Stop list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trip.suppliers.length,
                  itemBuilder: (context, index) {
                    return _buildStopCard(
                      context,
                      trip.suppliers[index],
                      index,
                      trip,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(TripProvider trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Total Stops', '${trip.totalStops}'),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildHeaderStat('Remaining', '${trip.remainingStops}'),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildHeaderStat(
                'Collected',
                '${trip.totalStops - trip.remainingStops}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Total route distance: ${trip.routeDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStopCard(
    BuildContext context,
    Supplier supplier,
    int index,
    TripProvider trip,
  ) {
    final isNext      = supplier.status == 'Next';
    final isCollected = supplier.status == 'Collected';

    Color statusColor;
    if (isCollected) {
      statusColor = AppColors.success;
    } else if (isNext) {
      statusColor = AppColors.info;
    } else {
      statusColor = AppColors.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isNext
            ? const BorderSide(color: AppColors.info, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          supplier.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                isCollected ? TextDecoration.lineThrough : null,
            color: isCollected ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text('Expected: ${supplier.expectedKg} kg'),
        trailing: Text(
          supplier.status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: isNext
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ScanCollectScreen(supplier: supplier),
                  ),
                )
            : null,
      ),
    );
  }
}