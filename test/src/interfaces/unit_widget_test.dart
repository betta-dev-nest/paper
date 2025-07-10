import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper/src/interfaces/unit.dart';

class MockWidgetUnit extends Mock implements WidgetAgent {}

class MockWidgetUnitContext extends Mock implements WidgetUnitContext {}

class MockUnitWidget extends Mock implements UnitWidget {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class MockScript extends Mock
    implements Script<Paper, UnitWidgetState<Paper, UnitWidget<Paper>>> {}

class MockUnitWidgetState extends Mock implements UnitWidgetState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class MockPaperReporter extends Mock implements PaperListener {}

class MockWidgetAgent extends Mock implements WidgetAgent {}

class MockContextDelegating extends Mock implements ContextDelegating {}

class ConcreteUnitWidgetState extends UnitWidgetState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}

class ConcreteWidgetAgent extends WidgetAgent {}

// ignore: must_be_immutable
class TestUnitWidget extends UnitWidget<Paper> {
  TestUnitWidget(super.parent, {required super.agent, required super.listener});

  @override
  Script<Paper, UnitWidgetState<Paper, UnitWidget<Paper>>> createScript() {
    return MockScript();
  }

  @override
  UnitWidgetState<Paper, UnitWidget<Paper>> createState() {
    return state ?? ConcreteUnitWidgetState();
  }

  ConcreteUnitWidgetState? state;
}

void main() {
  final stateTestSupporter = UnitWidgetStateTestingSupporter();
  final agentTestSupporter = AgentTestingSupporter();

  setUp(() {
    registerFallbackValue(
      WidgetUnit(MockWidgetAgent(), MockWidgetUnitContext()),
    );
  });

  group('[WidgetUnit] testing', () {
    test('Should create WidgetUnit with correct member', () {
      final agent = MockWidgetAgent();
      final context = MockWidgetUnitContext();

      final unit = WidgetUnit(agent, context);

      expect(unit.key, agent);
      expect(unit.context, context);
      expect(unit.createMember(), context);
    });
  });

  group('[UnitWidget] testing', () {
    test('Should create UnitWidget with correct members', () {
      final context = MockWidgetUnitContext();
      final reporter = MockPaperReporter();
      final parent = ConcreteUnitWidgetState();
      final agent = ConcreteWidgetAgent();

      stateTestSupporter.setContext(context, parent);

      final unit = TestUnitWidget(parent, agent: agent, listener: reporter);

      when(() => context.observeAgent(agent)).thenReturn(null);

      expect(stateTestSupporter.getUnitContext(parent), context);
      verify(() => context.observeAgent(agent)).called(1);
      expect(agentTestSupporter.getReporter(agent), reporter);
      expect(unit.createState(), isA<ConcreteUnitWidgetState>());
      expect(unit.createScript(), isA<MockScript>());
    });
  });

  group('[UnitWidgetState] testing', () {
    testWidgets('[initState] testing', (WidgetTester tester) async {
      final parentContext = MockWidgetUnitContext();
      final reporter = MockPaperReporter();
      final parent = ConcreteUnitWidgetState();
      final agent = ConcreteWidgetAgent();

      final state = ConcreteUnitWidgetState();

      stateTestSupporter.setContext(parentContext, parent);

      final unit = TestUnitWidget(parent, agent: agent, listener: reporter);

      unit.state = state;

      agentTestSupporter.setListenerToAgent(agent, parentContext);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: unit)));

      final context = stateTestSupporter.getUnitContext(state);

      expect(stateTestSupporter.getAgent(state), agent);
      expect(context?.key, agent);
      expect(context?.state, state);
      expect(context?.script, isA<MockScript>());
      verify(
        () => parentContext.initWidgetUnit(
          agent,
          any(
            that: isA<WidgetUnit>()
                .having(
                  (e) => e.key,
                  'key',
                  agent,
                )
                .having(
                  (e) => e.context,
                  'context',
                  context,
                ),
          ),
        ),
      );
    });

    testWidgets('[dispose] testing', (WidgetTester tester) async {
      final parentContext = MockWidgetUnitContext();
      final reporter = MockPaperReporter();
      final parent = ConcreteUnitWidgetState();
      final agent = ConcreteWidgetAgent();
      final state = ConcreteUnitWidgetState();

      stateTestSupporter.setContext(parentContext, parent);

      final unit = TestUnitWidget(parent, agent: agent, listener: reporter);

      unit.state = state;

      agentTestSupporter.setListenerToAgent(agent, parentContext);

      when(() => parentContext.initWidgetUnit(agent, any()));

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: unit)));

      final context = stateTestSupporter.getUnitContext(state);

      expect(stateTestSupporter.getAgent(state), agent);
      expect(context?.key, agent);
      expect(context?.state, state);
      expect(context?.script, isA<MockScript>());
      verify(
        () => parentContext.initWidgetUnit(
          agent,
          any(
            that: isA<WidgetUnit>()
                .having(
                  (e) => e.key,
                  'key',
                  agent,
                )
                .having(
                  (e) => e.context,
                  'context',
                  context,
                ),
          ),
        ),
      );

      await tester.pumpWidget(Container());

      verify(() => parentContext.disposeUnit(agent)).called(1);
      expect(stateTestSupporter.getUnitContext(state), null);
      expect(stateTestSupporter.getAgent(state), null);
    });
  });
}
