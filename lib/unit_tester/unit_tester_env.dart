part of 'unit_tester.dart';

class UnitTestingEnvironment implements ContextDelegating {
  BaseContext? context;

  late final TestingMemberOperating network;

  UnitTestingEnvironment() {
    network = TestingMemberOperating(onBuildMemberSync: buildMemberSync);
  }

  void buildMemberSync(Member source, MemberBuilder builder) {
    final member = builder.createMember();
    if (member is BaseContext && context == null) {
      context = member;
    }
    member.init();
    member.lifeState = MemberLife.init;
  }

  Future<void> setupTestingUnit(Unit unit) async {
    final ctx = unit.createMember();
    context = ctx;
    ctx.operator = network;
    ctx.lifeState = MemberLife.initializing;
    await ctx.init();
    ctx.lifeState = MemberLife.init;
  }

  Future<void> setupTestingUnitWidget(
    UnitWidget Function(UnitWidgetState state) unitBuilder,
    flutter_test.WidgetTester tester,
  ) async {
    final bridge = UnitWidgetState.bridge(this);

    final unit = unitBuilder(bridge);

    await tester.pumpWidget(unit);
  }

  Future<void> commandTestingUnit(Paper paper, {dynamic cause}) async {
    await context?.handle(paper, cause);
  }

  @override
  Future<void> initUnit(UnitAgent<Paper> agent, Unit<Paper> unit) async {}

  @override
  Future<void> command(Agent agent, Paper paper, {dynamic cause}) async {}

  @override
  Future<void> constructRootWidget(UnitWidget<Paper> widget) async {}

  @override
  void disposeUnit(Agent<Paper> agent) {}

  @override
  void initWidgetUnit(WidgetAgent<Paper> agent, WidgetUnit unit) {
    if (context != null) return;

    /// Setup for create and init testing unit widget
    final ctx = unit.createMember();
    context = ctx;
    ctx.operator = network;
    ctx.init();
    ctx.lifeState = MemberLife.init;
  }

  @override
  void observeAgent(Agent<Paper> agent) {
    AgentTestingSupporter().setListenerToAgent(agent, this);
  }

  @override
  void process(Paper paper, cause) {}

  @override
  Future<P?> requestReport<P extends Paper>(Agent<Paper> of) async {
    return null;
  }

  @override
  void takeNote(Note note) {
    throw UnimplementedError();
  }
}

class TestingMemberOperating implements MemberOperating {
  TestingMemberOperating({this.onBuildMemberSync});

  final void Function(Member source, MemberBuilder builder)? onBuildMemberSync;

  final agentValidator = MockAgentValidator();

  @override
  Future<Event?> acquireEvent<E extends Event>(Unique child) async {
    if (child is Agent) {
      return agentValidator.report(child, E);
    }

    return null;
  }

  @override
  Future<void> buildMemberAsync(Member source, MemberBuilder builder) async {}

  @override
  void buildMemberSync(Member source, MemberBuilder builder) {
    onBuildMemberSync?.call(source, builder);
  }

  @override
  Future<void> buildRootWidget(Widget widget) async {}

  @override
  void disposeMember(Unique keys) {}

  @override
  void notifyEvent(Member member, Event event, cause) {}

  @override
  Future<void> processMember(Member source, Unique child, Event event) async {
    if (child is Agent && event is Paper) {
      await agentValidator.process(child, event);
    }
  }
}
