import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/dashboard/data/dashboard_remote_data_source.dart';
import 'package:vaulted/features/dashboard/data/dashboard_repository.dart';
import 'package:vaulted/features/dashboard/data/models/dashboard_model.dart';

class MockDashboardRemoteDataSource extends Mock
    implements DashboardRemoteDataSource {}

void main() {
  late MockDashboardRemoteDataSource mockRemote;
  late DashboardRepository repository;

  setUp(() {
    mockRemote = MockDashboardRemoteDataSource();
    repository = DashboardRepository(mockRemote);
  });

  test('delegates getDashboard to remote', () async {
    const model = DashboardModel(
      totalProperties: 2,
      totalItems: 10,
      itemsByStatus: {'active': 8},
      itemsByCategory: {'furniture': 3},
      totalValuation: 1000,
      currency: 'USD',
    );
    when(() => mockRemote.getDashboard()).thenAnswer((_) async => model);

    final result = await repository.getDashboard();

    expect(result, model);
    verify(() => mockRemote.getDashboard()).called(1);
  });

  test('propagates errors from remote', () async {
    when(() => mockRemote.getDashboard()).thenThrow(Exception('down'));

    expect(() => repository.getDashboard(), throwsA(isA<Exception>()));
  });
}
