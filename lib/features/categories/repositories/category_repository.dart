import '../../../models/category_model.dart';
import '../../../services/mock_data_service.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> getCategories(String examId, int year);
}

class CategoryRepository implements ICategoryRepository {
  const CategoryRepository();

  @override
  Future<List<CategoryModel>> getCategories(String examId, int year) async {
    return MockDataService.getCategories(examId);
  }
}
