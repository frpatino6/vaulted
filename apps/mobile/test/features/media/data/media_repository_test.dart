import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/media/data/media_remote_data_source.dart';
import 'package:vaulted/features/media/data/media_repository.dart';

class MockMediaRemoteDataSource extends Mock implements MediaRemoteDataSource {}

void main() {
  late MockMediaRemoteDataSource mockRemote;
  late MediaRepository repository;

  setUp(() {
    mockRemote = MockMediaRemoteDataSource();
    repository = MediaRepository(mockRemote);
  });

  test('delegates uploadPhoto', () async {
    final file = XFile('/tmp/a.jpg');
    when(() => mockRemote.uploadPhoto(file)).thenAnswer((_) async => 'url');

    expect(await repository.uploadPhoto(file), 'url');
    verify(() => mockRemote.uploadPhoto(file)).called(1);
  });
}
