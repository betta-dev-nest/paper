import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper/src/interfaces/unit.dart';
import 'package:paper/src/protocols.dart';
import 'package:test/test.dart';

class MockOperator extends Mock implements MemberOperating {}

class MockPaper extends Mock implements Paper {}

class MockKey extends Mock implements Unique {}

class MockScript extends Mock implements Script<MockPaper, MockState> {}

class MockUnit extends Mock implements Unit {}

class MockUnitWidget extends Mock implements UnitWidget {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class MockWidgetUnit extends Mock implements WidgetUnit {}

class MockAgent extends Mock implements Agent {}

class MockUnitAgent extends Mock implements UnitAgent {}

class MockWidgetAgent extends Mock implements WidgetAgent {}

class MockState extends Mock {}

class MockCause extends Mock {}

class MockNote extends Mock implements ImplNote<int> {}

class MockCompleter extends Mock implements Completer<void> {}

class MockFuture<T> extends Mock implements Future<T> {}

class ConcreteAgent extends Agent {}

class ConcreteUnitAgent extends UnitAgent {}

class ConcreteUnitWidgetAgent extends WidgetAgent {}

T? mockSourceVerifier<T>(T o) {
  return o != int ? o : null;
}

class TestBaseContext extends BaseContext<MockState> {
  @override
  MemberLife lifeState = MemberLife.init;

  TestBaseContext({required super.state, required super.script});

  @override
  Unique get key => MockKey();
}

void main() {
  setUp(() {
    registerFallbackValue(mockSourceVerifier);
  });

  test('[init] testing', () async {
    /// The method's body is empty.
    /// The unit test for the method shall be added if the body is populated
  });

  test('[dispose] testing', () async {
    final context = TestBaseContext(state: MockState(), script: MockScript());
    context.operator = MockOperator();

    context.dispose();

    expect(
      () => context.operator,
      throwsA(
        isA<ContextError>()
            .having(
              (e) => e.member,
              'member',
              'listener',
            )
            .having(
              (e) => e.message,
              'message',
              'The listener has not been defined',
            ),
      ),
    );
    expect(context.selfCaller.isDispose(), true);
  });

  group('[handle] testing', () {
    test('should handle paper that has been registered in the script',
        () async {
      final script = MockScript();
      final paper = MockPaper();
      final state = MockState();
      final cause = MockCause();

      final context = TestBaseContext(state: state, script: script);

      when(() => script.handle(paper, state, any())).thenAnswer((_) {});

      await context.handle(paper, cause);

      verify(
        () => script.handle(
          paper,
          state,
          any(
            that: isA<T? Function<T>(T)>()
                .having((e) => e.call(cause), 'call', null),
          ),
        ),
      ).called(1);
      verifyNever(
        () => script.handle(
          paper,
          state,
          any(
            that: isA<T? Function<T>(T)>()
                .having((e) => e.call(cause), 'call', cause),
          ),
        ),
      );
    });

    test(
        'should clear the notes and register any pending notes that has been register during the process of paper',
        () async {
      final script = MockScript();
      final paper = MockPaper();
      final state = MockState();
      final cause = MockCause();
      final note1 = MockNote();
      final note2 = MockNote();
      final note3 = MockNote();

      final context = TestBaseContext(state: state, script: script);

      context.notes.addAll([note1, note2]);
      context.pendingNotes = HashSet.from([note3]);

      when(() => script.handle(paper, state, any())).thenAnswer((_) {});
      when(() => note1.keepWhen).thenReturn(
        (paper) => paper.runtimeType == MockPaper,
      );
      when(() => note1.cachedValue).thenReturn(1);
      when(() => note2.keepWhen).thenReturn(
        (paper) => paper.runtimeType != MockPaper,
      );
      when(() => note2.cachedValue).thenReturn(2);

      await context.handle(paper, cause);

      verify(() => note1.keepWhen).called(1);
      verifyNever(() => note1.cachedValue = null);
      verify(() => note2.keepWhen).called(1);
      verify(() => note2.cachedValue = null).called(1);
      expect(context.notes.contains(note1), true);
      expect(context.notes.contains(note2), false);
      expect(context.notes.contains(note3), true);
      expect(context.pendingNotes, null);
    });
  });

  test('[handleReport] testing', () async {
    final script = MockScript();
    final state = MockState();
    final childPaper = MockPaper();
    final parentPaper = MockPaper();
    final agent = ConcreteAgent();

    AgentTestingSupporter().setReporterToAgent(
      agent,
      PaperListener(
        (r) => r.on<MockPaper>((paper) => parentPaper),
      ),
    );

    when(() => script.handle(parentPaper, state, any())).thenAnswer((_) {});

    final context = TestBaseContext(state: state, script: script);

    final outputPaper = await context.handleReport(childPaper, agent);

    expect(outputPaper, parentPaper);

    verify(() => script.handle(
          parentPaper,
          state,
          any(
            that: isA<T? Function<T>(T)>()
                .having((e) => e.call(agent), 'call', null),
          ),
        )).called(1);
    verifyNever(() => script.handle(
          parentPaper,
          state,
          any(
            that: isA<T? Function<T>(T)>()
                .having((e) => e.call(agent), 'call', agent),
          ),
        ));
  });

  test('[report] testing', () async {
    final script = MockScript();
    final state = MockState();
    final paper = MockPaper();

    when(() => script.report(MockPaper, state)).thenAnswer((_) async => paper);

    final context = TestBaseContext(state: state, script: script);

    final outputPaper = await context.report<MockPaper>();

    verify(() => script.report(MockPaper, state)).called(1);

    expect(outputPaper, paper);
  });

  test('[observeAgent] testing', () {
    final script = MockScript();
    final state = MockState();

    final agent = ConcreteAgent();

    expect(AgentTestingSupporter().getListener(agent), null);

    final context = TestBaseContext(state: state, script: script);

    context.observeAgent(agent);

    final parent = AgentTestingSupporter().getListener(agent);

    expect(
      parent,
      isA<ContextContainer>().having((e) => e(), 'call', context),
    );
  });

  test('[initUnit] testing', () async {
    final script = MockScript();
    final state = MockState();
    final agent = ConcreteUnitAgent();
    final unit = MockUnit();
    final operator = MockOperator();

    final context = TestBaseContext(state: state, script: script);

    when(() => operator.buildMemberAsync(context, unit))
        .thenAnswer((_) async {});

    context.operator = operator;
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.absence,
    );

    await context.initUnit(agent, unit);

    verify(() => operator.buildMemberAsync(context, unit)).called(1);

    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.init,
    );

    await context.initUnit(agent, unit);

    verifyNever(() => operator.buildMemberAsync(context, unit));
  });

  test('[initUnit] testing', () async {
    final script = MockScript();
    final state = MockState();
    final agent = ConcreteUnitAgent();
    final unit = MockUnit();
    final operator = MockOperator();
    final completer = MockCompleter();

    final context = TestBaseContext(state: state, script: script);

    when(() => operator.buildMemberAsync(context, unit))
        .thenAnswer((_) async {});
    when(() => completer.complete()).thenAnswer((_) async {});

    context.operator = operator;
    context.awaitingToProcessAfterInitAgents[agent] = completer;
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.absence,
    );

    await context.initUnit(agent, unit);

    verify(() => operator.buildMemberAsync(context, unit)).called(1);
    verifyNever(() => completer.complete());

    await Future(() {});

    verify(() => completer.complete()).called(1);

    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.init,
    );

    await context.initUnit(agent, unit);

    verifyNever(() => operator.buildMemberAsync(context, unit));
  });

  test('[constructRootWidget] testing', () async {
    final script = MockScript();
    final state = MockState();
    final agent = ConcreteUnitWidgetAgent();
    final widget = MockUnitWidget();
    final operator = MockOperator();

    final context = TestBaseContext(state: state, script: script);

    when(() => widget.agent).thenReturn(agent);
    when(() => operator.buildRootWidget(widget)).thenAnswer((_) async {});

    context.operator = operator;
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.absence,
    );

    await context.constructRootWidget(widget);

    verify(() => operator.buildRootWidget(widget)).called(1);
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.init,
    );

    await context.constructRootWidget(widget);

    verifyNever(() => operator.buildRootWidget(widget));
  });

  test('[initWidgetUnit] testing', () async {
    final script = MockScript();
    final state = MockState();
    final agent = ConcreteUnitWidgetAgent();
    final unit = MockWidgetUnit();
    final operator = MockOperator();

    final context = TestBaseContext(state: state, script: script);

    when(() => operator.buildMemberSync(context, unit)).thenReturn(null);

    context.operator = operator;
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.absence,
    );

    context.initWidgetUnit(agent, unit);

    verify(() => operator.buildMemberSync(context, unit)).called(1);

    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.init,
    );

    context.initWidgetUnit(agent, unit);

    verifyNever(() => operator.buildMemberSync(context, unit));
  });

  test('[disposeUnit] testing', () async {
    final script = MockScript();
    final state = MockState();
    final agent = ConcreteAgent();
    final operator = MockOperator();

    final unitContext = TestBaseContext(state: state, script: script);

    when(() => operator.disposeMember(agent)).thenReturn(null);

    unitContext.operator = operator;
    AgentTestingSupporter().setLifeStateToAgent(
      agent,
      MemberLife.init,
    );

    unitContext.disposeUnit(agent);

    verify(() => operator.disposeMember(agent)).called(1);
  });

  group('[command] testing', () {
    test(
        'should call operator to process the child context when state of agent is init',
        () async {
      final script = MockScript();
      final state = MockState();
      final agent = ConcreteAgent();
      final operator = MockOperator();
      final paper = MockPaper();

      final context = TestBaseContext(state: state, script: script);

      when(() => operator.processMember(context, agent, paper))
          .thenAnswer((_) async {});

      context.operator = operator;
      AgentTestingSupporter().setLifeStateToAgent(
        agent,
        MemberLife.init,
      );

      context.command(agent, paper);

      verify(() => operator.processMember(context, agent, paper)).called(1);
    });

    test(
        'should save agent and completer context when state of agent is initializing',
        () async {
      final script = MockScript();
      final state = MockState();
      final agent = ConcreteAgent();
      final operator = MockOperator();
      final paper = MockPaper();

      final context = TestBaseContext(state: state, script: script);

      when(() => operator.processMember(context, agent, paper))
          .thenAnswer((_) async {});

      context.operator = operator;
      AgentTestingSupporter().setLifeStateToAgent(
        agent,
        MemberLife.initializing,
      );

      context.command(agent, paper);

      verifyNever(() => operator.processMember(context, agent, paper));

      context.awaitingToProcessAfterInitAgents[agent]?.complete();
      await Future(() {});

      verify(() => operator.processMember(context, agent, paper)).called(1);
    });

    test(
        'should init unit agent and process paper when state of agent is absence',
        () async {
      final script = MockScript();
      final state = MockState();
      final agent = MockUnitAgent();
      final operator = MockOperator();
      final paper = MockPaper();

      final context = TestBaseContext(state: state, script: script);

      when(() => agent.isInit).thenReturn(false);
      when(() => agent.isInitializing).thenReturn(false);
      when(() => agent.isAbsence).thenReturn(true);
      when(() => agent.init()).thenAnswer((_) => Future(() {}));
      when(() => operator.processMember(context, agent, paper))
          .thenAnswer((_) async {});

      context.operator = operator;

      context.command(agent, paper);

      verify(() => agent.init()).called(1);
      verifyNever(() => operator.processMember(context, agent, paper));

      await Future(() {});

      verify(() => operator.processMember(context, agent, paper)).called(1);
    });

    test(
        'should init widget agent and process paper when state of agent is absence',
        () async {
      final script = MockScript();
      final state = MockState();
      final agent = MockWidgetAgent();
      final operator = MockOperator();
      final paper = MockPaper();

      final context = TestBaseContext(state: state, script: script);

      when(() => agent.isInit).thenReturn(false);
      when(() => agent.isInitializing).thenReturn(false);
      when(() => agent.isAbsence).thenReturn(true);
      when(() => agent.constructAsRoot()).thenAnswer((_) => Future(() {}));
      when(() => operator.processMember(context, agent, paper))
          .thenAnswer((_) async {});

      context.operator = operator;

      context.command(agent, paper);

      verify(() => agent.constructAsRoot()).called(1);
      verifyNever(() => operator.processMember(context, agent, paper));

      await Future(() {});

      verify(() => operator.processMember(context, agent, paper)).called(1);
    });
  });

  group('[requestReport] testing', () {
    final script = MockScript();
    final state = MockState();
    final operator = MockOperator();
    final paper = MockPaper();
    final agent = MockAgent();

    final context = TestBaseContext(state: state, script: script);

    context.operator = operator;

    test('Should return paper when the returned paper match the type',
        () async {
      when(() => operator.acquireEvent<Paper>(agent)).thenAnswer(
        (_) => Future.value(paper),
      );

      final report = await context.requestReport(agent);

      expect(report, paper);
    });

    test('Should return null when the returned paper does not match the type',
        () async {
      when(() => operator.acquireEvent<Paper>(agent)).thenAnswer(
        (_) => Future.value(null),
      );

      final report = await context.requestReport(agent);

      expect(report, null);
    });
  });

  test('[process] testing', () async {
    final script = MockScript();
    final state = MockState();
    final operator = MockOperator();
    final paper = MockPaper();

    final context = TestBaseContext(state: state, script: script);

    context.operator = operator;

    when(() => operator.notifyEvent(context, paper, 1)).thenReturn(null);

    context.process(paper, 1);

    verify(() => operator.notifyEvent(context, paper, 1)).called(1);
  });

  test('[takeNote] testing', () {
    final script = MockScript();
    final state = MockState();
    final note = MockNote();

    final context = TestBaseContext(state: state, script: script);

    context.takeNote(note);

    expect(context.pendingNotes?.first, note);
  });

  test('[eraseNote] testing', () {
    final script = MockScript();
    final state = MockState();
    final note = MockNote();
    final paper = MockPaper();

    final context = TestBaseContext(state: state, script: script);

    when(() => note.keepWhen).thenReturn((_) => true);

    context.notes.add(note);

    context.eraseNote(paper);

    expect(context.notes.contains(note), true);

    when(() => note.keepWhen).thenReturn((_) => false);

    context.eraseNote(paper);

    expect(context.notes.contains(note), false);
  });
}
