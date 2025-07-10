import 'package:paper/src/protocols.dart';
import 'package:paper/src/utilities/assert_failure.dart';
import 'package:test/test.dart';
import 'package:paper/src/infra/tree_layout_registry.dart';

class StringKey extends Unique {
  final String key;

  StringKey(this.key);
}

void main() {
  group('Test [saveRoot] operation', () {
    final registry = TreeLayoutRegistry<StringKey, String>();

    test(
      'The root of the registry should be null when the registry is firstly initialized',
      () {
        expect(registry.root, null);
      },
    );

    test(
      'The root should be correctly retrieved when having been registered by [saveRoot]',
      () {
        registry.saveRoot(StringKey('rootKey'), 'rootObject');
        expect(registry.root, 'rootObject');
      },
    );

    test(
      'The [saveRoot] should throw asserting error when a root object has been registered',
      () {
        expect(
          () => registry.saveRoot(StringKey('newRootKey'), 'newRootObject'),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'saveRoot',
                message:
                    'A root object as String has been already registered.'),
          )),
        );
      },
    );
  });

  group('Test [save], [parentOf] operation', () {
    final registry = TreeLayoutRegistry<StringKey, String>();
    final root = 'rootObject';

    final k_1 = StringKey('key-1');
    final o_1 = 'object-1';

    final k_2 = StringKey('key-2');
    final o_2 = 'object-2';

    final k_1_1 = StringKey('key-1.1');
    final o_1_1 = 'object-1.1';

    final k_1_2 = StringKey('key-1.2');
    final o_1_2 = 'object-1.2';

    registry.saveRoot(StringKey('rootKey'), 'rootObject');

    test(
      'The [parentOf] will return null if the input object has been registered as root',
      () {
        expect(registry.parentOf(root), null);
      },
    );

    test(
      'The [parentOf] will throw asserting error when the input object has not been registered',
      () {
        expect(
          () => registry.parentOf('not-registered-object'),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );
      },
    );

    test(
      'The children should be saved into the registry by [save] and correctly retrieve its parents by [parentOf]',
      () {
        registry.save(k_1, o_1, under: root);

        expect(registry.parentOf(o_1), root);

        registry.save(k_1_1, o_1_1, under: o_1);

        expect(registry.parentOf(o_1_1), o_1);

        registry.save(k_1_2, o_1_2, under: o_1);

        expect(registry.parentOf(o_1_2), o_1);

        registry.save(k_2, o_2, under: root);

        expect(registry.parentOf(o_2), root);
      },
    );

    test(
      'The [save] should throw asserting error when the input [under] object has been registered',
      () {
        expect(
          () => registry.save(StringKey('key'), 'object',
              under: 'not-registered-object'),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
              object: '_LinkedNodeRegistry<StringKey, String>',
              member: 'save',
              message: 'The parent [under] has not been registered',
            ),
          )),
        );
      },
    );

    test(
      'The [save] should throw asserting error when the input object has been already registered',
      () {
        expect(
          () => registry.save(StringKey('key'), o_1, under: root),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
              object: '_LinkedNodeRegistry<StringKey, String>',
              member: 'save',
              message: 'The [object] as String has been registered.',
            ),
          )),
        );
      },
    );

    test(
      'The [save] should throw asserting error when the input key has been already registered',
      () {
        expect(
          () => registry.save(k_1, 'object', under: root),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
              object: '_LinkedNodeRegistry<StringKey, String>',
              member: 'save',
              message: 'The [key] as StringKey has been registered.',
            ),
          )),
        );
      },
    );
  });

  group('Test [removeByKey] operation', () {
    final registry = TreeLayoutRegistry<StringKey, String>();
    final root = 'rootObject';

    final k_1 = StringKey('key-1');
    final o_1 = 'object-1';

    final k_2 = StringKey('key-2');
    final o_2 = 'object-2';

    final k_1_1 = StringKey('key-1.1');
    final o_1_1 = 'object-1.1';

    final k_1_2 = StringKey('key-1.2');
    final o_1_2 = 'object-1.2';

    final k_1_1_1 = StringKey('key-1.1.1');
    final o_1_1_1 = 'object-1.1.1';

    final k_1_1_2 = StringKey('key-1.1.2');
    final o_1_1_2 = 'object-1.1.2';

    registry.saveRoot(StringKey('rootKey'), 'rootObject');

    registry.save(k_1, o_1, under: root);
    registry.save(k_1_1, o_1_1, under: o_1);
    registry.save(k_1_2, o_1_2, under: o_1);
    registry.save(k_1_1_1, o_1_1_1, under: o_1_1);
    registry.save(k_1_1_2, o_1_1_2, under: o_1_1);
    registry.save(k_2, o_2, under: root);

    test(
      'The [parentOf] should throw asserting error when retrieve the parents of the input object after the input object have been removed.',
      () {
        registry.removeByKey(k_2);

        expect(
          () => registry.parentOf(o_2),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );
      },
    );

    test(
      'The [parentOf] should throw asserting error when retrieve the parents of the input object and its children after the input object have been removed.',
      () {
        registry.removeByKey(k_1);

        expect(
          () => registry.parentOf(o_1),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );

        expect(
          () => registry.parentOf(o_1_1),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );

        expect(
          () => registry.parentOf(o_1_2),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );

        expect(
          () => registry.parentOf(o_1_1_1),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );

        expect(
          () => registry.parentOf(o_1_1_2),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            AssertFailure.infraError(
                object: '_LinkedNodeRegistry<StringKey, String>',
                member: 'parentOf',
                message:
                    'The object [object] as String has not been registered'),
          )),
        );
      },
    );
  });
}
