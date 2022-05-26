import 'package:fastautils/fastaparser/constants.dart';

class LetterCode implements Comparable<LetterCode> {
  LetterCode(this.type, this.code) {
    code = code.toUpperCase();
  }

  LetterCode? complement() {
    if (type != SequenceType.nucleotide ||
        !nucleotideCodeComplement.containsKey(code)) {
      return null;
    }

    return LetterCode(SequenceType.nucleotide, nucleotideCodeComplement[code]!);
  }

  String get description {
    if (!typeToCodesMap[type]!.contains(code)) {
      return '';
    }

    if (type == SequenceType.nucleotide) {
      return nucleotideNames[code]!;
    } else {
      return aminoacidNames[code]!;
    }
  }

  @override
  int compareTo(LetterCode other) {
    final typeCmp = Enum.compareByIndex(type, other.type);

    if (typeCmp != 0) {
      return typeCmp;
    }

    return code.compareTo(other.code);
  }

  @override
  String toString() {
    return code;
  }

  SequenceType type;
  String code;
}
