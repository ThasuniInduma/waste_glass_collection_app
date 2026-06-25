import 'package:intl/intl.dart';

class Constants {
  static const String baseUrl = 'http://192.168.8.137:5000';
  static String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());
}