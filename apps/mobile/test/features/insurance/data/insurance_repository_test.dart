import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_remote_data_source.dart';
import 'package:vaulted/features/insurance/data/insurance_repository.dart';
import 'package:vaulted/features/insurance/data/models/insurance_policy_model.dart';

class MockInsuranceRemoteDataSource extends Mock
    implements InsuranceRemoteDataSource {}

InsurancePolicyModel _fakePolicy(String id) => InsurancePolicyModel(
      id: id,
      tenantId: 't',
      provider: 'P',
      policyNumber: 'N',
      coverageType: 'all-risk',
      totalCoverageAmount: 1,
      startDate: '2025-01-01',
      expiresAt: '2026-01-01',
    );

void main() {
  late MockInsuranceRemoteDataSource mockRemote;
  late InsuranceRepository repository;

  setUp(() {
    mockRemote = MockInsuranceRemoteDataSource();
    repository = InsuranceRepository(mockRemote);
  });

  test('getPolicies delegates', () async {
    final list = [_fakePolicy('1')];
    when(() => mockRemote.getPolicies()).thenAnswer((_) async => list);

    expect(await repository.getPolicies(), list);
    verify(() => mockRemote.getPolicies()).called(1);
  });

  test('createPolicy builds body and omits empty notes', () async {
    final created = _fakePolicy('new');
    when(
      () => mockRemote.createPolicy(any()),
    ).thenAnswer((inv) async {
      final map = inv.positionalArguments.first as Map<String, dynamic>;
      expect(map.containsKey('notes'), isFalse);
      return created;
    });

    final result = await repository.createPolicy(
      provider: 'Acme',
      policyNumber: '1',
      coverageType: 'all-risk',
      totalCoverageAmount: 100,
      startDate: '2025-01-01',
      expiresAt: '2026-01-01',
      notes: '',
    );

    expect(result, created);
    verify(() => mockRemote.createPolicy(any())).called(1);
  });

  test('createPolicy includes premium and notes when set', () async {
    when(() => mockRemote.createPolicy(any())).thenAnswer((_) async => _fakePolicy('x'));

    await repository.createPolicy(
      provider: 'Acme',
      policyNumber: '1',
      coverageType: 'all-risk',
      totalCoverageAmount: 100,
      premium: 9.99,
      startDate: '2025-01-01',
      expiresAt: '2026-01-01',
      notes: 'Umbrella',
    );

    final map = verify(() => mockRemote.createPolicy(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(map['premium'], 9.99);
    expect(map['notes'], 'Umbrella');
  });

  test('updatePolicy sends only provided fields', () async {
    when(() => mockRemote.updatePolicy('id', any()))
        .thenAnswer((_) async => _fakePolicy('id'));

    await repository.updatePolicy(
      'id',
      provider: 'NewCo',
      notes: null,
    );

    final map = verify(() => mockRemote.updatePolicy('id', captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(map, {'provider': 'NewCo'});
  });

  test('attachItem forwards map with defaults', () async {
    when(() => mockRemote.attachItem('p', any()))
        .thenAnswer((_) async => _fakePolicy('p'));

    await repository.attachItem(
      'p',
      itemId: 'i',
      coveredValue: 250,
    );

    verify(
      () => mockRemote.attachItem('p', {
        'itemId': 'i',
        'coveredValue': 250.0,
        'currency': 'USD',
      }),
    ).called(1);
  });

  test('detachItem delegates', () async {
    when(() => mockRemote.detachItem('p', 'i'))
        .thenAnswer((_) async => _fakePolicy('p'));

    await repository.detachItem('p', 'i');

    verify(() => mockRemote.detachItem('p', 'i')).called(1);
  });

  test('getCoverageGaps delegates', () async {
    final report = const CoverageGapReportModel(
      uncovered: [],
      underinsured: [],
      totalUncoveredValue: 100,
      totalUnderinsuredGap: 25,
    );
    when(() => mockRemote.getCoverageGaps('p')).thenAnswer((_) async => report);

    expect(await repository.getCoverageGaps('p'), report);
  });
}
