class ListenerContainer<T> {
  T? _object;

  ListenerContainer(this._object);

  T? call() => _object;

  void dispose() => _object = null;

  bool isDispose() {
    return _object == null;
  }
}
