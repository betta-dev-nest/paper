import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:paper/src/utilities/assert_failure.dart';

import '../protocols.dart';
import '../utilities/listener_container.dart';

part 'unit_agent.dart';
part 'unit_founder.dart';
part 'unit_note.dart';
part 'unit_script.dart';
part 'unit_standard.dart';
part 'unit_widget.dart';

/// Type for the function of verifying the source that cause changes to the parent
typedef SourceVerifier = T? Function<T>(T);

/// The base type for every papers
abstract class Paper extends Event {
  Paper();
}

/// The object implements the set of operations from [Member] in order for the framework to handle.
///
/// The [BaseContext] consists of [TState] and [Script].
///
/// The [TState] serves as state of the context following the State Design Pattern,
/// which is also functional as similar as [State] in widget building of Flutter.
///
/// The [Script] serves a container of logics of handle [Paper]s that the context receive.
abstract class BaseContext<TState> implements Member, ContextDelegating {
  final TState state;

  final Script script;

  BaseContext({required this.state, required this.script});

  /// A link in the association of [_operator], [operator] getter, [operator] setter.
  ///
  /// It is the reference to the controller who manage the operations of the [Member].
  MemberOperating? _operator;

  /// Derived from [Member]
  ///
  /// A link in the association of [_operator], [operator] getter, [operator] setter.
  ///
  /// It is used to retrieve the operator that referred from [_operator].
  ///
  /// If the operator has been not setup when [operator] is called, an error will be thrown.
  @override
  MemberOperating get operator {
    assert(() {
      if (_operator == null) {
        throw ContextError(
          member: 'listener',
          message: 'The listener has not been defined',
        );
      }
      return true;
    }());
    return _operator!;
  }

  /// Derived from [Member]
  ///
  /// A link in the association of [_operator], [operator] getter, [operator] setter.
  ///
  /// It is used to assign a operator to the member.
  @override
  set operator(MemberOperating? listener) {
    _operator = listener;
  }

  /// Derived from [Member]
  ///
  /// Called only once, after the context is injected into the tree.
  ///
  /// Override this to perform any actions the context need during the initializing phase.
  @override
  @mustCallSuper
  FutureOr<void> init() {}

  /// Derived from [Member]
  ///
  /// Called only once, when the context is removed from the tree permanently.
  ///
  /// To optimize performance, the member has to remember to dispose its operator
  /// by remove the reference [_operator] when the member is disposed by the framework.
  ///
  /// Override this to perform any actions the context need during the disposing phase.
  @override
  @mustCallSuper
  void dispose() {
    operator = null;
    selfCaller.dispose();
  }

  /// Derived from [Member]
  ///
  /// Execute the handling input [Paper] by refer to the [Script] for the corresponding handler.
  /// After the handling is done, the context will erase the [Note]s that are satisfied the condition.
  /// After the erasing is done, the context will add the [Note]s that are marked as need to be added during the handling
  ///
  /// The [cause] is any object that cause the triggering of the handling via the [paper].
  @override
  Future<void> handle(covariant Paper paper, dynamic cause) async {
    // final handler = await script.handlerOf(paper.runtimeType);

    await script.handle(
      paper,
      state,
      <T>(o) => o != cause ? o : null,
    );

    eraseNote(paper);

    if (pendingNotes?.isNotEmpty == true) {
      notes.addAll(pendingNotes!);
      pendingNotes = null;
    }
  }

  /// Derived from [Member]
  ///
  /// Execute the handling input [Paper] that transferred from its controlled child via [Agent]
  /// The input [Paper] is mapped by [Agent._reporter] to convert it into [context]'s registered paper.
  ///
  /// After successfully process the paper, it will be returned to indicate for the [operator] that the handled papers
  @override
  Future<Event?> handleReport(
    covariant Paper paper,
    covariant Agent child,
  ) async {
    final needToHandlePaper = await child._reporter?.getPaper(paper);
    if (needToHandlePaper == null) return null;

    await handle(needToHandlePaper, child);

    return needToHandlePaper;
  }

  /// Derived from [Member]
  ///
  /// Execute the process to retrieve a desired paper with type [E] via [script]
  @override
  FutureOr<Paper?> report<E extends Event>() async {
    // final reporter = await script.reporterOf(E);
    // return reporter?.call(state);
    return script.report(E, state);
  }

  /// The container that cache the reference to this context itself.
  /// It will injected into child agents for the any callback requests.
  late final selfCaller = ContextContainer(this);

  /// Derived from [ContextDelegating]
  ///
  /// Register itself as listener to a child agent.
  @override
  void observeAgent(Agent agent) {
    agent._addListener(selfCaller);
  }

  /// Derived from [ContextDelegating]
  ///
  /// Init a child unit by executing [MemberOperating.buildMemberAsync]
  /// because [Unit]'s context has asynchronous initializing operation and
  /// also avoid blocking any UI operations during the initialization.
  ///
  /// After the successfully initialized the unit, check for any awaiting agent to be processed in [awaitingToProcessAfterInitAgents],
  /// extract the completer and complete it.
  @override
  Future<void> initUnit(UnitAgent agent, Unit unit) {
    if (!agent.isAbsence) return Future.value();
    return operator.buildMemberAsync(this, unit).then((_) {
      if (awaitingToProcessAfterInitAgents.containsKey(agent)) {
        Future(
          () => awaitingToProcessAfterInitAgents.remove(agent)?.complete(),
        );
      }
    });
  }

  /// Derived from [ContextDelegating]
  ///
  /// Init a root child widget unit by executing [MemberOperating.buildRootWidget].
  @override
  Future<void> constructRootWidget(UnitWidget widget) async {
    if (!widget.agent.isAbsence) return Future.value();
    return operator.buildRootWidget(widget);
  }

  /// Derived from [ContextDelegating]
  ///
  /// Init a root child widget unit by executing [MemberOperating.buildMemberSync]
  /// because the widget unit need to following the Flutter framework which
  /// is a synchronous operation.
  @override
  void initWidgetUnit(WidgetAgent agent, WidgetUnit unit) {
    if (!agent.isAbsence) return;
    operator.buildMemberSync(this, unit);
  }

  /// Derived from [ContextDelegating]
  ///
  /// Remove the child context associate with the [agent] by executing [MemberOperating.disposeMember]
  ///
  /// There shall be two different approaches for [Unit] and [UnitWidget].
  /// because FLutter framework will remove the children and on each removing, the child of this framework will be removed as well.
  @override
  void disposeUnit(Agent agent) {
    if (agent.isAbsence) return;
    operator.disposeMember(agent);
  }

  /// Derive from [ContextDelegating]
  ///
  /// Used to request the child [agent] to process the [paper]
  /// If the [agent] has been attached to a context, which means the initializing has been executed before this,
  /// the [agent]
  @override
  Future<void> command(Agent agent, Paper paper) {
    if (agent.isInit) {
      return operator.processMember(this, agent, paper);
    }

    Future<void> processCallback(void _) =>
        operator.processMember(this, agent, paper);

    if (agent.isInitializing) {
      final completer = Completer<void>()..future.then(processCallback);
      awaitingToProcessAfterInitAgents[agent] = completer;
      return completer.future;
    }

    if (agent.isAbsence) {
      if (agent is UnitAgent) {
        return agent.init().then(processCallback);
      } else if (agent is WidgetAgent) {
        return agent.constructAsRoot().then(processCallback);
      } else {
        throw ContextError(
          member: 'command',
          message:
              'The ability of implicitly creating instance for a unit when calling [command] is only available for [UnitAgent] and [WidgetAgent].\nPlease explicitly init the instance of unit by calling your customized operation',
        );
      }
    }

    return Future(() {});
  }

  /// Stores the contexts' agents that are being initialized when [command] execute them to process papers
  ///
  /// When the agents are called to process papers, they will be stores in the map along with their completers
  /// When the initializing finishes, the completers will be completed and the processing papers will be carried out.
  late final awaitingToProcessAfterInitAgents =
      HashMap<Agent, Completer<void>>.identity();

  /// Derived from [ContextDelegating]
  ///
  /// Acquire a paper with type [P] from the child [of] by [MemberOperating.acquireEvent]
  @override
  Future<P?> requestReport<P extends Paper>(Agent of) async {
    // return operator.acquireEvent<P>(of).then((event) {
    //   if (event is P) return event;
    //   return null;
    // });

    final paper = await operator.acquireEvent<P>(of);
    if (paper is P) return paper;
    return null;
  }

  /// Derived from [ContextDelegating]
  ///
  /// Send signal to [MemberOperating] that the context has need to process the [paper],
  /// by triggering [MemberOperating.notifyEvent]
  @override
  void process(Paper paper, dynamic cause) {
    operator.notifyEvent(this, paper, cause);
  }

  /// Contains all notes that are pending for process
  late final notes = HashSet<ImplNote>.identity();
  HashSet<ImplNote>? pendingNotes;

  /// Derived from [ContextDelegating]
  ///
  /// Save the note into the [notes] map
  @override
  void takeNote(covariant ImplNote note) {
    (pendingNotes ??= HashSet<ImplNote>.identity()).add(note);
  }

  /// Called after completing processing a paper inside the [handle].
  ///
  /// The condition [ImplNote.keepWhen] will testified to take action whether to remove to note
  void eraseNote(Paper paper) {
    if (notes.isEmpty) return;
    notes.removeWhere((note) {
      final shouldKeep = note.keepWhen?.call(paper) ?? false;
      if (shouldKeep) return false;

      note.cachedValue = null;
      return true;
    });
  }
}

/// The interface for operating a contexts
///
/// This is the interface, which Agent-types use for commanding its parents contexts.
abstract class ContextDelegating {
  void observeAgent(Agent agent);

  Future<void> initUnit(UnitAgent agent, Unit unit);

  Future<void> constructRootWidget(UnitWidget widget);

  void initWidgetUnit(WidgetAgent agent, WidgetUnit unit);

  void disposeUnit(Agent agent);

  Future<void> command(Agent agent, Paper paper);

  void process(Paper paper, dynamic cause);

  Future<P?> requestReport<P extends Paper>(Agent of);

  void takeNote(Note note);
}

class ContextContainer extends ListenerContainer<ContextDelegating>
    implements ContextDelegating {
  ContextContainer(super.object);

  @override
  Future<void> initUnit(UnitAgent<Paper> agent, Unit<Paper> unit) {
    return this()?.initUnit(agent, unit) ?? Future(() => null);
  }

  @override
  void initWidgetUnit(WidgetAgent<Paper> agent, WidgetUnit unit) {
    this()?.initWidgetUnit(agent, unit);
  }

  @override
  Future<void> constructRootWidget(UnitWidget<Paper> widget) {
    return this()?.constructRootWidget(widget) ?? Future(() => null);
  }

  @override
  Future<void> command(Agent<Paper> agent, Paper paper) {
    return this()?.command(agent, paper) ?? Future(() => null);
  }

  @override
  void disposeUnit(Agent<Paper> agent) {
    this()?.disposeUnit(agent);
  }

  @override
  void observeAgent(Agent<Paper> agent) {
    this()?.observeAgent(agent);
  }

  @override
  void process(Paper paper, dynamic cause) {
    this()?.process(paper, cause);
  }

  @override
  Future<P?> requestReport<P extends Paper>(Agent<Paper> of) {
    return this()?.requestReport(of) ?? Future(() => null);
  }

  @override
  void takeNote(Note note) {
    this()?.takeNote(note);
  }
}

class ContextError extends Error {
  final String member;
  final String message;

  ContextError({required this.member, required this.message});

  @override
  String toString() {
    return Error.safeToString(
      AssertFailure.infraError(
        object: 'EventLine',
        member: member,
        message: message,
      ),
    );
  }
}
