import 'package:intl/intl.dart';

class Constants {
  static const String baseUrl = 'https://waste-glass-collection-a6byhpa3axdqf0e6.centralindia-01.azurewebsites.net';
  static String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());
}