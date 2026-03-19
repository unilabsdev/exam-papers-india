import '../../../models/paper_model.dart';
import '../../../services/mock_data_service.dart';

/// Immutable key used as the family parameter for [papersProvider].
/// Implements value equality so Riverpod can deduplicate cache entries.
class PaperParams {
  final String examId;
  final int year;
  final String categoryId;

  const PaperParams({
    required this.examId,
    required this.year,
    required this.categoryId,
  });

  @override
  bool operator ==(Object other) =>
      other is PaperParams &&
      other.examId == examId &&
      other.year == year &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(examId, year, categoryId);

  @override
  String toString() =>
      'PaperParams(examId: $examId, year: $year, categoryId: $categoryId)';
}

abstract class IPaperRepository {
  Future<List<PaperModel>> getPapers(PaperParams params);
}

class PaperRepository implements IPaperRepository {
  const PaperRepository();

  @override
  Future<List<PaperModel>> getPapers(PaperParams params) async {
    return MockDataService.getPapers(
      examId:     params.examId,
      year:       params.year,
      categoryId: params.categoryId,
    );
  }
}
