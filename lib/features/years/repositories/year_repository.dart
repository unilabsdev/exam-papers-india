import '../../../models/year_model.dart';
import '../../../services/mock_data_service.dart';

abstract class IYearRepository {
  Future<List<YearModel>> getYears(String examId);
}

class YearRepository implements IYearRepository {
  const YearRepository();

  @override
  Future<List<YearModel>> getYears(String examId) async {
    return MockDataService.getYears(examId);
  }
}
