import 'package:flutter/material.dart';
import 'package:waste_glass_collection/models/collection_record_model.dart';
import 'package:waste_glass_collection/models/supplier_model.dart';
import 'package:waste_glass_collection/services/api_service.dart';
import 'package:waste_glass_collection/services/sqlite_service.dart';

class TripProvider extends ChangeNotifier {
  final _api   = ApiService();
  final _local = SqliteService();

  List<Supplier> suppliers      = [];
  int            currentIndex   = 0;
  double         routeDistanceKm = 0;
  bool           isLoading      = false;
  String?        error;

  DateTime? _tripStart;
  DateTime? _tripEnd;

  Supplier? get currentSupplier =>
      currentIndex < suppliers.length ? suppliers[currentIndex] : null;

  bool get tripComplete => suppliers.isNotEmpty &&
      currentIndex >= suppliers.length;

  int get totalStops     => suppliers.length;
  int get remainingStops =>
      suppliers.where((s) => s.status != 'Collected').length;

  Duration? get tripDuration =>
      _tripStart == null ? null : (_tripEnd ?? DateTime.now()).difference(_tripStart!);

  // Called on app open — loads optimised route from backend
  Future<void> loadRoute() async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final result    = await _api.getRoute();
      suppliers       = result.suppliers;
      routeDistanceKm = result.routeDistanceKm;

      // Resume from wherever the backend says the trip actually is —
      // don't assume a fresh fetch means a fresh trip.
      final firstPending = suppliers.indexWhere((s) => s.status != 'Collected');
      currentIndex        = firstPending == -1 ? suppliers.length : firstPending;

      _tripStart = DateTime.now();
      _tripEnd   = currentIndex >= suppliers.length && suppliers.isNotEmpty
          ? DateTime.now()
          : null;
    } catch (e) {
      error = 'Could not load route. Check your connection.';
    }

    isLoading = false;
    notifyListeners();
  }

  // Called after successful collection on Screen 2
  Future<void> recordCollection(CollectionRecord record) async {
    // 1. Save locally first — offline first
    await _local.insertCollection(record);

    // 2. Try to post to backend immediately
    try {
      await _api.submitCollection(record);
    } catch (_) {
      // Offline — will sync on Screen 3
    }

    // 3. Advance to next stop
    suppliers[currentIndex].status = 'Collected';
    currentIndex++;
    if (currentIndex < suppliers.length) {
      suppliers[currentIndex].status = 'Next';
    } else {
      _tripEnd = DateTime.now();
    }

    notifyListeners();
  }

  // Called from Screen 3 sync button
  Future<bool> syncToServer() async {
    final unsynced = await _local.getUnsyncedCollections();
    if (unsynced.isEmpty) return true;

    try {
      final success = await _api.syncCollections(unsynced);
      if (success) {
        for (final r in unsynced) {
          if (r.localId != null) await _local.markSynced(r.localId!);
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}