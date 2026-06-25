class Supplier {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double expectedKg;
  final String barcodeId;
  String status;
  final int stopOrder;

  Supplier({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.expectedKg,
    required this.barcodeId,
    required this.status,
    required this.stopOrder,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id:         json['id'],
      name:       json['name'],
      lat:        (json['lat'] as num).toDouble(),
      lng:        (json['lng'] as num).toDouble(),
      expectedKg: (json['expectedKg'] as num).toDouble(),
      barcodeId:  json['barcodeId'],
      status:     json['status'],
      stopOrder:  json['stopOrder'],
    );
  }
}