import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';

void applyWebCredentials(Dio dio) {
  (dio.httpClientAdapter as BrowserHttpClientAdapter).withCredentials = true;
}
