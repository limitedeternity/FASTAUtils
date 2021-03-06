import 'dart:math';
import 'dart:typed_data';

import 'package:darq/darq.dart';
import 'package:fastautils/fastaparser/constants.dart';
import 'package:fastautils/fastaparser/fastasequence.dart';
import 'package:fastautils/logic/utils.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';

double calculateGCPercent(FastaSequence seq) {
  final letterFrequency = seq.letterFrequency();

  return seq.isNotEmpty
      ? ((letterFrequency['G'] ?? 0) +
                  (letterFrequency['C'] ?? 0) +
                  (letterFrequency['S'] ?? 0)) *
              100 /
              seq.length +
          ((letterFrequency['K'] ?? 0) +
                  (letterFrequency['M'] ?? 0) +
                  (letterFrequency['N'] ?? 0) +
                  (letterFrequency['R'] ?? 0) +
                  (letterFrequency['Y'] ?? 0)) *
              50 /
              seq.length +
          ((letterFrequency['B'] ?? 0) + (letterFrequency['V'] ?? 0)) *
              (2 / 3 * 100) /
              seq.length +
          ((letterFrequency['D'] ?? 0) + (letterFrequency['H'] ?? 0)) *
              (1 / 3 * 100) /
              seq.length
      : 0;
}

/*
S = 16.6 x log[Na+]
(Schildkraut & Lifson (1965), Biopolymers 3: 195-208)
*/
double saltCorrection(
  double concNa,
  double concK,
  double concTris,
  double concMg,
  double concdNTPs,
) {
  var milliMol = concNa + concK + concTris / 2;

  // Na equivalent according to von Ahsen et al. (2001)
  if (concK + concMg + concTris + concdNTPs > 0 && concdNTPs < concMg) {
    // dNTPs bind Mg2+ strongly. If [concdNTPs] is larger than or equal to
    // [concMg], free Mg2+ is considered not to be relevant.
    milliMol += 120 * sqrt(concMg - concdNTPs);
  }

  return 16.6 * (log(milliMol * 1e-3) / ln10);
}

/*
Tm = 81.5 + 0.41(%GC) - 600/N + S
(Used by Primer3Plus to calculate the product Tm)
*/
double meltingTempGCContent(FastaSequence seq) {
  final percentGC = calculateGCPercent(seq);

  final meltingTemp =
      seq.isNotEmpty ? 81.5 + 0.41 * percentGC - 600 / seq.length : 0;

  return meltingTemp + saltCorrection(50, 0, 0, 0, 0);
}

Iterable<Tuple2<String, String>> overlapShiftGenerator(
  String left,
  String overlappedRight,
  int overlapLength,
) sync* {
  var leftCopy = left;
  var rightCopy = overlappedRight;
  yield Tuple2(leftCopy, rightCopy);

  for (final _ in overlapLength.to(left.length)) {
    rightCopy = leftCopy[leftCopy.length - overlapLength - 1] + rightCopy;
    leftCopy = leftCopy.iterable.take(leftCopy.length - 1).join();
    yield Tuple2(leftCopy, rightCopy);
  }
}

Future<void> runSlicer(
  Tuple2<XFile, Stream<FastaSequence>> fastaFileAndSequences,
  Tuple3<int, int, int> operationParameters,
) async {
  final inputPath = fastaFileAndSequences.item0.path;
  final inputName = fastaFileAndSequences.item0.name;

  final sequenceMaxLength = operationParameters.item0;
  final overlapLength = operationParameters.item1;
  final overlapMeltingTemp = operationParameters.item2;

  final outputMap = <String, List<Map<String, dynamic>>>{};

  await for (final seq in fastaFileAndSequences.item1) {
    if (seq.type == SequenceType.aminoacid) {
      continue;
    }

    final seqWithOverlaps = seq.sequenceString
        .skip(sequenceMaxLength)
        .wrap(sequenceMaxLength - overlapLength)
        .map((e) => e.join())
        .fold<List<String>>(
      [seq.sequenceString.take(sequenceMaxLength).join()],
      (acc, curr) => [
        ...acc,
        acc.last.iterable.skip(acc.last.length - overlapLength).join() + curr
      ],
    );

    for (var i = 0; i < seqWithOverlaps.length - 1; ++i) {
      final overlapBestFit = overlapShiftGenerator(
        seqWithOverlaps[i],
        seqWithOverlaps[i + 1],
        overlapLength,
      ).where((leftAndRight) {
        final overlapSequence = FastaSequence(
          leftAndRight.item1.iterable.take(overlapLength).join(),
        );

        return overlapSequence.longestRepeat() < 4;
      }).orderBy((leftAndRight) {
        final overlapSequence = FastaSequence(
          leftAndRight.item1.iterable.take(overlapLength).join(),
        );

        return (meltingTempGCContent(overlapSequence) - overlapMeltingTemp)
            .abs();
      }).firstOrDefault();

      if (overlapBestFit == null) {
        continue;
      }

      if (i == 0 || i > 0 && seqWithOverlaps[i - 1] != overlapBestFit.item0) {
        seqWithOverlaps[i] = overlapBestFit.item0;
        seqWithOverlaps[i + 1] = overlapBestFit.item1;
      } else if (overlapBestFit.item0.length == overlapLength) {
        seqWithOverlaps.removeAt(i - 1);
        --i;
      } else {
        seqWithOverlaps[i] = overlapBestFit.item0;
        seqWithOverlaps[i + 1] = overlapBestFit.item1;
      }

      if (seqWithOverlaps[i + 1].length > sequenceMaxLength) {
        final leftOverlap =
            seqWithOverlaps[i + 1].iterable.take(overlapLength).join();

        final rightOverlap = seqWithOverlaps[i + 1]
            .iterable
            .skip(seqWithOverlaps[i + 1].length - overlapLength)
            .join();

        final fragmentList = seqWithOverlaps[i + 1]
            .iterable
            .take(seqWithOverlaps[i + 1].length - overlapLength)
            .skip(overlapLength)
            .wrap(sequenceMaxLength - overlapLength)
            .map((e) => e.join())
            .toList(growable: true);

        if (2 * overlapLength + fragmentList.last.length <= sequenceMaxLength) {
          fragmentList.last += rightOverlap;
        } else {
          fragmentList.add(rightOverlap);
        }

        final postprocessingResult = fragmentList.skip(1).fold<List<String>>(
          [leftOverlap + fragmentList.first],
          (acc, curr) => [
            ...acc,
            acc.last.iterable.skip(acc.last.length - overlapLength).join() +
                curr
          ],
        );

        seqWithOverlaps
          ..removeAt(i + 1)
          ..insertAll(i + 1, postprocessingResult);
      }
    }

    final outputMapEntries =
        seqWithOverlaps.zip<Tuple2<double, double>, Map<String, dynamic>>(
      [
        double.nan,
        ...seqWithOverlaps.skip(1).map((entry) {
          final overlapSequence = FastaSequence(
            entry.iterable.take(overlapLength).join(),
          );

          return meltingTempGCContent(overlapSequence);
        }),
        double.nan
      ].pairwise(),
      (overlappedSeq, overlapTemperatures) {
        return <String, dynamic>{
          'SequenceFragment': overlappedSeq,
          'LeftOverlap': overlapTemperatures.item0.isNaN
              ? ''
              : overlappedSeq.iterable.take(overlapLength).join(),
          'TmLeftOverlap': overlapTemperatures.item0,
          'RightOverlap': overlapTemperatures.item1.isNaN
              ? ''
              : overlappedSeq.iterable
                  .skip(overlappedSeq.length - overlapLength)
                  .join(),
          'TmRightOverlap': overlapTemperatures.item1,
        };
      },
    );

    outputMap[seq.id] = [
      ...outputMap.putIfAbsent(seq.id, () => []),
      ...outputMapEntries,
    ];
  }

  final outputPath = await getSavePath(
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'TOML',
        extensions: ['toml'],
      )
    ],
    initialDirectory: p.dirname(inputPath),
    suggestedName: '${inputName.substring(0, inputName.lastIndexOf("."))}.toml',
    confirmButtonText: 'Save',
  );

  if (outputPath == null) {
    return;
  }

  await XFile.fromData(
    Uint8List.fromList(
      TomlDocument.fromMap(outputMap).toString().codeUnits,
    ),
    name: '${inputName.substring(0, inputName.lastIndexOf("."))}.toml',
    mimeType: 'application/toml',
  ).saveTo(outputPath);
}
