import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';

class FoodEntryTile extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;

  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${entry.calories} kcal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.caloriesColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'P: ${entry.protein.toInt()}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.proteinColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'C: ${entry.carbs.toInt()}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.carbsColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'F: ${entry.fat.toInt()}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.fatColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.white.withOpacity(0.35),
              size: 20,
            ),
            onPressed: onDelete,
            tooltip: 'Delete meal',
          ),
        ],
      ),
    );
  }
}

