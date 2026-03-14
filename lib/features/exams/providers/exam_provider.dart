import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exam_model.dart';
import '../repositories/exam_repository.dart';
import '../repositories/supabase_exam_repository.dart';
import '../../../services/supabase_service.dart';

final examRepositoryProvider = Provider<IExamRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExamRepository(client);
});

/// Exam list provider with in-memory caching via [keepAlive].
final examsProvider = FutureProvider.autoDispose<List<ExamModel>>((ref) async {
  ref.keepAlive();
  return ref.watch(examRepositoryProvider).getExams();
});
