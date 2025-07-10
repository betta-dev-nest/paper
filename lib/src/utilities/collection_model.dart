// import 'dart:collection';

// import 'package:paper/src/utilities/model.dart';

// class ListModel<E> extends Model {
//   final List<E> _source;

//   ListModel(List<E> source, {Object Function(ListModel<E> list)? keyGen})
//       : _source = [...source] {
//     _keyGen = keyGen ?? (_) => _source.join('&');
//   }

//   @override
//   late final Object key = _keyGen(this);

//   late final Object Function(ListModel<E> list) _keyGen;

//   late final length = _source.length;

//   bool get isEmpty => length == 0;

//   bool get isNotEmpty => length != 0;

//   E? at(int index) {
//     try {
//       return _source.elementAt(index);
//     } catch (_) {
//       return null;
//     }
//   }

//   bool any(bool Function(E element) test) {
//     return _source.any(test);
//   }

//   bool contains(Object? element) {
//     return _source.contains(element);
//   }

//   bool every(bool Function(E element) test) {
//     return _source.every(test);
//   }

//   E? firstWhere(bool Function(E element) test) {
//     try {
//       return _source.firstWhere(test);
//     } catch (_) {
//       return null;
//     }
//   }

//   void forEach(void Function(E element) action) {
//     _source.forEach(action);
//   }

//   int? indexOf(E element, [int start = 0]) {
//     return _source.indexOf(element, start);
//   }

//   int indexWhere(bool Function(E element) test, [int start = 0]) {
//     return _source.indexWhere(test, start);
//   }

//   Iterator<E> get iterator => _source.iterator;

//   Iterable<T> map<T>(T Function(E e) toElement) {
//     return _source.map(toElement);
//   }

//   E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
//     return _source.singleWhere(test);
//   }

//   List<E> toList({bool growable = true}) {
//     return _source.toList(growable: growable);
//   }

//   Set<E> toSet() {
//     return _source.toSet();
//   }

//   Map<int, E> toMap() {
//     return _source.asMap();
//   }

//   Iterable<E> where(bool Function(E element) test) {
//     return _source.where(test);
//   }

//   Iterable<T> whereType<T>() {
//     return _source.whereType();
//   }
// }

// class MapModel<K, V> extends Model {
//   final Map<K, V> _source;

//   MapModel(Map<K, V> source, {Object Function(MapModel<K, V> list)? keyGen})
//       : _source = UnmodifiableMapView(source) {
//     _keyGen = keyGen ?? (_) => _source.keys.join('&');
//   }

//   @override
//   late final Object key = _keyGen(this);

//   late final Object Function(MapModel<K, V> map) _keyGen;

//   V? operator [](Object? key) => _source[key];

//   bool containsKey(Object? key) => _source.containsKey(key);

//   bool containsValue(Object? value) => _source.containsValue(value);

//   Iterable<MapEntry> get entries => _source.entries;

//   void forEach(void Function(dynamic key, dynamic value) action) =>
//       _source.forEach(action);

//   bool get isEmpty => _source.isEmpty;

//   bool get isNotEmpty => _source.isNotEmpty;

//   Iterable get keys => _source.keys;

//   Iterable get values => _source.values;

//   int get length => _source.length;

//   Map<K2, V2> map<K2, V2>(
//           MapEntry<K2, V2> Function(dynamic key, dynamic value) transform) =>
//       _source.map(transform);
// }
