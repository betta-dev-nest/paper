import 'package:mocktail/mocktail.dart';
import 'package:paper/src/interfaces/unit.dart';
import 'package:paper/src/protocols.dart';
import 'package:test/test.dart';

class MockUnit extends Mock implements Unit {}

class MockUnitContext extends Mock implements UnitContext {}

class MockPaperReporter extends Mock implements PaperListener {}

class MockScript extends Mock
    implements Script<Paper, UnitState<Paper, Unit<Paper>>> {}

class MockState extends Mock implements UnitState {}

class MockUnique extends Mock implements Unique {}

class ConcreteUnitAgent extends UnitAgent {}

class ConcreteState extends UnitState {}

class TestUnitWithMockState extends Unit {
  TestUnitWithMockState(super.agent, {required super.listener});

  @override
  Script<Paper, UnitState<Paper, Unit<Paper>>> createScript() {
    return MockScript();
  }

  @override
  UnitState<Paper, Unit<Paper>> createState() {
    return MockState();
  }
}

class TestUnitWithConcreteState extends Unit {
  TestUnitWithConcreteState(super.agent, {required super.listener});

  @override
  Script<Paper, UnitState<Paper, Unit<Paper>>> createScript() {
    return MockScript();
  }

  @override
  UnitState<Paper, Unit<Paper>> createState() {
    return ConcreteState();
  }
}

void main() {
  final agentTestSupporter = AgentTestingSupporter();
  group('[UnitWidget] testing', () {
    test('Should create Unit with correct members', () {
      final reporter = MockPaperReporter();
      final agent = ConcreteUnitAgent();

      final unit = TestUnitWithMockState(agent, listener: reporter);

      expect(agentTestSupporter.getReporter(agent), reporter);
      expect(unit.createState(), isA<MockState>());
      expect(unit.createScript(), isA<MockScript>());
    });
  });

  group('[UnitContext] testing', () {
    test('[state], [script], [key], [lifeState] testing', () {
      final unit = MockUnit();
      final script = MockScript();
      final state = MockState();
      final agent = ConcreteUnitAgent();

      when(() => unit.createScript()).thenReturn(script);
      when(() => unit.createState()).thenReturn(state);
      when(() => unit.agent).thenReturn(agent);
      when(() => unit.key).thenReturn(agent);

      final context = UnitContext(unit);

      expect(context.state, state);
      expect(context.script, script);
      expect(context.key, agent);
      expect(context.lifeState, MemberLife.absence);

      context.lifeState = MemberLife.init;
      expect(context.lifeState, MemberLife.init);
    });

    test('[init] testing', () async {
      final unit = MockUnit();
      final script = MockScript();
      final state = ConcreteState();
      final agent = ConcreteUnitAgent();

      when(() => unit.createScript()).thenReturn(script);
      when(() => unit.createState()).thenReturn(state);
      when(() => unit.agent).thenReturn(agent);
      when(() => unit.key).thenReturn(agent);

      final context = UnitContext(unit);

      await context.init();

      
    });
  });
}
