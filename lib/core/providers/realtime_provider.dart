import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

/// Streams INSERT events from the `papers` table via Supabase Realtime.
/// Consumers can listen to invalidate their caches when new papers arrive.
final newPaperStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final client     = ref.watch(supabaseClientProvider);
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client
        .channel('public:papers')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'papers',
          callback: (payload) => controller.add(payload.newRecord),
        )
        .subscribe();

    ref.onDispose(() {
      client.removeChannel(channel);
      controller.close();
    });

    return controller.stream;
  },
);
