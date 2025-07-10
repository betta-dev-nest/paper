part of 'unit.dart';

/// The configurations for the paper framework to build a unit context and attach it to the tree
abstract class Unit<P extends Paper> extends MemberBuilder {
  final UnitAgent<P> agent;

  Unit(this.agent, {required PaperListener<P, Paper>? listener}) {
    agent._logReporter(listener);
  }

  @override
  Unique get key => agent;

  UnitState<P, Unit<P>> createState();

  Script<P, UnitState<P, Unit<P>>> createScript();

  @override
  UnitContext createMember() => UnitContext<P>(this);
}

@optionalTypeArgs
abstract class UnitState<P extends Paper, U extends Unit<P>>
    implements NoteKeeping {
  @mustCallSuper
  Future<void> initState(U unit) async {}

  Set<Agent>? register() => null;

  @mustCallSuper
  void dispose() {}

  void report(Paper paper, {dynamic from}) {
    _listener?.process(paper, from);
  }

  PaperListener<IPaper, P> reporter<IPaper extends Paper>(
    void Function(PaperListener<IPaper, P> reporter) reporter,
  ) =>
      PaperListener<IPaper, P>(reporter);

  UnitWidgetState get widgetState {
    assert(_listener != null);
    return UnitWidgetState.bridge(_listener!);
  }

  ContextContainer? _listener;

  void _addListener(ContextContainer listener) => _listener = listener;

  @override
  void takeNote(Note note) {
    _listener?.takeNote(note);
  }

  @override
  String toString() => runtimeType.toString();
}

class UnitContext<P extends Paper> extends BaseContext<UnitState> {
  final Unit unit;

  UnitContext(this.unit)
      : super(
          state: unit.createState(),
          script: unit.createScript(),
        );

  @override
  Unique get key => unit.key;

  @override
  MemberLife get lifeState => unit.agent._lifeState;

  @override
  set lifeState(MemberLife state) {
    unit.agent._lifeState = state;
  }

  @override
  Future<void> init() async {
    super.init();
    state._addListener(selfCaller);
    await state.initState(unit);

    final agents = state.register();
    if (agents != null) {
      await Future.forEach(
        agents,
        (agent) => Future(() => agent._addListener(selfCaller)),
      );
    }
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  String toString() => 'UnitContext: state: ${state.toString()}';
}

@visibleForTesting
class UnitTestingSupporter {
  void setContext(WidgetUnitContext context, UnitWidgetState state) {
    state._unitContext = context;
  }

  WidgetUnitContext? getUnitContext(UnitWidgetState state) {
    return state._unitContext;
  }

  WidgetAgent? getAgent(UnitWidgetState state) {
    return state._agent;
  }
}
