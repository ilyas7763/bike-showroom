import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'data/showroom_repository.dart';
import 'state/showroom_provider.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShowroomApp());
}

class ShowroomApp extends StatelessWidget {
  const ShowroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ShowroomProvider(ShowroomRepository(DatabaseHelper.instance))
            ..loadAll(),
      child: MaterialApp(
        title: 'Bike Showroom',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepOrange,
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(isDense: false),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
