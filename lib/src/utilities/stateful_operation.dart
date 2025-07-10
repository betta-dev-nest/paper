import 'dart:collection';

import 'package:flutter/foundation.dart';

class StatefulOperation<I, O> {
  StatefulOperation(this._call);

  final Future<O> Function(I param) _call;

  late final _runnings = <_Unique, I>{};

  UnmodifiableListView<I> get runnings =>
      UnmodifiableListView(_runnings.values);

  Future<O> call(I param) {
    final key = _Unique();
    _runnings[key] = param;
    return _call(param).whenComplete(() {
      _runnings.remove(key);
    });
  }
}

class _Unique {
  _Unique();

  @override
  String toString() => '[#${shortHash(this)}]';
}
