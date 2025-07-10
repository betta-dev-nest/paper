part of 'unit.dart';

/// The unit is created during the phase of initialization of [UnitWidgetState]
/// Then unit then will be inject into the Paper framework to inflate and attache the context for the unit.
class WidgetUnit implements MemberBuilder {
  @override
  final WidgetAgent key;
  final WidgetUnitContext context;

  WidgetUnit(this.key, this.context);

  @override
  WidgetUnitContext createMember() => context;
}

/// The widget acts as a [StatefulWidget], and will create a configurations to build a unit for the Paper framework
abstract class UnitWidget<P extends Paper> extends StatefulWidget {
  final WidgetAgent<P> agent;

  /// During the initializing, the [parent] will observe [agent] by add state's context as listener to the [agent]
  /// and the [agent] will register [listener]
  UnitWidget(
    UnitWidgetState parent, {
    required this.agent,
    required PaperListener<P, Paper>? listener,
  }) : super(key: agent._key) {
    parent._observeAgent(agent);
    agent._logReporter(listener);
  }

  @protected
  @override
  @factory
  UnitWidgetState<P, UnitWidget<P>> createState();

  @protected
  @factory
  Script<P, UnitWidgetState<P, UnitWidget<P>>> createScript();
}

/// Acting very similar to [State] create by [StatefulWidget], [UnitWidgetState] is created by [UnitWidget],
/// inflated in widget tree of Flutter; and also attaches to a [UnitContext] in Paper framework.
abstract class UnitWidgetState<P extends Paper, T extends UnitWidget<P>>
    extends State<T> implements NoteKeeping {
  UnitWidgetState();

  /// Create a widget state that will be able to inject to Unit Widget as parent
  /// when that widget is a child of a unit.
  factory UnitWidgetState.bridge(ContextDelegating context) =>
      _WidgetStateBridge(context);

  /// The unit context that the widget is attached to
  WidgetUnitContext? _unitContext;

  /// The agent that represent the widget in the unit context tree
  WidgetAgent? _agent;

  /// Derived from [State]
  ///
  /// During initializing, to attach the widget to the Paper framework, following would be done:
  ///
  ///  * Save the [UnitWidget.agent] to [_agent]
  ///  * Create a [WidgetUnitContext] and save it to [_unitContext]
  ///  * Create a [WidgetUnit] and request to attach to Paper framework via [WidgetAgent._constructUnit].
  @override
  @mustCallSuper
  @protected
  void initState() {
    super.initState();

    _agent = widget.agent;
    _unitContext = WidgetUnitContext(
      key: widget.agent,
      state: this,
      script: widget.createScript(),
    );
    _agent!._constructUnit(WidgetUnit(_agent!, _unitContext!));
  }

  /// Derived from [State]
  ///
  /// The disposal is trigger be the Flutter framework.
  ///
  /// When disposing, the disposal from Paper framework will operate via [WidgetAgent._disposeUnit]
  /// After being disposed, the [_unitContext] and [_agent] will be removed from the state.
  @override
  @mustCallSuper
  @protected
  void dispose() {
    _agent!._disposeUnit();
    _unitContext = _agent = null;
    super.dispose();
  }

  Set<Agent>? register() => null;

  void report(Paper paper, {dynamic from}) {
    _listener?.process(paper, from);
  }

  /// Create reporter or listener to children unit widgets.
  /// [IPaper] is the type of the paper that is reported from the child.
  PaperListener<IPaper, P> reporter<IPaper extends Paper>(
    void Function(PaperListener<IPaper, P> reporter) reporter,
  ) =>
      PaperListener<IPaper, P>(reporter);

  ContextContainer? _listener;

  void _addListener(ContextContainer listener) => _listener = listener;

  void _observeAgent(WidgetAgent agent) {
    assert(
      _unitContext != null,
      'Level $runtimeType - The _unitContext has not been defined',
    );
    _unitContext!.observeAgent(agent);
  }

  /// Derived from [NoteKeeping]
  ///
  /// Register the [note] by calling [ContextContainer.takeNote]
  @override
  void takeNote(Note note) {
    _listener?.takeNote(note);
  }

  void render([void Function()? fn]) => setState(fn ?? () {});
}

class WidgetUnitContext extends BaseContext<UnitWidgetState> {
  @override
  final WidgetAgent key;

  WidgetUnitContext({
    required this.key,
    required UnitWidgetState state,
    required Script script,
  }) : super(state: state, script: script);

  @override
  MemberLife get lifeState => key._lifeState;

  @override
  set lifeState(MemberLife state) {
    key._lifeState = state;
  }

  @override
  void init() {
    super.init();
    state._addListener(selfCaller);

    final agents = state.register();
    if (agents != null) {
      for (var agent in agents) {
        agent._addListener(selfCaller);
      }
    }
  }
}

class _WidgetStateBridge<P extends Paper, T extends UnitWidget<P>>
    extends UnitWidgetState<P, T> {
  final ContextDelegating contextDelegating;

  _WidgetStateBridge(this.contextDelegating);

  @override
  void _observeAgent(WidgetAgent agent) {
    contextDelegating.observeAgent(agent);
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class UnitWidgetStateTestingSupporter {
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
