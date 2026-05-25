import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gig.dart';

class GigRepository {
  final SupabaseClient _client;
  GigRepository(this._client);

  Future<List<Gig>> getGigs({int page = 0, String? category}) async {
    const int pageSize = 10;
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from('gigs').select().eq('is_active', true);

    if (category != null && category != 'Tất cả') {
      query = query.eq('category', category);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List).map((json) => Gig.fromJson(json)).toList();
  }

  Future<void> createGig(Map<String, dynamic> gigData) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('gigs').insert({...gigData, 'user_id': userId});
  }
}
