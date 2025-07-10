import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:paper/src/interfaces/unit.dart';
import 'package:meta/meta.dart';
import 'package:paper/src/protocols.dart';

import 'unit_tester.mocks.dart';

part 'unit_tester_env.dart';

/// Provide methods of testing units.
///
/// Example:
///
/// ## Branch -------------
/// ```dart
/// class Branch extends Unit<BranchPaper> {
///   Branch(super.agent, {super.listener});
///
///   @override
///   Script<BranchPaper, UnitState<BranchPaper, Unit<BranchPaper>>>
///       createScript() => BranchScript();
///
///   @override
///   UnitState<BranchPaper, Unit<BranchPaper>> createState() => BranchState();
/// }
///
/// class BranchState extends UnitState<BranchPaper, Branch> {
///   final bigLeaf = UnitAgent<LeafPaper>();
///   final smallLeaf = UnitAgent<LeafPaper>();
///
///   String? smallLeafColor;
///
///   @override
///   Set<Agent> register() => {
///         bigLeaf.log((a) => Leaf(a)),
///         smallLeaf.log((a) => Leaf(a, listener: smallLeafListener)),
///       };
///
///   PaperListener<LeafPaper, BranchPaper> get smallLeafListener => PaperListener(
///         (r) => r.on<LeafColor>((p) {
///           return BranchLeafColor((p.color));
///         }),
///       );
/// }
///
/// class BranchScript extends Script<BranchPaper, BranchState> {
///   @override
///   void map() => on<BranchLeafColor>(onLeafColor);
///
///   void onLeafColor(
///     BranchLeafColor p,
///     BranchState s,
///     SourceVerifier ifFrom,
///   ) async {
///     await s.bigLeaf.process(LeafColor(p.color));
///
///     final childPaper = await s.smallLeaf.report<LeafColor>();
///     s.smallLeafColor = childPaper?.color;
///   }
/// }
///
/// abstract class BranchPaper extends Paper {}
///
/// class BranchLeafColor extends BranchPaper {
///   BranchLeafColor(this.color);
///
///   final String color;
/// }
/// ```
///
/// ## Leaf -------------
/// ```dart
/// class Leaf extends Unit<LeafPaper> {
///   Leaf(super.agent, {super.listener});
///
///   @override
///   Script<LeafPaper, UnitState<LeafPaper, Unit<LeafPaper>>> createScript() =>
///       LeafScript();
///
///   @override
///   UnitState<LeafPaper, Unit<LeafPaper>> createState() => LeafState();
/// }
///
/// class LeafState extends UnitState<LeafPaper, Leaf> {
///   String color = 'green';
/// }
///
/// class LeafScript extends Script<LeafPaper, LeafState> {
///   @override
///   void map() => on<LeafColor>(onColor, onReportColor);
///
///   void onColor(
///     LeafColor p,
///     LeafState s,
///     SourceVerifier ifFrom,
///   ) async {
///     /// Implement function's body
///   }
///
///   LeafColor onReportColor(LeafState s) {
///     return LeafColor(s.color);
///   }
/// }
///
/// abstract class LeafPaper extends Paper {}
///
/// class LeafColor extends LeafPaper {
///   LeafColor(this.color);
///
///   final String color;
/// }
/// ```
///
///
/// ## Unit testing
/// ```dart
/// import 'package:flutter_test/flutter_test.dart';
/// import 'package:mockito/mockito.dart';
/// import 'package:paper/paper.dart';
///
/// void main(){
///   TestUnit.toProcessPaper<Branch, BranchState>(
///     'testing [BranchLeafColor]',
///     unit: Branch(UnitAgent<BranchPaper>()),
///     setup: (state, agentValidator) {
///       when(agentValidator.report(state.smallLeaf, LeafColor))
///         .thenAnswer((_) async => LeafColor('yellow'));
///     },
///     paper: BranchLeafColor('red'),
///     test: (state, agentValidator) {
///       verify(
///         agentValidator.process(
///           state.bigLeaf,
///           argThat(isA<LeafColor>().having((e) => e.color, 'color', 'red')),
///         ),
///       ).called(1);
///       expect(state.smallLeafColor, 'yellow');
///     },
///   );
///
///   TestUnit.toReceivePaper<BranchState>(
///     'testing [LeafColor] from [state.smallLeaf]',
///     unit: Branch(UnitAgent<BranchPaper>()),
///     paper: LeafColor('red'),
///     from: (state) => state.smallLeaf,
///     expected: isA<BranchLeafColor>().having(
///       (e) => e.color,
///       'color',
///       'red',
///     ),
///   );
/// }
/// ```
class TestUnit {
  /// Create a test to verify the operations when [U] unit handles [paper]
  /// with the given [description].
  /// [U] is type the of target unit. [S] is the type of corresponding state of [U].
  ///
  /// [unit] is the Unit for testing.
  ///
  /// [setup] is for initializing and preparing required dependencies for the [unit].
  /// [setup] is called at very first. [setup] is optional.
  ///
  /// [paper] is the target paper need to test the operation of handling.
  /// The testing will command the unit created to process [paper] after [setup].
  ///
  /// [test] is the operation for verify the test case.
  ///
  /// [testOn] is equivalent to `testOn` of `test` in flutter_test.
  ///
  /// [timeout] is equivalent to `timeout` of `test` in flutter_test.
  ///
  /// [skip] is equivalent to `skip` of `test` in flutter_test.
  ///
  /// [tags] is equivalent to `tags` of `test` in flutter_test.
  ///
  /// [onPlatform] is equivalent to `onPlatform` of `test` in flutter_test.
  ///
  /// [retry] is equivalent to `retry` of `test` in flutter_test.
  ///
  /// Refer to [TestUnit] for an example.
  @isTest
  static void
      toProcessPaper<U extends Unit<Paper>, S extends UnitState<Paper, U>>(
    String description, {
    required U unit,
    void Function(S state, AgentValidator agentValidator)? setup,
    required Paper? paper,
    required void Function(S state, AgentValidator agentValidator) test,
    String? testOn,
    flutter_test.Timeout? timeout,
    dynamic skip,
    dynamic tags,
    Map<String, dynamic>? onPlatform,
    int? retry,
  }) {
    final tester = UnitTestingEnvironment();

    flutter_test.test(
      description,
      () async {
        await tester.setupTestingUnit(unit);
        final state = tester.context?.state;
        final agentValidator = tester.network.agentValidator;
        setup?.call(state, agentValidator);
        if (paper != null) {
          await tester.commandTestingUnit(paper);
        }
        test(state, tester.network.agentValidator);
      },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry,
    );
  }

  /// Create a test to verify the operations when [U] unit receive [paper]
  /// that reported by [from] with the given [description].
  /// [U] is type the of target unit. [S] is the type of corresponding state of [U].
  ///
  /// [unit] is the Unit for testing.
  ///
  /// [setup] is for initializing and preparing required dependencies for the [unit].
  /// [setup] is called at very first. [setup] is optional.
  ///
  /// [paper] is the paper will be reported by the child [from].
  ///
  /// [from] is function to return the agents that will send [paper] to the [unit].
  ///
  /// [expected] is the matcher of the expected paper.
  ///
  /// [testOn] is equivalent to `testOn` of `test` in flutter_test.
  ///
  /// [timeout] is equivalent to `timeout` of `test` in flutter_test.
  ///
  /// [skip] is equivalent to `skip` of `test` in flutter_test.
  ///
  /// [tags] is equivalent to `tags` of `test` in flutter_test.
  ///
  /// [onPlatform] is equivalent to `onPlatform` of `test` in flutter_test.
  ///
  /// [retry] is equivalent to `retry` of `test` in flutter_test.
  ///
  /// Refer to [TestUnit] for an example.
  @isTest
  static void
      toReceivePaper<U extends Unit<Paper>, S extends UnitState<Paper, U>>(
    String description, {
    required Unit unit,
    void Function(S state, AgentValidator agentValidator)? setup,
    required Paper paper,
    required Agent Function(S state) from,
    required dynamic expected,
    String? testOn,
    flutter_test.Timeout? timeout,
    dynamic skip,
    dynamic tags,
    Map<String, dynamic>? onPlatform,
    int? retry,
  }) {
    final tester = UnitTestingEnvironment();

    flutter_test.test(
      description,
      () async {
        await tester.setupTestingUnit(unit);
        final state = tester.context!.state;
        final agentValidator = tester.network.agentValidator;
        final child = from(state);
        setup?.call(state, agentValidator);

        if (child is UnitAgent) {
          await child.init();
        }
        if (child is WidgetAgent) {
          await child.constructAsRoot();
        }

        final listener = AgentTestingSupporter().getReporter(child);

        final output = await listener?.getPaper(paper);

        flutter_test.expect(output, expected);
      },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry,
    );
  }
}

/// Provide methods of testing unit widgets.
///
/// Example:
///
/// ## Branch -------------
/// ```dart
/// class Branch extends UnitWidget<BranchPaper> {
///   // ignore: use_key_in_widget_constructors
///   Branch(super.parent, {required super.agent, super.listener});
///
///   @override
///   UnitWidgetState<BranchPaper, Branch> createState() => BranchState();
///
///   @override
///   Script<BranchPaper, BranchState> createScript() => BranchScript();
/// }
///
/// class BranchState extends UnitWidgetState<BranchPaper, Branch> {
///   final bigLeaf = WidgetAgent<LeafPaper>();
///   final smallLeaf = WidgetAgent<LeafPaper>();
///
///   Color? smallLeafColor;
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: Center(
///           child: Column(
///             children: [
///               Leaf(this, agent: bigLeaf),
///               Leaf(this, agent: smallLeaf, listener: smallLeafListener),
///             ],
///           ),
///         ),
///       ),
///     );
///   }
///
///   PaperListener<LeafPaper, BranchPaper> get smallLeafListener => PaperListener(
///         (r) => r.on<LeafColor>((p) {
///           return BranchLeafColor(p.color);
///         }),
///       );
/// }
///
/// class BranchScript extends Script<BranchPaper, BranchState> {
///   @override
///   void map() => on<BranchLeafColor>(onLeafColor);
///
///   void onLeafColor(
///     BranchLeafColor p,
///     BranchState s,
///     SourceVerifier ifFrom,
///   ) async {
///     await s.bigLeaf.process(LeafColor(p.color));
///
///     final childPaper = await s.smallLeaf.report<LeafColor>();
///     s.smallLeafColor = childPaper?.color;
///   }
/// }
///
/// class BranchPaper extends Paper {}
///
/// class BranchLeafColor extends BranchPaper {
///   BranchLeafColor(this.color);
///
///   final Color color;
///}
/// ```
///
/// ## Leaf -------------
/// ```dart
/// class Leaf extends UnitWidget<LeafPaper> {
///   // ignore: use_key_in_widget_constructors
///   Leaf(super.parent, {required super.agent, super.listener});
///
///   @override
///   UnitWidgetState<LeafPaper, Leaf> createState() => LeafState();
///
///   @override
///  Script<LeafPaper, LeafState> createScript() => LeafScript();
/// }
///
/// class LeafState extends UnitWidgetState<LeafPaper, Leaf> {
///   Color color = Colors.green;
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(width: 30, height: 30, color: color);
///   }
/// }
///
/// class LeafScript extends Script<LeafPaper, LeafState> {}
///
/// class LeafPaper extends Paper {}
///
/// class LeafColor extends LeafPaper {
///   LeafColor(this.color);
///
///   final Color color;
/// }
/// ```
///
///
/// ## Unit testing
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:flutter_test/flutter_test.dart';
/// import 'package:mockito/mockito.dart';
/// import 'package:paper/paper.dart';
///
/// void main(){
///   TestUnitWidget.toProcessPaper<Branch, BranchState>(
///     'testing [BranchLeafColor]',
///     create: (s) => Branch(s, agent: WidgetAgent<BranchPaper>()),
///     setup: (state, agentValidator) {
///       when(agentValidator.report(state.smallLeaf, LeafColor))
///           .thenAnswer((_) async => LeafColor(Colors.yellow));
///     },
///     paper: BranchLeafColor(Colors.red),
///     test: (tester, state, agentValidator) {
///       expect(find.byType(Branch), findsOneWidget);
///       expect(find.byType(Leaf), findsNWidgets(2));
///
///       verify(
///        agentValidator.process(
///           state.bigLeaf,
///           argThat(isA<LeafColor>().having((e) => e.color, 'color', Colors.red)),
///         ),
///       ).called(1);
///       expect(state.smallLeafColor, Colors.yellow);
///     },
///   );
///
///   TestUnitWidget.toReceivePaper<Branch, BranchState>(
///     'testing [LeafColor] from [state.smallLeaf]',
///     create: (s) => Branch(s, agent: WidgetAgent<BranchPaper>()),
///     paper: LeafColor(Colors.red),
///     from: (state) => state.smallLeaf,
///     expected: isA<BranchLeafColor>().having(
///       (e) => e.color,
///       'color',
///       Colors.red,
///     ),
///   );
/// }
/// ```
class TestUnitWidget {
  /// Create a test to verify the operations when [U] unit widget handles [paper]
  /// with the given [description].
  /// [U] is type the of target unit. [S] is the type of corresponding state of [U].
  ///
  /// [create] is the method to create the target unit widget.
  /// The input `s` is convenient for inject parent state to the widget.
  ///
  /// [setup] is for initializing and preparing required dependencies for target widget.
  /// [setup] is called at very first. [setup] is optional.
  ///
  /// [paper] is the target paper need to test the operation of handling.
  /// The testing will command the unit created to process [paper] after [setup].
  ///
  /// [test] is the operation for verify the test case.
  ///
  /// [skip] is equivalent to `skip` of `testWidgets` in flutter_test.
  ///
  /// [timeout] is equivalent to `timeout` of `testWidgets` in flutter_test.
  ///
  /// [semanticsEnabled] is equivalent to `semanticsEnabled` of `testWidgets` in flutter_test.
  ///
  /// [variant] is equivalent to `variant` of `testWidgets` in flutter_test.
  ///
  /// [tags] is equivalent to `tags` of `testWidgets` in flutter_test.
  ///
  /// [retry] is equivalent to `retry` of `testWidgets` in flutter_test.
  ///
  /// [experimentalLeakTesting] is equivalent to `experimentalLeakTesting` of `testWidgets` in flutter_test.
  ///
  /// Refer to [TestUnitWidget] for an example.
  @isTest
  static void toProcessPaper<U extends UnitWidget<Paper>,
      S extends UnitWidgetState<Paper, U>>(
    String description, {
    required U Function(UnitWidgetState s) create,
    void Function(S state, AgentValidator agentValidator)? setup,
    required Paper? paper,
    required void Function(
      flutter_test.WidgetTester tester,
      S state,
      AgentValidator agentValidator,
    ) test,
    bool? skip,
    flutter_test.Timeout? timeout,
    bool semanticsEnabled = true,
    flutter_test.TestVariant<Object?> variant =
        const flutter_test.DefaultTestVariant(),
    dynamic tags,
    int? retry,
    LeakTesting? experimentalLeakTesting,
  }) {
    final tester = UnitTestingEnvironment();
    flutter_test.testWidgets(
      description,
      (flutter_test.WidgetTester widgetTester) async {
        await widgetTester.runAsync(() async {
          await tester.setupTestingUnitWidget(create, widgetTester);
          final state = tester.context?.state;
          final agentValidator = tester.network.agentValidator;
          setup?.call(state, agentValidator);
          if (paper != null) {
            await tester.commandTestingUnit(paper);
          }
          test(widgetTester, state, agentValidator);
        });
      },
      skip: skip,
      timeout: timeout,
      semanticsEnabled: semanticsEnabled,
      variant: variant,
      tags: tags,
      retry: retry,
      experimentalLeakTesting: experimentalLeakTesting,
    );
  }

  /// Create a test to verify the operations when [U] unit widget handles [paper]
  /// with the given [description].
  /// [U] is type the of target unit. [S] is the type of corresponding state of [U].
  ///
  /// [create] is the method to create the target unit widget.
  /// The input `s` is convenient for inject parent state to the widget.
  ///
  /// [setup] is for initializing and preparing required dependencies for target widget.
  /// [setup] is called at very first. [setup] is optional.
  ///
  /// [paper] is the paper will be reported by the child [from].
  ///
  /// [from] is function to return the agents that will send [paper] to the widget.
  ///
  /// [expected] is the matcher of the expected paper.
  ///
  /// [skip] is equivalent to `skip` of `testWidgets` in flutter_test.
  ///
  /// [timeout] is equivalent to `timeout` of `testWidgets` in flutter_test.
  ///
  /// [semanticsEnabled] is equivalent to `semanticsEnabled` of `testWidgets` in flutter_test.
  ///
  /// [variant] is equivalent to `variant` of `testWidgets` in flutter_test.
  ///
  /// [tags] is equivalent to `tags` of `testWidgets` in flutter_test.
  ///
  /// [retry] is equivalent to `retry` of `testWidgets` in flutter_test.
  ///
  /// [experimentalLeakTesting] is equivalent to `experimentalLeakTesting` of `testWidgets` in flutter_test.
  ///
  /// Refer to [TestUnitWidget] for an example.
  @isTest
  static void toReceivePaper<U extends UnitWidget<Paper>,
      S extends UnitWidgetState<Paper, U>>(
    String description, {
    required U Function(UnitWidgetState s) create,
    void Function(S state, AgentValidator agentValidator)? setup,
    required Paper paper,
    required Agent Function(S state) from,
    required dynamic expected,
    bool? skip,
    flutter_test.Timeout? timeout,
    bool semanticsEnabled = true,
    flutter_test.TestVariant<Object?> variant =
        const flutter_test.DefaultTestVariant(),
    dynamic tags,
    int? retry,
    LeakTesting? experimentalLeakTesting,
  }) {
    final tester = UnitTestingEnvironment();
    flutter_test.testWidgets(
      description,
      (flutter_test.WidgetTester widgetTester) async {
        await widgetTester.runAsync(() async {
          await tester.setupTestingUnitWidget(create, widgetTester);
          final state = tester.context?.state;
          final agentValidator = tester.network.agentValidator;

          final child = from(state);
          setup?.call(state, agentValidator);

          if (child is UnitAgent) {
            await child.init();
          }

          final listener = AgentTestingSupporter().getReporter(child);

          final output = await listener?.getPaper(paper);

          flutter_test.expect(output, expected);
        });
      },
      skip: skip,
      timeout: timeout,
      semanticsEnabled: semanticsEnabled,
      variant: variant,
      tags: tags,
      retry: retry,
      experimentalLeakTesting: experimentalLeakTesting,
    );
  }
}

abstract class AgentValidator {
  Future<void> process(Agent? agent, Paper? paper);

  Future<Paper?> report(Agent agent, Type type);
}
