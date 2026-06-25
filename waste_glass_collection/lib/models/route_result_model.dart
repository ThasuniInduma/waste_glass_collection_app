import 'package:waste_glass_collection/models/supplier_model.dart';

class RouteResult {
  final List<Supplier> suppliers;
  final double routeDistanceKm;

  RouteResult({required this.suppliers, required this.routeDistanceKm});

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final List list = json['suppliers'];
    return RouteResult(
      suppliers:       list.map((e) => Supplier.fromJson(e)).toList(),
      routeDistanceKm: (json['routeDistance'] as num).toDouble(),
    );
  }
}
