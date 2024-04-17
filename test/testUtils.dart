import 'package:isar/isar.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([Isar, IsarCollection, Query])
void main() {}

class MockQueryBuilder<OBJ, R, S> extends QueryBuilder<OBJ, R, S> {
  MockQueryBuilder(IsarCollection<OBJ> mockCollection)
      : super(QueryBuilderInternal(collection: mockCollection));
}
