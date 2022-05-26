extension WrapExtension<T> on Iterable<T> {
  Iterable<Iterable<T>> wrap(
    int margin, [
    int skipFirst = 0,
  ]) sync* {
    for (var iter = skip(skipFirst);
        iter.isNotEmpty;
        iter = iter.skip(margin)) {
      yield iter.take(margin);
    }
  }
}

extension RangeExtension on int {
  Iterable<int> to(int stop, {int? step}) sync* {
    step ??= this < stop ? 1 : -1;

    while (step == 0) {
      yield this;
    }

    if (this < stop == step > 0) {
      yield* Iterable.generate(
        (this - stop).abs() ~/ step.abs(),
        (int i) => this + i * step!,
      );
    }
  }
}
