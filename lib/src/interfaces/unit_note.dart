part of 'unit.dart';

abstract class NoteKeeping {
  void takeNote(Note note);
}

/// A declarative variable cache that can be used to store a value,
/// which can be interact with [Paper]
abstract class Note<T> {
  factory Note(
    NoteKeeping keeper, {
    bool Function(Paper)? keepWhen,
    T? value,
  }) =>
      ImplNote(
        keeper,
        keepWhen: keepWhen,
        value: value,
      );

  T? value;
}

class ImplNote<T> implements Note<T> {
  T? cachedValue;

  @override
  T? get value => cachedValue;

  @override
  set value(T? value) {
    cachedValue = value;
    onValueSet(this);
  }

  final bool Function(Paper)? keepWhen;

  final void Function(Note<T>) onValueSet;

  ImplNote(
    NoteKeeping keeper, {
    this.keepWhen,
    T? value,
  }) : onValueSet = keeper.takeNote {
    this.cachedValue = value;
  }
}
