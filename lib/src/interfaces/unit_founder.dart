part of 'unit.dart';

abstract class FounderBase implements ContextDelegating {
  late final selfCall = ContextContainer(this);

  @override
  void observeAgent(Agent agent) {
    agent._addListener(selfCall);
  }

  @override
  Future<void> command(Agent agent, Paper paper) {
    return Future.value();
  }

  @override
  Future<void> initUnit(UnitAgent agent, Unit unit) =>
      throw UnimplementedError();

  @override
  Future<void> constructRootWidget(UnitWidget widget) =>
      throw UnimplementedError();

  @override
  void initWidgetUnit(WidgetAgent agent, WidgetUnit unit) =>
      throw UnimplementedError();

  @override
  void disposeUnit(Agent agent) => throw UnimplementedError();

  @override
  void process(Paper paper, dynamic cause) => throw UnimplementedError();

  @override
  Future<P?> requestReport<P extends Paper>(Agent<Paper> of) {
    throw UnimplementedError();
  }

  @override
  void takeNote(Note note) => throw UnimplementedError();
}
