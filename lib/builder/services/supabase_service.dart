import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient? _client;

  SupabaseService._() {
    _refreshClient();
  }

  static final SupabaseService instance = SupabaseService._();

  void _refreshClient() {
    try {
      _client = Supabase.instance.client;
    } catch (_) {
      _client = null;
    }
  }

  bool get isEnabled => _client != null;

  SupabaseClient get _safeClient {
    _refreshClient();
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    return client;
  }

  Future<void> checkConnection() async {
    await _safeClient.from('railway_layouts').select('id').limit(1);
  }

  Future<String> saveLayout({
    required String name,
    required String description,
    required String xmlContent,
    required Map<String, dynamic> stats,
    String source = 'terminal_editor',
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'xml_content': xmlContent,
      'stats': stats,
      'source': source,
    };

    final response = await _safeClient
        .from('railway_layouts')
        .insert(payload)
        .select('id')
        .single();

    return response['id'].toString();
  }

  Future<Map<String, dynamic>?> fetchLatestLayout({
    String source = 'terminal_editor',
  }) async {
    final response = await _safeClient
        .from('railway_layouts')
        .select('id,name,description,xml_content,created_at')
        .eq('source', source)
        .order('created_at', ascending: false)
        .limit(1);

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchRecentLayouts({
    int limit = 5,
    String source = 'terminal_editor',
  }) async {
    final response = await _safeClient
        .from('railway_layouts')
        .select('id,name,description,created_at')
        .eq('source', source)
        .order('created_at', ascending: false)
        .limit(limit);

    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
