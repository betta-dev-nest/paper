part of 'unit.dart';

/// A placeholder for implementation for how to process the [p] and leads to change the state [s].
/// [isFrom] is condition verifying if the source the causes the paper to be process.
/// if the cause matches, the [isFrom] will return null, otherwise it will return the cause.
///
/// [report] - implementation for how generate the paper with type [TPaper] and return it to the parent.
typedef PaperHandler<TPaper extends Paper, TState> = FutureOr<void> Function(
  TPaper p,
  TState s,
  SourceVerifier ifFrom,
);

typedef PaperReporter<TPaper extends Paper, TState> = FutureOr<TPaper?>
    Function(TState s);

/// A registry for a collection of [PaperHandler].
///
/// The [Script] will map and point out which [PaperHandler] for the paper with type [TPaper].
abstract class Script<TPaper extends Paper, TState> {
  Type? _currentPaper;

  late final _handlers = HashMap<Type, Function?>.identity();
  late final _reporters = HashMap<Type, Function?>.identity();

  /// The [map] needs to be implemented when defining a script class. For example:
  ///
  /// ```dart
  /// class XScript extends Script<XPaper, XState> {
  ///   XScript map(XScript scr) => src
  ///     .on<FirstPaper>(
  ///       FirstHandler()
  ///     )
  ///     ?.on<SecondPaper>(
  ///       SecondHandler()
  ///     )
  /// }
  /// ```
  // FutureOr<Script<TPaper, TState>?>
  FutureOr<void> map(
      // Script<TPaper, TState> src,
      ) {}

  FutureOr<void> handle(Paper p, dynamic s, SourceVerifier ifFrom) async {
    final type = p.runtimeType;
    if (!_handlers.containsKey(type)) {
      _currentPaper = type;
      await map();
      if (!_handlers.containsKey(type)) {
        _handlers[type] = null;
      }
      _currentPaper = null;
    }
    return _handlers[type]?.call(p, s, ifFrom);
  }

  FutureOr<Paper?> report(Type t, TState s) async {
    if (!_reporters.containsKey(t)) {
      _currentPaper = t;
      await map();
      if (!_reporters.containsKey(t)) {
        _reporters[t] = null;
      }
      _currentPaper = null;
    }
    return _reporters[t]?.call(s);
  }

  /// Used to along with [map] to register handlers to the registry.
  /// Refer to [map] for the example usage.
  Script<TPaper, TState>? on<P extends TPaper>([
    PaperHandler<P, TState>? handler,
    PaperReporter<P, TState>? reporter,
  ]) {
    if (_currentPaper == P) {
      _handlers[P] = handler;
      _reporters[P] = reporter;
      return null;
    }
    return this;
  }
}

/// A placeholder for listeners to a unit.
///
/// [IPaper] is the type of input paper, which is the paper reported from children.
/// [OPaper] is the type of output paper, which is the result from the input paper.
class PaperListener<IPaper extends Paper, OPaper extends Paper> {
  final void Function(PaperListener<IPaper, OPaper> reporter) reporter;

  IPaper? _currentPaper;

  late final _handler = HashMap<Type, Function>.identity();

  PaperListener(this.reporter);

  FutureOr<OPaper?> getPaper(IPaper paper) async {
    if (!_handler.containsKey(paper.runtimeType)) {
      _currentPaper = paper;
      reporter(this);
    }

    return _handler[paper.runtimeType]?.call(paper);
  }

  PaperListener? on<P extends IPaper>(
    FutureOr<OPaper?> Function(P paper) handler,
  ) {
    if (_currentPaper.runtimeType == P) {
      _handler[P] = handler;
      return null;
    }
    return this;
  }
}
