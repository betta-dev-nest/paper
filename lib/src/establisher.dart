import 'dart:async';
import 'dart:collection';

import 'infra/network.dart';
import 'interfaces/unit.dart';

abstract class PaperFrameworkEstablisher {
  factory PaperFrameworkEstablisher() => _Establisher();

  Future<void> initializeUnit(
    Unit unit,
  );

  Future<void> initializeWidgetUnit(
    UnitWidget Function(UnitWidgetState state) unitBuilder,
  );
}

class _Establisher extends FounderBase implements PaperFrameworkEstablisher {
  @override
  Future<void> initializeUnit(
    Unit unit, {
    Paper? paper,
  }) async {
    return network.buildRootMember(unit).then((_) {
      if (awaitingToProcessAfterInitAgents.containsKey(unit.agent)) {
        Future(
          () => awaitingToProcessAfterInitAgents.remove(unit.agent)?.complete(),
        );
      }
    });
  }

  @override
  Future<void> initializeWidgetUnit(
    UnitWidget Function(UnitWidgetState state) unitBuilder,
  ) {
    final bridge = UnitWidgetState.bridge(this);

    final unit = unitBuilder(bridge);

    return network.buildRootWidget(unitBuilder(bridge)).then((_) {
      if (awaitingToProcessAfterInitAgents.containsKey(unit.agent)) {
        Future(
          () => awaitingToProcessAfterInitAgents.remove(unit.agent)?.complete(),
        );
      }
    });
  }

  @override
  void initWidgetUnit(WidgetAgent agent, WidgetUnit unit) {
    network.buildRootMember(unit);
  }

  @override
  Future<void> command(Agent agent, Paper paper) {
    if (agent.isInit) {
      return network.processRootMember(paper);
    }

    final completer = Completer<void>()
      ..future.then((_) => network.processRootMember(paper));
    awaitingToProcessAfterInitAgents[agent] = completer;
    return completer.future;
  }

  late final awaitingToProcessAfterInitAgents =
      HashMap<Agent, Completer<void>>.identity();
}
