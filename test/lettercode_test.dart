import 'package:fastautils/fastaparser/constants.dart';
import 'package:fastautils/fastaparser/lettercode.dart';
import 'package:test/test.dart';

void main() {
  group('LetterCode', () {
    test('Construction', () {
      expect(
        LetterCode(SequenceType.nucleotide, 'a').compareTo(
              LetterCode(SequenceType.nucleotide, 'A'),
            ) ==
            0,
        true,
      );
    });

    test('Comparison', () {
      expect(
        LetterCode(SequenceType.aminoacid, 'A').compareTo(
              LetterCode(SequenceType.nucleotide, 'A'),
            ) !=
            0,
        true,
      );

      expect(
        LetterCode(SequenceType.nucleotide, 'A').compareTo(
              LetterCode(SequenceType.nucleotide, 'A'),
            ) ==
            0,
        true,
      );

      expect(
        LetterCode(SequenceType.nucleotide, 'G').compareTo(
              LetterCode(SequenceType.nucleotide, 'A'),
            ) !=
            0,
        true,
      );
    });

    test('toString', () {
      expect(LetterCode(SequenceType.aminoacid, 'A').toString(), 'A');
    });

    test('Complement', () {
      expect(LetterCode(SequenceType.aminoacid, 'A').complement(), null);
      expect(
        LetterCode(SequenceType.nucleotide, 'A').complement()?.compareTo(
                  LetterCode(SequenceType.nucleotide, 'T'),
                ) ==
            0,
        true,
      );

      expect(LetterCode(SequenceType.nucleotide, 'J').complement(), null);
      expect(LetterCode(SequenceType.aminoacid, 'J').complement(), null);
    });

    test('Description', () {
      expect(LetterCode(SequenceType.aminoacid, 'A').description, 'alanine');
      expect(LetterCode(SequenceType.nucleotide, 'A').description, 'adenosine');
      expect(LetterCode(SequenceType.nucleotide, 'J').description, '');
      expect(LetterCode(SequenceType.aminoacid, 'J').description, '');
    });
  });
}
