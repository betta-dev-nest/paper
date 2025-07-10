import 'package:mocktail/mocktail.dart';
import 'package:paper/src/interfaces/unit.dart';
import 'package:test/test.dart';

class MockPaper extends Mock implements Paper {}

class FirstMockPaper extends MockPaper {}

class SecondMockPaper extends MockPaper {}

class MockCause extends Mock {}

class MockState extends Mock {}

class TestingScript extends Script<MockPaper, MockState> {
  @override
  void map() =>
      on<FirstMockPaper>(firstHandler)?.on<SecondMockPaper>(secondHandler);

  void firstHandler(
    FirstMockPaper p,
    MockState s,
    SourceVerifier ifFrom,
  ) {}

  void secondHandler(
    SecondMockPaper p,
    MockState s,
    SourceVerifier ifFrom,
  ) {}
}

class InputMockPaper extends Mock implements Paper {}

class FirstInputMockPaper extends InputMockPaper {}

class SecondInputMockPaper extends InputMockPaper {}

class TestingPaperListener extends PaperListener<InputMockPaper, MockPaper> {
  TestingPaperListener(super.reporter);
}

T? mockSourceVerifier<T>(T o) {
  return o != int ? o : null;
}

void main() {
  setUp(() {
    registerFallbackValue(mockSourceVerifier);
  });

  // test('[Script] testing', () async {
  //   final script = TestingScript();
  //   final state = MockState();
  //   final firstPaper = FirstInputMockPaper();
  //   final secondPaper = SecondInputMockPaper();
  //   final cause = MockCause();

  //   await script.handle(firstPaper, state, any());
  //   await script.handle(secondPaper, state, any());
  // });

  test('[PaperListener] testing', () async {
    final listener = TestingPaperListener(
      (l) => l
          .on<FirstInputMockPaper>((p) => FirstMockPaper())
          ?.on<SecondInputMockPaper>((p) => SecondMockPaper()),
    );

    final first = await listener.getPaper(FirstInputMockPaper());
    final second = await listener.getPaper(SecondInputMockPaper());

    expect(first, isA<FirstMockPaper>());
    expect(second, isA<SecondMockPaper>());
  });
}
