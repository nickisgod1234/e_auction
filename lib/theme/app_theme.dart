import 'package:flutter/material.dart';

// Theme configuration - Change this to switch between different clients
class AppTheme {
  static const String currentClient = 'E-Auction'; // Options: 'morket', 'E-Auction', 'client3'
  
  // Theme data for different clients
  static ThemeData getThemeForClient(String client) {
    switch (client) {
      case 'morket':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Add more theme extensions
          extensions: [
            CustomThemeExtension(
              primaryColor: Colors.green,
              secondaryColor: Colors.green.shade100,
              accentColor: Colors.green.shade600,
            ),
          ],
        );
        
      case 'E-Auction':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          extensions: [
            CustomThemeExtension(
              primaryColor: Colors.blue,
              secondaryColor: Colors.blue.shade100,
              accentColor: Colors.blue.shade600,
            ),
          ],
        );
        
      case 'client3':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 1,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          extensions: [
            CustomThemeExtension(
              primaryColor: Colors.orange,
              secondaryColor: Colors.orange.shade100,
              accentColor: Colors.orange.shade600,
            ),
          ],
        );
        
      default:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          extensions: [
            CustomThemeExtension(
              primaryColor: Colors.green,
              secondaryColor: Colors.green.shade100,
              accentColor: Colors.green.shade600,
            ),
          ],
        );
    }
  }
  
  // App title for different clients
  static String getAppTitle(String client) {
    switch (client) {
      case 'morket':
        return 'MORKET';
      case 'E-Auction':
        return 'E-Auction';
      case 'client3':
        return 'Client 3 App';
      default:
        return 'E-Auction';
    }
  }
}

// Custom theme extension to access theme colors throughout the app
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  const CustomThemeExtension({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
  }) {
    return CustomThemeExtension(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
    covariant ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
    );
  }
}

// Extension to easily access custom theme colors
extension CustomThemeExtensionX on BuildContext {
  CustomThemeExtension get customTheme => 
      Theme.of(this).extension<CustomThemeExtension>() ?? 
      const CustomThemeExtension(
        primaryColor: Colors.green,
        secondaryColor: Colors.green,
        accentColor: Colors.green,
      );
} 