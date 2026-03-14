import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/paper_model.dart';
import '../repositories/paper_repository.dart';
import '../repositories/supabase_paper_repository.dart';
import '../../../services/supabase_service.dart';

final paperRepositoryProvider = Provider<IPaperRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePaperRepository(client);
});

/// Family provider keyed by [PaperParams] with in-memory caching.
final papersProvider =
    FutureProvider.autoDispose.family<List<PaperModel>, PaperParams>(
  (ref, params) async {
    ref.keepAlive();
    return ref.watch(paperRepositoryProvider).getPapers(params);
  },
);
