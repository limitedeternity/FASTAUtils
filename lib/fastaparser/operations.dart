import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:darq/darq.dart';
import 'package:fastautils/fastaparser/fastasequence.dart';

Tuple2<String, String>? parseDefLine(String defLine) {
  final lineIterTrimLeft = defLine.iterable.skipWhile((c) => c == ' ');

  if (lineIterTrimLeft.isEmpty || lineIterTrimLeft.first != '>') {
    return null;
  }

  final parts = <String>[
    lineIterTrimLeft.skip(1).skipWhile((c) => c == ' ').join().trim(),
    ''
  ];

  final spaceIdx = parts[0].indexOf(' ');
  if (spaceIdx > -1) {
    parts[1] = parts[0].substring(spaceIdx + 1).trimLeft();
    parts[0] = parts[0].substring(0, spaceIdx);
  }

  return Tuple2.fromList(parts);
}

Stream<FastaSequence> fastaSequencesfromFile(XFile file) async* {
  final lines = file
      .openRead()
      .map((e) => e.toList(growable: false))
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  Tuple2<String, String>? defLineComponents;
  final sequence = StringBuffer();

  await for (final line in lines) {
    final localDefLineComponents = parseDefLine(line);

    if (localDefLineComponents != null) {
      if (sequence.isNotEmpty) {
        yield FastaSequence(
          sequence.toString(),
          defLineComponents?.item0 ?? '',
          defLineComponents?.item1 ?? '',
        );

        sequence.clear();
      }

      defLineComponents = localDefLineComponents;
      continue;
    }

    sequence.write(line);
  }

  if (sequence.isNotEmpty) {
    yield FastaSequence(
      sequence.toString(),
      defLineComponents?.item0 ?? '',
      defLineComponents?.item1 ?? '',
    );

    sequence.clear();
  }
}
