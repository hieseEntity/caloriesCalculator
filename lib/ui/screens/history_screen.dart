import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/tracker/tracker_controller.dart';

class HistoryScreen extends StatelessWidget {
  final TrackerController trackerController;
  final int targetCalories;

  const HistoryScreen({
    super.key,
    required this.trackerController,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = trackerController.historySummaries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Intake History'),
      ),
      body: summaries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No logged days yet',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                final progress = summary.targetCalories > 0
                    ? (summary.totalCalories / summary.targetCalories).clamp(0.0, 1.5)
                    : 0.0;
                final isUnder = summary.totalCalories <= summary.targetCalories;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            summary.dateString,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnder
                                  ? AppTheme.primary.withOpacity(0.15)
                                  : Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${summary.totalCalories} / ${summary.targetCalories} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnder ? AppTheme.primary : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress > 1.0 ? 1.0 : progress,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnder ? AppTheme.caloriesColor : Colors.redAccent,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${summary.entryCount} meals logged',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                          ),
                          Row(
                            children: [
                              Text('P: ${summary.totalProtein.toInt()}g', style: const TextStyle(fontSize: 11, color: AppTheme.proteinColor, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('C: ${summary.totalCarbs.toInt()}g', style: const TextStyle(fontSize: 11, color: AppTheme.carbsColor, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('F: ${summary.totalFat.toInt()}g', style: const TextStyle(fontSize: 11, color: AppTheme.fatColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

