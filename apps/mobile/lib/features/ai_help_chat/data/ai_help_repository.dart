import 'ai_help_remote_data_source.dart';

class AiHelpRepository {
  AiHelpRepository(this._remote);

  final AiHelpRemoteDataSource _remote;

  Future<({String answer, String sessionId, List<String> suggestions})> chat({
    required String query,
    String? sessionId,
    String? currentScreen,
  }) =>
      _remote.chat(
        query: query,
        sessionId: sessionId,
        currentScreen: currentScreen,
      );
}
