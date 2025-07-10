import 'dart:collection';

/// The base type for every models.
///
/// The [key] is required to define the uniqueness of the model.
abstract class Model {
  const Model();

  Object get key;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Model &&
            runtimeType == other.runtimeType &&
            key == other.key);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ key.hashCode;
}

class ListModel<E> extends Model {
  final List<E> _source;

  ListModel(List<E> source, {Object Function(ListModel<E> list)? keyGen})
      : _source = [...source] {
    _keyGen = keyGen ?? (_) => _source.join('&');
  }

  @override
  late final Object key = _keyGen(this);

  late final Object Function(ListModel<E> list) _keyGen;

  late final length = _source.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  E? at(int index) {
    try {
      return _source.elementAt(index);
    } catch (_) {
      return null;
    }
  }

  bool any(bool Function(E element) test) {
    return _source.any(test);
  }

  bool contains(Object? element) {
    return _source.contains(element);
  }

  bool every(bool Function(E element) test) {
    return _source.every(test);
  }

  E? firstWhere(bool Function(E element) test) {
    try {
      return _source.firstWhere(test);
    } catch (_) {
      return null;
    }
  }

  void forEach(void Function(E element) action) {
    _source.forEach(action);
  }

  int? indexOf(E element, [int start = 0]) {
    return _source.indexOf(element, start);
  }

  int indexWhere(bool Function(E element) test, [int start = 0]) {
    return _source.indexWhere(test, start);
  }

  Iterator<E> get iterator => _source.iterator;

  Iterable<T> map<T>(T Function(E e) toElement) {
    return _source.map(toElement);
  }

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    return _source.singleWhere(test);
  }

  List<E> toList({bool growable = true}) {
    return _source.toList(growable: growable);
  }

  Set<E> toSet() {
    return _source.toSet();
  }

  Map<int, E> toMap() {
    return _source.asMap();
  }

  Iterable<E> where(bool Function(E element) test) {
    return _source.where(test);
  }

  Iterable<T> whereType<T>() {
    return _source.whereType();
  }
}

class MapModel<K, V> extends Model {
  final Map<K, V> _source;

  MapModel(Map<K, V> source, {Object Function(MapModel<K, V> list)? keyGen})
      : _source = UnmodifiableMapView(source) {
    _keyGen = keyGen ?? (_) => _source.keys.join('&');
  }

  @override
  late final Object key = _keyGen(this);

  late final Object Function(MapModel<K, V> map) _keyGen;

  V? operator [](Object? key) => _source[key];

  bool containsKey(Object? key) => _source.containsKey(key);

  bool containsValue(Object? value) => _source.containsValue(value);

  Iterable<MapEntry> get entries => _source.entries;

  void forEach(void Function(dynamic key, dynamic value) action) =>
      _source.forEach(action);

  bool get isEmpty => _source.isEmpty;

  bool get isNotEmpty => _source.isNotEmpty;

  Iterable get keys => _source.keys;

  Iterable get values => _source.values;

  int get length => _source.length;

  Map<K2, V2> map<K2, V2>(
          MapEntry<K2, V2> Function(dynamic key, dynamic value) transform) =>
      _source.map(transform);
}

class JsonModelParsingException implements Exception {
  final Type source;

  final Function getter;

  JsonModelParsingException({required this.source, required this.getter});

  @override
  String toString() {
    return '$runtimeType: Cannot retrieve the value from $getter of $source due to incorrect expected type';
  }
}

abstract class JsonModel extends Model {
  T? getOrThrowException<T>(dynamic value, {required Function getter}) {
    if (value == null || value is T) return value;
    throw JsonModelParsingException(source: runtimeType, getter: getter);
  }
}

abstract class MapJsonModel extends JsonModel {
  final Map<String, dynamic> _json;

  MapJsonModel(Map<String, dynamic> json) : _json = json;

  @override
  Object get key => _json.keys.join('&');

  String? tryString(String field, {required Function getter}) =>
      getOrThrowException<String>(_json[field], getter: getter);

  num? tryNum(String field, {required Function getter}) =>
      getOrThrowException<num>(_json[field], getter: getter);

  bool? tryBool(String field, {required Function getter}) =>
      getOrThrowException<bool>(_json[field], getter: getter);

  // Map<String, dynamic>? tryMap(String field, {required Function getter}) =>
  //     getOrThrowException<Map<String, dynamic>>(_json[field], getter: getter);

  // List<dynamic>? tryList(String field, {required Function getter}) =>
  //     getOrThrowException<List<dynamic>>(_json[field], getter: getter);

  T? tryMapObject<T>(
    String field,
    T Function(Map<String, dynamic> j) onCreate, {
    required Function getter,
  }) {
    final json = getOrThrowException<Map<String, dynamic>>(
      _json[field],
      getter: getter,
    );
    return json != null ? onCreate(json) : null;
  }

  T? tryListObject<T>(
    String field,
    T Function(List<dynamic> j) onCreate, {
    required Function getter,
  }) {
    final json = getOrThrowException<List<dynamic>>(
      _json[field],
      getter: getter,
    );
    return json != null ? onCreate(json) : null;
  }
}

abstract class ListJsonModel extends JsonModel {
  final List<dynamic> _json;

  ListJsonModel(List<dynamic> json) : _json = json;

  late final length = _json.length;

  @override
  Object get key => _json.join('&');

  String? stringItem(int index) =>
      getOrThrowException<String>(_json[index], getter: stringItem);

  num? numItem(int index) =>
      getOrThrowException<num>(_json[index], getter: numItem);

  bool? boolItem(int index) =>
      getOrThrowException<bool>(_json[index], getter: boolItem);

  T? tryMapObject<T>(
    int index,
    T Function(Map<String, dynamic> j) onCreate, {
    required Function getter,
  }) {
    final json = getOrThrowException<Map<String, dynamic>>(
      _json[index],
      getter: getter,
    );
    return json != null ? onCreate(json) : null;
  }

  T? tryListObject<T>(
    int index,
    T Function(List<dynamic> j) onCreate, {
    required Function getter,
  }) {
    final json = getOrThrowException<List<dynamic>>(
      _json[index],
      getter: getter,
    );
    return json != null ? onCreate(json) : null;
  }
}
