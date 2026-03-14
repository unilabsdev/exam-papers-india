import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/year_model.dart';
import '../repositories/year_repository.dart';
import '../repositories/supabase_year_repository.dart';
import '../../../services/supabase_service.dart';

final yearRepositoryProvider = Provider<IYearRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseYearRepository(client);
});

/// Family provider keyed by [examId] with in-memory caching.
final yearsProvider =
    FutureProvider.autoDispose.family<List<YearModel>, String>(
  (ref, examId) async {
    ref.keepAlive();
    return ref.watch(yearRepositoryProvider).getYears(examId);
  },
);
