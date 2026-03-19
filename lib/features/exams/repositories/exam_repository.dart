import '../../../models/exam_model.dart';
import '../../../services/mock_data_service.dart';

/// Contract — swap implementation for SupabaseExamRepository when ready.
abstract class IExamRepository {
  Future<List<ExamModel>> getExams();
}

/// Mock implementation backed by [MockDataService].
class ExamRepository implements IExamRepository {
  const ExamRepository();

  @override
  Future<List<ExamModel>> getExams() async {
    return MockDataService.exams;
  }
}

