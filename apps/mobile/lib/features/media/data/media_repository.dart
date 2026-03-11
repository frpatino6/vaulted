import 'package:image_picker/image_picker.dart';

import 'media_remote_data_source.dart';

class MediaRepository {
  MediaRepository(this._remote);

  final MediaRemoteDataSource _remote;

  Future<String> uploadPhoto(XFile file) => _remote.uploadPhoto(file);
}
