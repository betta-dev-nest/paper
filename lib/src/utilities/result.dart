abstract class Result<T, E> {
  Result();

  factory Result.success(T data) => Success(data);

  factory Result.failure(E exp) => Failure(exp);

    
}

class Success<T> extends Result<T, Never> {
  Success(this.data);

  final T data;
}

class Failure<E> extends Result<Never, E> {
  Failure(this.exp);

  final E exp;
}
