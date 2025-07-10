part of 'unit.dart';

/// The object represents a units in the tree. Consider [Agent] as a reference to a unit.
///
/// [Agent]s are registered to refer to units by their parent.
///
/// [Agent]s provide APIs for unit parents to give commands to their children units.
abstract class Agent<P extends Paper> extends Unique {
  /// The parent that manages the agent.
  ContextDelegating? _parent;

  /// Register the parent.
  void _addListener(ContextDelegating parent) {
    _parent = parent;
  }

  /// The state of lifecycle of the unit the agent refers to.
  MemberLife _lifeState = MemberLife.absence;

  /// Indicate whether the unit is initialized and registered into the tree
  bool get isInit => _lifeState == MemberLife.init;

  /// Indicate whether the unit is being initialized
  bool get isInitializing => _lifeState == MemberLife.initializing;

  /// Indicate whether the unit is being disposed or have not been initialized
  bool get isAbsence => _lifeState == MemberLife.absence;

  PaperListener<P, Paper>? _reporter;

  /// Register the listeners for notifying the parent.
  void _logReporter(PaperListener<P, Paper>? reporter) {
    _reporter = reporter;
  }
}

/// The agent is specialized for [Unit].
class UnitAgent<P extends Paper> extends Agent<P> {
  Unit<P> Function(UnitAgent<P>) _builder = (_) => throw Exception();

  UnitAgent<P> log(Unit<P> Function(UnitAgent<P> agent) builder) {
    _builder = builder;
    return this;
  }

  Future<void> init() {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitState.register]',
    );
    return _parent?.initUnit(this, _builder(this)) ?? Future(() => null);
  }

  void dispose() {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitState.register]',
    );
    _parent?.disposeUnit(this);
  }

  Future<void> process(P paper) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitState.register]',
    );
    return _parent?.command(this, paper) ?? Future(() => null);
  }

  Future<R?> report<R extends P>() {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitState.register]',
    );
    return _parent?.requestReport<R>(this) ?? Future(() => null);
  }
}

/// The agent is specialized for [UnitWidget].
class WidgetAgent<P extends Paper> extends Agent<P> {
  late final _key = GlobalKey();

  UnitWidget<P> Function(WidgetAgent<P>) _builder = (_) => throw Exception();

  WidgetAgent<P> log(UnitWidget<P> Function(WidgetAgent<P> agent) builder) {
    _builder = builder;
    return this;
  }

  Future<void> constructAsRoot() {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );
    return _parent?.constructRootWidget(_builder(this)) ?? Future(() => null);
  }

  void Function()? _onDispose;

  void _disposeUnit() {
    _parent?.disposeUnit(this);
    _onDispose?.call();
  }

  void _constructUnit(WidgetUnit unit) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );
    _parent?.initWidgetUnit(this, unit);
  }

  Future<void> process(P paper) {
    return _parent?.command(this, paper) ?? Future(() {});
  }

  Future<R?> report<R extends P>() {
    return _parent?.requestReport<R>(this) ?? Future(() => null);
  }
}

/// A collection of agents that are registered to create same type of units.
///
/// There are two subtypes of [AgentSet] are provided for [UnitAgent] and [WidgetAgent].
/// They are [UnitAgentSet] and [WidgetAgentSet] respectively.
abstract class AgentSet<TAgent extends Agent> {
  late final _agents = HashMap<String, TAgent>.identity();

  /// Check the life state of the agent of [key] is init.
  bool isInitAt(String key) {
    if (!_agents.containsKey(key)) {
      return false;
    }

    return _agents[key]!.isInit;
  }

  /// Check the life state of the agent of [key] is initializing.
  bool isInitializingAt(String key) {
    if (!_agents.containsKey(key)) {
      return false;
    }

    return _agents[key]!.isInitializing;
  }

  /// Check the life state of the agent of [key] is absent.
  bool isAbsentAt(String key) {
    if (!_agents.containsKey(key)) {
      return true;
    }

    return _agents[key]!.isAbsence;
  }
}

/// A collection set of [UnitAgent].
abstract class UnitAgentSet<P extends Paper> extends AgentSet<UnitAgent<P>> {
  UnitAgentSet._();

  factory UnitAgentSet() => _UnitAgentImpl();

  /// Similar to [UnitAgent.log], it register a method to create unit.
  ///
  /// The [builder] takes an additional input of [key] to register the unit attached to the [key].
  ///
  /// The [Agent] returned by this method should NOT be used as ordinary agent.
  /// It only plays a role of allowing this method to be called within [UnitState.register] or [UnitWidgetState.register].
  /// Calling some member from this agent will throw [UnsupportedError].
  Agent log(Unit Function(String key, UnitAgent<P> a) builder);

  /// Init the unit attached to [key].
  Future<void> init(String key);

  /// Dispose the unit attached to [key].
  void dispose(String key);

  /// Command the unit attached to [key] to process [paper].
  Future<void> process(String key, {required P paper});

  /// Command the unit attached to [key] to report a paper of type [R].
  Future<void> report<R extends P>(String key);
}

class _UnitAgentImpl<P extends Paper> extends UnitAgentSet<P>
    implements Agent<P> {
  _UnitAgentImpl() : super._();

  Unit Function(String key, UnitAgent<P> a) _builder =
      (_, __) => throw Exception();

  @override
  ContextDelegating? _parent;

  @override
  void _addListener(ContextDelegating parent) {
    _parent = parent;
  }

  @override
  Agent log(Unit Function(String key, UnitAgent<P> a) builder) {
    _builder = builder;
    return this;
  }

  @override
  Future<void> init(String key) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );

    if (_agents.containsKey(key)) return Future.value();

    final agent = UnitAgent<P>();

    return _parent!.initUnit(agent, _builder(key, agent));
  }

  @override
  void dispose(String key) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );

    if (!_agents.containsKey(key)) return;
    final agent = _agents.remove(key)!;
    _parent!.disposeUnit(agent);
  }

  @override
  Future<void> process(String key, {required P paper}) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );

    final UnitAgent<P> agent;
    if (!_agents.containsKey(key)) {
      agent = UnitAgent<P>();
      _agents[key] = agent;
      return _parent!
          .initUnit(agent, _builder(key, agent))
          .then((_) => _parent!.command(agent, paper));
    } else {
      agent = _agents[key]!;
      return _parent!.command(agent, paper);
    }
  }

  @override
  Future<R?> report<R extends P>(String key) {
    assert(
      _parent != null,
      'The parent that manages the agent has not been defined. Please register agent by [UnitWidgetState.register]',
    );

    final agent = _agents[key];

    if (agent == null) return Future.value(null);

    return _parent!.requestReport<R>(agent);
  }

  @override
  MemberLife get _lifeState {
    throw UnsupportedError(
      'Cannot execute getter _lifeState from UnitAgentSet',
    );
  }

  @override
  set _lifeState(MemberLife lifeState) {
    throw UnsupportedError(
      'Cannot execute setter _lifeState from UnitAgentSet',
    );
  }

  @override
  PaperListener<P, Paper>? get _reporter {
    throw UnsupportedError('Cannot execute getter _reporter from UnitAgentSet');
  }

  @override
  set _reporter(PaperListener<P, Paper>? reporter) {
    throw UnsupportedError('Cannot execute setter _reporter from UnitAgentSet');
  }

  @override
  void _logReporter(PaperListener<P, Paper>? reporter) {
    throw UnsupportedError('Cannot execute _logReporter from UnitAgentSet');
  }

  @override
  bool get isAbsence {
    throw UnsupportedError('Cannot execute isAbsence from UnitAgentSet');
  }

  @override
  bool get isInit {
    throw UnsupportedError('Cannot execute isInit from UnitAgentSet');
  }

  @override
  bool get isInitializing {
    throw UnsupportedError('Cannot execute isInitializing from UnitAgentSet');
  }
}

/// A collection set of [UnitAgent].
class WidgetAgentSet<P extends Paper> extends AgentSet<WidgetAgent<P>> {
  /// Retrieve the agent at [key].
  WidgetAgent<P> agentAt(String key) {
    final WidgetAgent<P> agent;
    if (!_agents.containsKey(key)) {
      agent = WidgetAgent()
        .._onDispose = () {
          _agents.remove(key);
        };

      _agents[key] = agent;
      return agent;
    }

    return _agents[key]!;
  }

  /// Command the unit attached to [key] to process [paper].
  Future<void> process(String key, {required P paper}) {
    if (!_agents.containsKey(key)) {
      return Future.value();
    }
    return _agents[key]!.process(paper);
  }

  Future<R?> report<R extends P>(String key) {
    final agent = _agents[key];

    if (agent == null) return Future.value(null);

    return agent.report<R>();
  }
}

@visibleForTesting
class AgentTestingSupporter {
  void setReporterToAgent<P extends Paper>(
    Agent agent,
    PaperListener<P, Paper> reporter,
  ) {
    agent._logReporter(reporter);
  }

  void setLifeStateToAgent(
    Agent agent,
    MemberLife state,
  ) {
    agent._lifeState = state;
  }

  void setListenerToAgent(
    Agent agent,
    ContextDelegating parent,
  ) {
    agent._addListener(parent);
  }

  ContextDelegating? getListener(Agent agent) {
    return agent._parent;
  }

  PaperListener? getReporter(Agent agent) {
    return agent._reporter;
  }
}
