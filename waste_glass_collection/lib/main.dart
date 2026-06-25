import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'screens/trip_sequence_screen.dart';
import 'utils/colors.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProvider(),
      child: MaterialApp(
        title: 'Waste Glass Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          useMaterial3: true,
        ),
        home: const TripSequenceScreen(),
      ),
    );
  }
}