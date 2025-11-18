import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/scenario_models.dart';

class ScenarioService extends ChangeNotifier {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  List<RailwayScenario> _myScenarios = [];
  List<RailwayScenario> _communityScenarios = [];
  List<RailwayScenario> _featuredScenarios = [];
  bool _isLoading = false;
  String? _error;

  ScenarioService(this._client);

  List<RailwayScenario> get myScenarios => _myScenarios;
  List<RailwayScenario> get communityScenarios => _communityScenarios;
  List<RailwayScenario> get featuredScenarios => _featuredScenarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Create a new scenario
  Future<RailwayScenario?> createScenario({
    required String name,
    required String description,
    required ScenarioCategory category,
    required ScenarioDifficulty difficulty,
    bool isPublic = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final scenario = RailwayScenario(
        id: _uuid.v4(),
        name: name,
        description: description,
        authorId: user.id,
        authorName: user.userMetadata?['full_name'] as String? ?? 'Anonymous',
        category: category,
        difficulty: difficulty,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final data = await _client
          .from('scenarios')
          .insert(scenario.toJson())
          .select()
          .single();

      final createdScenario = RailwayScenario.fromJson(data);
      _myScenarios.add(createdScenario);

      _isLoading = false;
      notifyListeners();

      return createdScenario;
    } catch (e) {
      _error = 'Failed to create scenario: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update an existing scenario
  Future<bool> updateScenario(RailwayScenario scenario) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedScenario = scenario.copyWith(
        updatedAt: DateTime.now(),
      );

      await _client
          .from('scenarios')
          .update(updatedScenario.toJson())
          .eq('id', scenario.id);

      // Update local cache
      final index = _myScenarios.indexWhere((s) => s.id == scenario.id);
      if (index != -1) {
        _myScenarios[index] = updatedScenario;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to update scenario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a scenario
  Future<bool> deleteScenario(String scenarioId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _client.from('scenarios').delete().eq('id', scenarioId);

      _myScenarios.removeWhere((s) => s.id == scenarioId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to delete scenario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load user's scenarios
  Future<void> loadMyScenarios() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _client.auth.currentUser;
      if (user == null) {
        _myScenarios = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _client
          .from('scenarios')
          .select()
          .eq('author_id', user.id)
          .order('updated_at', ascending: false);

      _myScenarios = (data as List)
          .map((json) => RailwayScenario.fromJson(json as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load scenarios: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load community scenarios (public scenarios)
  Future<void> loadCommunityScenarios({
    ScenarioCategory? category,
    ScenarioDifficulty? difficulty,
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      var query = _client.from('scenarios').select().eq('is_public', true);

      if (category != null) {
        query = query.eq('category', category.name);
      }

      if (difficulty != null) {
        query = query.eq('difficulty', difficulty.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final data = await query
          .order('downloads', ascending: false)
          .limit(limit);

      _communityScenarios = (data as List)
          .map((json) => RailwayScenario.fromJson(json as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load community scenarios: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load featured scenarios
  Future<void> loadFeaturedScenarios() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _client
          .from('scenarios')
          .select()
          .eq('is_featured', true)
          .eq('is_public', true)
          .order('rating', ascending: false)
          .limit(20);

      _featuredScenarios = (data as List)
          .map((json) => RailwayScenario.fromJson(json as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load featured scenarios: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single scenario by ID
  Future<RailwayScenario?> getScenario(String scenarioId) async {
    try {
      final data = await _client
          .from('scenarios')
          .select()
          .eq('id', scenarioId)
          .single();

      return RailwayScenario.fromJson(data);
    } catch (e) {
      _error = 'Failed to load scenario: $e';
      notifyListeners();
      return null;
    }
  }

  /// Increment download count
  Future<void> incrementDownloads(String scenarioId) async {
    try {
      await _client.rpc('increment_scenario_downloads', params: {
        'scenario_id': scenarioId,
      });
    } catch (e) {
      debugPrint('Failed to increment downloads: $e');
    }
  }

  /// Rate a scenario
  Future<bool> rateScenario(String scenarioId, double rating) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Insert or update rating
      await _client.from('scenario_ratings').upsert({
        'scenario_id': scenarioId,
        'user_id': user.id,
        'rating': rating,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Recalculate average rating
      await _client.rpc('update_scenario_rating', params: {
        'scenario_id': scenarioId,
      });

      return true;
    } catch (e) {
      _error = 'Failed to rate scenario: $e';
      notifyListeners();
      return false;
    }
  }

  /// Publish a scenario (make it public)
  Future<bool> publishScenario(String scenarioId) async {
    try {
      await _client
          .from('scenarios')
          .update({'is_public': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', scenarioId);

      // Update local cache
      final index = _myScenarios.indexWhere((s) => s.id == scenarioId);
      if (index != -1) {
        _myScenarios[index] = _myScenarios[index].copyWith(
          isPublic: true,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to publish scenario: $e';
      notifyListeners();
      return false;
    }
  }

  /// Unpublish a scenario (make it private)
  Future<bool> unpublishScenario(String scenarioId) async {
    try {
      await _client
          .from('scenarios')
          .update({'is_public': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', scenarioId);

      // Update local cache
      final index = _myScenarios.indexWhere((s) => s.id == scenarioId);
      if (index != -1) {
        _myScenarios[index] = _myScenarios[index].copyWith(
          isPublic: false,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to unpublish scenario: $e';
      notifyListeners();
      return false;
    }
  }

  /// Duplicate a scenario
  Future<RailwayScenario?> duplicateScenario(String scenarioId) async {
    try {
      final original = await getScenario(scenarioId);
      if (original == null) return null;

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final duplicate = original.copyWith(
        id: _uuid.v4(),
        name: '${original.name} (Copy)',
        authorId: user.id,
        authorName: user.userMetadata?['full_name'] as String? ?? 'Anonymous',
        isPublic: false,
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        downloads: 0,
        rating: 0,
        ratingCount: 0,
      );

      final data = await _client
          .from('scenarios')
          .insert(duplicate.toJson())
          .select()
          .single();

      final created = RailwayScenario.fromJson(data);
      _myScenarios.add(created);

      // Increment downloads on original
      await incrementDownloads(scenarioId);

      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to duplicate scenario: $e';
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
