import 'models/item_model.dart';
import 'search_remote_data_source.dart';

class SearchRepository {
  SearchRepository(this._remoteDataSource);

  final SearchRemoteDataSource _remoteDataSource;

  Future<List<ItemModel>> search({
    required String query,
    String? category,
    String? status,
  }) {
    return _remoteDataSource.search(
      query: query,
      category: category,
      status: status,
    );
  }
}
