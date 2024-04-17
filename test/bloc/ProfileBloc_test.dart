import 'package:arrange_windows/IsarDB.dart';
import 'package:arrange_windows/bloc/ProfileBloc.dart';
import 'package:arrange_windows/models/AppInfo.dart';
import 'package:arrange_windows/models/Profile.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';

import '../testUtils.dart';
import '../testUtils.mocks.dart';

main() {
  final mockIsar = MockIsar();
  IsarDB.testInstance(mockIsar);
  late MockIsarCollection<Profile> mockProfileCollection;
  late MockQuery<Profile> mockQuery;
  late Profile profile;

  setUp(() {
    reset(mockIsar);
    when(mockIsar.isOpen).thenReturn(true);
    mockProfileCollection = MockIsarCollection<Profile>();
    when(mockIsar.profiles).thenReturn(mockProfileCollection);
    final mockQueryBuilder =
        MockQueryBuilder<Profile, Profile, QWhere>(mockProfileCollection);
    when(mockProfileCollection.where()).thenReturn(mockQueryBuilder);
    mockQuery = MockQuery<Profile>();
    when(mockProfileCollection.buildQuery(
      whereClauses: anyNamed('whereClauses'),
      whereDistinct: anyNamed('whereDistinct'),
      whereSort: anyNamed('whereSort'),
      filter: anyNamed('filter'),
      sortBy: anyNamed('sortBy'),
      distinctBy: anyNamed('distinctBy'),
      offset: anyNamed('offset'),
      limit: anyNamed('limit'),
      property: anyNamed('property'),
    )).thenReturn(mockQuery);
    profile = Profile(id: 1, name: 'test', apps: [AppInfo()]);
  });

  blocTest('load profiles when initializing',
      setUp: () {
        when(mockQuery.findAll())
            .thenAnswer((realInvocation) => Future.value([profile]));
      },
      build: () => ProfileBloc(),
      verify: (bloc) {
        verify(mockQuery.findAll()).called(1);
        expect(bloc.state.profiles, [profile]);
      });

  blocTest(
    'save profile must call isar to persist',
    setUp: () {
      when(mockIsar.writeTxn<Null>(any)).thenAnswer((_) => Future.value(null));
      when(mockProfileCollection.put(any)).thenAnswer((_) => Future.value(1));
      // this is because after saving, the app reload all profiles.
      when(mockQuery.findAll())
          .thenAnswer((realInvocation) => Future.value([profile]));
    },
    build: () => ProfileBloc(),
    act: (bloc) => bloc.add(RequestSaveProfile(profile)),
    verify: (bloc) async {
      final txnCall = verify(mockIsar.writeTxn<Null>(captureAny)).captured;
      final func = txnCall[0] as Function;
      // simulate the inner call function
      await func.call();
      verify(mockProfileCollection.put(profile)).called(1);
    },
  );

  blocTest('clear startup profile must clear the flag',
      setUp: () {
        final mockFilterBuilder =
            MockQueryBuilder<Profile, Profile, QAfterFilterCondition>(
                mockProfileCollection);
        when(mockProfileCollection.filter()).thenReturn(mockFilterBuilder);
        when(mockQuery.findAll()).thenAnswer(
            (_) => Future.value([profile.copyWith(launchAtStartup: true)]));
        when(mockIsar.writeTxn<Null>(any))
            .thenAnswer((_) => Future.value(null));
        when(mockProfileCollection.putAll(any))
            .thenAnswer((_) => Future.value([1]));
      },
      build: () => ProfileBloc(),
      act: (bloc) => bloc.add(const RequestClearStartupProfile()),
      verify: (bloc) async {
        final txnCall = verify(mockIsar.writeTxn<Null>(captureAny)).captured;
        final func = txnCall[0] as Function;
        // simulate the inner call function
        await func.call();
        final putAll =
            verify(mockProfileCollection.putAll(captureAny)).captured;
        expect(putAll[0].length, 1);
        expect(
            (putAll[0] as List<Profile>)
                .any((element) => element.launchAtStartup),
            false);
      });

  blocTest('set start up profile must clear existing flag',
      setUp: () {
        final mockFilterBuilder =
            MockQueryBuilder<Profile, Profile, QAfterFilterCondition>(
                mockProfileCollection);
        when(mockProfileCollection.filter()).thenReturn(mockFilterBuilder);
        when(mockQuery.findAll()).thenAnswer((_) =>
            Future.value([profile.copyWith(launchAtStartup: true, id: 2)]));
        when(mockIsar.writeTxn<Null>(any))
            .thenAnswer((_) => Future.value(null));
        when(mockProfileCollection.putAll(any))
            .thenAnswer((_) => Future.value([1]));
        when(mockProfileCollection.put(any)).thenAnswer((_) => Future.value(1));
      },
      build: () => ProfileBloc(),
      act: (bloc) => bloc.add(RequestSetStartupProfile(profile)),
      verify: (bloc) async {
        final txnCall = verify(mockIsar.writeTxn<Null>(captureAny)).captured;
        final func = txnCall[0] as Function;
        // simulate the inner call function
        await func.call();
        final putAll =
            verify(mockProfileCollection.putAll(captureAny)).captured;
        expect(putAll[0].length, 1);
        expect(putAll[0].first.launchAtStartup, false);
        expect(putAll[0].first.id, 2);

        final put = verify(mockProfileCollection.put(captureAny)).captured;
        final launchProfile = put[0] as Profile;
        expect(launchProfile.id, 1);
        expect(launchProfile.launchAtStartup, true);
      });
}
