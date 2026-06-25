class CollectionRecord {
  final int?   localId;
  final String supplierId;
  final double clearKg;
  final double colouredKg;
  final String condition;
  final String timestamp;
  bool synced;

  CollectionRecord({
    this.localId,
    required this.supplierId,
    required this.clearKg,
    required this.colouredKg,
    required this.condition,
    required this.timestamp,
    this.synced = false,
  });

  // For saving to local SQLite
  Map<String, dynamic> toMap() => {
    'supplier_id':  supplierId,
    'clear_kg':     clearKg,
    'coloured_kg':  colouredKg,
    'condition':    condition,
    'timestamp':    timestamp,
    'synced':       synced ? 1 : 0,
  };

  // For reading from local SQLite
  factory CollectionRecord.fromMap(Map<String, dynamic> map) {
    return CollectionRecord(
      localId:    map['id'],
      supplierId: map['supplier_id'],
      clearKg:    map['clear_kg'],
      colouredKg: map['coloured_kg'],
      condition:  map['condition'],
      timestamp:  map['timestamp'],
      synced:     map['synced'] == 1,
    );
  }

  // For sending to backend
  Map<String, dynamic> toJson() => {
    'supplierId':  supplierId,
    'clearKg':     clearKg,
    'colouredKg':  colouredKg,
    'condition':   condition,
    'timestamp':   timestamp,
  };
}