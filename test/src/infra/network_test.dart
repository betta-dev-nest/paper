import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:paper/src/infra/network.dart';
import 'package:paper/src/infra/tree_layout_registry.dart';
import 'package:paper/src/protocols.dart';
import 'package:test/test.dart';

class MockMemberBuilder extends Mock implements MemberBuilder {}

class MockMember extends Mock implements Member {}

class MockTreeLayoutRegistry extends Mock
    implements TreeLayoutRegistry<Unique, Member> {}

class MockUnique extends Mock implements Unique {}

class MockEvent extends Mock implements Event {}

class MockFuture<T> extends Mock implements Future<T> {}

class MockMember1 extends Mock implements Member {}

class MockMember2 extends Mock implements Member {}

class MockMember3 extends Mock implements Member {}

class MockMember4 extends Mock implements Member {}

class MockEvent1 extends Mock implements Event {}

class MockEvent2 extends Mock implements Event {}

class MockEvent3 extends Mock implements Event {}

class MockEvent4 extends Mock implements Event {}

void main() {
  late MemberBuilder builder;
  late Member member;
  late Unique key;
  late Event event;
  late TreeLayoutRegistry<Unique, Member> registry;

  setUp(() {
    builder = MockMemberBuilder();
    member = MockMember();
    key = MockUnique();
    event = MockEvent();
    registry = MockTreeLayoutRegistry();
  });

  test('[buildRootMember] testing', () async {
    when(() => registry.saveRoot(key, member)).thenReturn(null);
    when(() => builder.key).thenReturn(key);
    when(() => builder.createMember()).thenReturn(member);

    final network = EventOperatorNetwork(memberRegistry: registry);

    await network.buildRootMember(builder);

    verify(() => registry.saveRoot(key, member)).called(1);
    verify(() => member.operator = network).called(1);
    verify(() => member.init()).called(1);

    // After the root object has been registered, call EventOperatorNetwork.buildRootMember will do nothing.
    await network.buildRootMember(builder);

    verifyNever(() => registry.saveRoot(key, member));
    verifyNever(() => member.operator = network);
    verifyNever(() => member.init());
  });

  group('[processRootMember] testing', () {
    test(
        'Should process member with event with Member.handle when the root is available',
        () async {
      when(() => registry.root).thenReturn(member);
      when(() => member.handle(event, null)).thenAnswer((_) async {});

      final network = EventOperatorNetwork(memberRegistry: registry);

      await network.processRootMember(event);

      verify(() => member.handle(event, null)).called(1);
    });

    test('Should throw asserting error when the root has not been registered',
        () async {
      when(() => registry.root).thenReturn(null);

      final network = EventOperatorNetwork(memberRegistry: registry);

      expect(
        () => network.processRootMember(event),
        throwsA(isA<HasNotBuiltRootMember>()),
      );
    });
  });

  test('[buildMemberSync] testing', () async {
    final source = MockMember();

    when(() => builder.key).thenReturn(key);
    when(() => builder.createMember()).thenReturn(member);
    when(() => registry.save(key, member, under: source)).thenReturn(null);

    final network = EventOperatorNetwork(memberRegistry: registry);

    network.buildMemberSync(source, builder);

    verify(() => registry.save(key, member, under: source)).called(1);
    verify(() => member.operator = network).called(1);
    verify(() => member.init()).called(1);
    verify(() => member.lifeState = MemberLife.init).called(1);
  });

  test('[buildMemberAsync] testing', () async {
    final source = MockMember();

    when(() => builder.key).thenReturn(key);
    when(() => builder.createMember()).thenReturn(member);
    when(() => registry.save(key, member, under: source)).thenReturn(null);

    final network = EventOperatorNetwork(memberRegistry: registry);

    await network.buildMemberAsync(source, builder);

    verify(() => registry.save(key, member, under: source)).called(1);
    verify(() => member.operator = network).called(1);
    verify(() => member.init()).called(1);
    verify(() => member.lifeState = MemberLife.initializing).called(1);
    verify(() => member.lifeState = MemberLife.init).called(1);
  });

  test('[disposeMember] testing', () async {
    final network = EventOperatorNetwork(memberRegistry: registry);

    when(
      () => registry.removeByKey(
        key,
        onObjectRemoved: network.requestMemberDispose,
      ),
    ).thenReturn(null);

    network.disposeMember(key);

    verify(
      () => registry.removeByKey(
        key,
        onObjectRemoved: network.requestMemberDispose,
      ),
    ).called(1);
  });

  test('[requestMemberDispose] testing', () async {
    when(() => member.dispose()).thenReturn(null);

    final network = EventOperatorNetwork(memberRegistry: registry);

    network.requestMemberDispose(member);

    verify(() => member.dispose()).called(1);
    verify(() => member.lifeState = MemberLife.absence).called(1);
  });

  // TODO: apply test logic
  test('[notifyEvent] testing', () async {
    final network = EventOperatorNetwork(memberRegistry: registry);

    network.requestMemberDispose(member);

    verify(() => member.dispose()).called(1);
    verify(() => member.lifeState = MemberLife.absence).called(1);
  });

  group('[EventLine] testing', () {
    final member1 = MockMember1();
    final member2 = MockMember2();
    final member3 = MockMember3();
    final member4 = MockMember4();

    final event1 = MockEvent1();
    final event2 = MockEvent2();
    final event3 = MockEvent3();
    final event4 = MockEvent4();

    final tree = <Member>[member1, member2, member3, member4];

    Member? getParent(Member member) {
      final index = tree.indexOf(member);
      if (index == 0) return null;

      return tree[index - 1];
    }

    test(
        'Should trigger request each member to process event when start the line',
        () async {
      final line = EventLine(getParent);

      final completer4 = Completer<void>();
      when(() => member4.handle(event4, 1)).thenAnswer(
        (_) => Future(() => completer4.complete()),
      );

      final key4 = MockUnique();
      final completer3 = Completer<void>();
      when(() => member4.key).thenReturn(key4);
      when(() => member3.handleReport(event4, key4)).thenAnswer(
        (_) => Future(() {
          completer3.complete();
          return event3;
        }),
      );

      final key3 = MockUnique();
      final completer2 = Completer<void>();
      when(() => member3.key).thenReturn(key3);
      when(() => member2.handleReport(event3, key3)).thenAnswer(
        (_) => Future(() {
          completer2.complete();
          return event2;
        }),
      );

      final key2 = MockUnique();
      final completer1 = Completer<void>();
      when(() => member2.key).thenReturn(key2);
      when(() => member1.handleReport(event2, key2)).thenAnswer(
        (_) => Future(() {
          completer1.complete();
          return event1;
        }),
      );

      line.start(member4, event4, 1);

      await completer4.future;

      verify(() => member4.handle(event4, 1)).called(1);
      verifyNever(() => member3.handleReport(event4, key4));
      verifyNever(() => member2.handleReport(event3, key3));
      verifyNever(() => member1.handleReport(event2, key2));

      await completer3.future;

      verify(() => member3.handleReport(event4, key4)).called(1);
      verifyNever(() => member2.handleReport(event3, key3));
      verifyNever(() => member1.handleReport(event2, key2));

      await completer2.future;

      verify(() => member2.handleReport(event3, key3)).called(1);
      verifyNever(() => member1.handleReport(event2, key2));

      await completer1.future;

      verify(() => member1.handleReport(event2, key2)).called(1);
    });

    test(
        'Should stop the line at the member which handleReport and return null when start the line',
        () async {
      final line = EventLine(getParent);

      final completer4 = Completer<void>();
      when(() => member4.handle(event4, 1)).thenAnswer(
        (_) => Future(() => completer4.complete()),
      );

      final key4 = MockUnique();
      final completer3 = Completer<void>();
      when(() => member4.key).thenReturn(key4);
      when(() => member3.handleReport(event4, key4)).thenAnswer(
        (_) => Future(() {
          completer3.complete();
          return event3;
        }),
      );

      final key3 = MockUnique();
      final completer2 = Completer<void>();
      when(() => member3.key).thenReturn(key3);
      when(() => member2.handleReport(event3, key3)).thenAnswer(
        (_) => Future(() {
          completer2.complete();
          return event2;
        }),
      );

      final key2 = MockUnique();
      final completer1 = Completer<void>();
      when(() => member2.key).thenReturn(key2);
      when(() => member1.handleReport(event2, key2)).thenAnswer(
        (_) => Future(() {
          completer1.complete();
          return event1;
        }),
      );

      line.start(member4, event4, 1);

      await completer4.future;

      verify(() => member4.handle(event4, 1)).called(1);
      verifyNever(() => member3.handleReport(event4, key4));
      verifyNever(() => member2.handleReport(event3, key3));
      verifyNever(() => member1.handleReport(event2, key2));

      await completer3.future;

      verify(() => member3.handleReport(event4, key4)).called(1);
      verifyNever(() => member2.handleReport(event3, key3));
      verifyNever(() => member1.handleReport(event2, key2));

      await completer2.future;

      verify(() => member2.handleReport(event3, key3)).called(1);
      verifyNever(() => member1.handleReport(event2, key2));

      await completer1.future;

      verify(() => member1.handleReport(event2, key2)).called(1);
    });
  });
}
