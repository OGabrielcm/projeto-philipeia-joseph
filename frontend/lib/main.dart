import 'package:flutter/material.dart';
import 'views/login/login_view.dart';

void main() {
  runApp(MaterialApp(
    title: 'Philipeia',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1F2125),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD300),
        secondary: Color(0xFFFFD300),
        surface: Color(0xFF2A2D31),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16181B),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1F2125),
      ),
      cardColor: const Color(0xFF2A2D31),
      dividerColor: const Color(0xFF3A3D42),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD300),
          foregroundColor: const Color(0xFF16181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB5B9C0),
          side: const BorderSide(color: Color(0xFF3A3D42)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD300)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16181B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3D42)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3D42)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFD300), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF7A7E85)),
        hintStyle: const TextStyle(color: Color(0xFF7A7E85)),
        prefixIconColor: const Color(0xFF7A7E85),
        suffixIconColor: const Color(0xFF7A7E85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF16181B),
        selectedItemColor: Color(0xFFFFD300),
        unselectedItemColor: Color(0xFF7A7E85),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFD300),
        foregroundColor: Color(0xFF16181B),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2D31),
        contentTextStyle: TextStyle(color: Color(0xFFB5B9C0)),
      ),
    ),
    home: const LoginView(),
  ));
}
