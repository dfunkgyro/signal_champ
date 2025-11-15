import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int reward;
  final bool Function(Map<String, dynamic> stats) checkCondition;
  
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.reward,
    required this.checkCondition,
  });
}

class AchievementsService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final List<Achievement> _earnedAchievements = [];
  
  AchievementsService(this._supabase);
  
  List<Achievement> get earnedAchievements => List.unmodifiable(_earnedAchievements);
  
  static final List<Achievement> allAchievements = [
    Achievement(
      id: 'first_train',
      name: 'First Journey',
      description: 'Add your first train to the simulation',
      icon: Icons.train,
      reward: 50,
      checkCondition: (stats) => (stats['total_trains'] as int? ?? 0) >= 1,
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Run a train at maximum speed for 5 minutes',
      icon: Icons.speed,
      reward: 100,
      checkCondition: (stats) => (stats['max_speed_duration'] as int? ?? 0) >= 300,
    ),
    Achievement(
      id: 'master_controller',
      name: 'Master Controller',
      description: 'Successfully control 8 trains simultaneously',
      icon: Icons.control_camera,
      reward: 250,
      checkCondition: (stats) => (stats['max_concurrent_trains'] as int? ?? 0) >= 8,
    ),
    Achievement(
      id: 'perfect_week',
      name: 'Perfect Week',
      description: 'Complete 7 days without any incidents',
      icon: Icons.stars,
      reward: 500,
      checkCondition: (stats) => (stats['incident_free_days'] as int? ?? 0) >= 7,
    ),
    Achievement(
      id: 'traffic_master',
      name: 'Traffic Master',
      description: 'Achieve 95% efficiency rating',
      icon: Icons.trending_up,
      reward: 1000,
      checkCondition: (stats) => (stats['efficiency'] as double? ?? 0.0) >= 0.95,
    ),
  ];
  
  Future<void> loadEarnedAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final response = await _supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);
      
      final earnedIds = (response as List)
          .map((r) => r['achievement_id'] as String)
          .toSet();
      
      _earnedAchievements.clear();
      _earnedAchievements.addAll(
        allAchievements.where((a) => earnedIds.contains(a.id)),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }
  
  Future<List<Achievement>> checkAchievements(Map<String, dynamic> stats) async {
    final newAchievements = <Achievement>[];
    
    for (final achievement in allAchievements) {
      if (_hasAchievement(achievement.id)) continue;
      
      if (achievement.checkCondition(stats)) {
        await _awardAchievement(achievement);
        newAchievements.add(achievement);
      }
    }
    
    return newAchievements;
  }
  
  bool _hasAchievement(String achievementId) {
    return _earnedAchievements.any((a) => a.id == achievementId);
  }
  
  Future<void> _awardAchievement(Achievement achievement) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await _supabase
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievement.id,
            'earned_at': DateTime.now().toIso8601String(),
          });
      
      _earnedAchievements.add(achievement);
      notifyListeners();
      
      debugPrint('Awarded achievement: ${achievement.name}');
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
    }
  }
  
  double getCompletionPercentage() {
    if (allAchievements.isEmpty) return 0.0;
    return _earnedAchievements.length / allAchievements.length;
  }
  
  int getTotalRewardsEarned() {
    return _earnedAchievements.fold(0, (sum, a) => sum + a.reward);
  }
}
