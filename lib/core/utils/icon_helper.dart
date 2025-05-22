import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> iconMap = {
    // FixedCategory
    'home': Icons.home,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'person': Icons.person,
    'credit_card': Icons.credit_card,
    'medical_services': Icons.medical_services,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'school': Icons.school,
    // AntCategory
    'restaurant_menu': Icons.restaurant_menu,
    'games': Icons.games,
    'shopping_bag': Icons.shopping_bag,
    'phone_android': Icons.phone_android,
    'attach_money': Icons.attach_money,
  };

  static IconData getIconByName(String name) {
    return iconMap[name] ?? Icons.help_outline;
  }

  static String getNameByIcon(IconData icon) {
    return iconMap.entries.firstWhere(
      (entry) => entry.value == icon,
      orElse: () => const MapEntry('help_outline', Icons.help_outline),
    ).key;
  }

  /// Obtener el nombre del ícono a partir de su código
  static String getIconNameByCodePoint(int codePoint) {
    // Buscar el ícono en el mapa por su código
    final entry = iconMap.entries.firstWhere(
      (entry) => entry.value.codePoint == codePoint,
      orElse: () => const MapEntry('help_outline', Icons.help_outline),
    );
    return entry.key;
  }
} 