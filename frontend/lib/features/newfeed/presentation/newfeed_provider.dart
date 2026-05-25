import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to trigger refresh across feed tabs when a post is edited or deleted
final newfeedProvider = StateProvider<int>((ref) => 0);
