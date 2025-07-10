/// Support for doing something awesome.
///
/// More dartdocs go here.
library paper;

export 'src/establisher.dart' show PaperFrameworkEstablisher;
export 'src/interfaces/unit.dart'
    show
        Agent,
        UnitAgent,
        WidgetAgent,
        AgentSet,
        UnitAgentSet,
        WidgetAgentSet,
        Unit,
        UnitState,
        UnitWidget,
        UnitWidgetState,
        Script,
        PaperListener,
        Paper,
        Note,
        PaperHandler,
        SourceVerifier;
export 'src/utilities/controller.dart' show Controller;
export 'src/utilities/model.dart'
    show Model, ListModel, MapModel, JsonModel, ListJsonModel, MapJsonModel;
export 'src/utilities/result.dart' show Result, Success, Failure;

export 'unit_tester/unit_tester.dart'
    show TestUnit, TestUnitWidget, AgentValidator;
