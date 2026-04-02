import 'package:dio/dio.dart';

class WardrobeStatsModel {
  const WardrobeStatsModel({
    required this.totalItems,
    required this.needsCleaning,
    required this.atDryCleaner,
    required this.outfitsCount,
  });

  final int totalItems;
  final int needsCleaning;
  final int atDryCleaner;
  final int outfitsCount;

  factory WardrobeStatsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> byCleaning =
        (json['byCleaning'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return WardrobeStatsModel(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      needsCleaning: (byCleaning['needs_cleaning'] as num?)?.toInt() ?? 0,
      atDryCleaner: (byCleaning['at_dry_cleaner'] as num?)?.toInt() ?? 0,
      outfitsCount: (json['outfitsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class WardrobeStatsRepository {
  WardrobeStatsRepository(this._dio);

  final Dio _dio;

  Future<WardrobeStatsModel> getStats() async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>('wardrobe/stats');
    final Map<String, dynamic>? payload = response.data;
    if (payload == null || payload['success'] != true || payload['data'] == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }

    return WardrobeStatsModel.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }
}
