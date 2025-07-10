import 'dart:collection';

import '../utilities/assert_failure.dart';

abstract class TreeLayoutRegistry<K, T> {
  factory TreeLayoutRegistry() => _LinkedNodeRegistry<K, T>();

  /// Get the root of the structure.
  T? get root;

  /// Get the parent object of the [object].
  T? parentOf(T object);

  /// Get the key by the [object].
  K? keyOf(T object);

  /// Get the object by the [key].
  T? objectOf(K key);

  /// Verify whether the [object] has been registered.
  bool containsObject(T object);

  /// Save the [object] as a root.
  ///
  /// If there has been a object registered as root, a asserting error will be thrown.
  void saveRoot(K key, T object);

  /// Save the [object] under the parent [under].
  ///
  /// If the [object] has already existed in the registry or the [under] has not been registered,
  /// a asserting error will be thrown.
  void save(K key, T object, {required T under});

  /// Remove the object from the registry.
  ///
  /// On each object removed, [onObjectRemoved] will be called with input of the object.
  /// [removeAllChildren] indicates whether to remove all objects, which are children of the object of [key].
  void removeByKey(
    K key, {
    void Function(T object)? onObjectRemoved,
  });
}

class _LinkedNodeRegistry<K, T> implements TreeLayoutRegistry<K, T> {
  final objects = HashMap<T, _Node<K, T>>.identity();
  final keys = HashMap<K, _Node<K, T>>.identity();

  _Node<K, T>? rootNode;

  @override
  T? get root => rootNode?.object;

  @override
  K? keyOf(T object) => objects[object]?.key;

  @override
  T? objectOf(K key) => keys[key]?.object;

  @override
  bool containsObject(T object) {
    return objects.containsKey(object) || objects[object] == null;
  }

  @override
  void saveRoot(K key, T object) {
    assert(
      root == null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'saveRoot',
        message:
            'A root object as ${root.runtimeType} has been already registered.',
      ),
    );

    rootNode = _Node.root(key, object);

    assert(
      keys[key] == null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'saveRoot',
        message: 'The key [key] as ${key.runtimeType} has been registered.',
      ),
    );
    assert(
      objects[object] == null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'saveRoot',
        message:
            'The object [object] as ${object.runtimeType} has been registered.',
      ),
    );
    _saveNode(key, object, rootNode!);
  }

  @override
  void save(K key, T object, {required T under}) {
    final parentNode = objects[under];

    assert(
      parentNode != null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'save',
        message: 'The parent [under] has not been registered',
      ),
    );

    final node = _Node.sub(key, object, parent: parentNode!);
    _attachNode(node, to: parentNode);

    assert(
      keys[key] == null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'save',
        message: 'The [key] as ${key.runtimeType} has been registered.',
      ),
    );
    assert(
      objects[object] == null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'save',
        message: 'The [object] as ${object.runtimeType} has been registered.',
      ),
    );
    _saveNode(key, object, node);
  }

  @override
  void removeByKey(
    K key, {
    void Function(T object)? onObjectRemoved,
  }) {
    var node = keys[key];
    if (node == null) return;

    final level = node.level;
    final previous = node.previous;

    assert(
      previous != null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'removeByKey',
        message:
            'The previous node of the need-to-remove object is null, which means the the object is root.',
      ),
    );

    _Node<K, T>? next;

    do {
      next = node!.next;

      _removeNode(node);
      onObjectRemoved?.call(node.object);

      node = next;
    } while (node != null && node.level > level);

    previous!.next = node;
    node?.previous = previous;
  }

  @override
  T? parentOf(T object) {
    assert(
      objects[object] != null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'parentOf',
        message:
            'The object [object] as ${object.runtimeType} has not been registered',
      ),
    );

    return objects[object]!.parent?.object;
  }

  void _attachNode(_Node node, {required _Node to}) {
    final next = to.next;

    to.next = node;
    node.previous = to;

    if (next == null) return;

    node.next = next;
    next.previous = node;
  }

  void _saveNode(K key, T object, _Node<K, T> node) {
    keys[key] = node;
    objects[object] = node;
  }

  void _removeNode(_Node node) {
    node.previous = node.next = node.parent = null;
    keys.remove(node.key);
    objects.remove(node.object);
  }
}

class _Node<K, T> {
  _Node.root(this.key, this.object) : level = 1;

  _Node.sub(
    this.key,
    this.object, {
    required _Node<K, T> this.parent,
  }) : level = parent.level + 1;

  final int level;

  final T object;

  final K key;

  _Node<K, T>? previous;

  _Node<K, T>? next;

  _Node<K, T>? parent;
}
