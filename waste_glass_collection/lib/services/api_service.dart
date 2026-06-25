import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waste_glass_collection/models/collection_record_model.dart';
import 'package:waste_glass_collection/models/route_result_model.dart';
import 'package:waste_glass_collection/utils/constants.dart';

class ApiService {
  // Screen 1 — get optimised route from backend
  Future<RouteResult> getRoute() async {
    final res = await http
        .get(Uri.parse('${Constants.baseUrl}/api/route/optimised'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return RouteResult.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load route');
  }

  // Screen 2 — submit one collection after barcode scan
  Future<bool> submitCollection(CollectionRecord record) async {
    final res = await http
        .post(
          Uri.parse('${Constants.baseUrl}/api/collection'),
          headers: {'Content-Type': 'application/json'},
          body:    jsonEncode(record.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Screen 3 — get trip summary from backend
  Future<Map<String, dynamic>> getTripSummary() async {
    final res = await http
        .get(Uri.parse('${Constants.baseUrl}/api/trip/summary'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load trip summary');
  }

  // Screen 3 — sync all local records to backend
  Future<bool> syncCollections(List<CollectionRecord> records) async {
    final res = await http
        .post(
          Uri.parse('${Constants.baseUrl}/api/collection/sync'),
          headers: {'Content-Type': 'application/json'},
          body:    jsonEncode(records.map((r) => r.toJson()).toList()),
        )
        .timeout(const Duration(seconds: 15));

    return res.statusCode == 200 || res.statusCode == 201;
  }
}