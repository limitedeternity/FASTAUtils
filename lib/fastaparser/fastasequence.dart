import 'dart:math';

import 'package:darq/darq.dart';
import 'package:fastautils/fastaparser/constants.dart';
import 'package:fastautils/fastaparser/lettercode.dart';
import 'package:fastautils/logic/utils.dart';

class FastaSequence {
  FastaSequence(String sequenceStr, [this._id = '', this.description = '']) {
    if (sequenceStr.iterable.any(aminoacidsNotInNucleotides.contains)) {
      _type = SequenceType.aminoacid;
    }

    sequence = sequenceStr.iterable
        .map((e) => LetterCode(_type, e))
        .toList(growable: false);
  }

  Map<String, int> letterFrequency() {
    final result = <String, int>{};

    for (final letterCodeObject in sequence) {
      final letter = letterCodeObject.code;
      result[letter] = result.containsKey(letter) ? result[letter]! + 1 : 1;
    }

    return result;
  }

  int longestRepeat() {
    var maximum = 0, counter = 0;
    var currentLetter = '';

    for (final letter in sequenceString) {
      if (letter == currentLetter) {
        counter += 1;
      } else {
        counter = 1;
        currentLetter = letter;
      }

      maximum = max(counter, maximum);
    }

    return maximum;
  }

  Iterable<LetterCode> get reversedSequence {
    return sequence.reverse();
  }

  Iterable<LetterCode?> get complementedSequence {
    return sequence.map((e) => e.complement());
  }

  String get defLine {
    return '>$id${description.isNotEmpty ? " " : ""}$description';
  }

  Iterable<String> get sequenceString {
    return sequence.map((e) => e.code);
  }

  int get length {
    return sequence.length;
  }

  bool get isEmpty {
    return sequence.isEmpty;
  }

  bool get isNotEmpty {
    return sequence.isNotEmpty;
  }

  SequenceType get type {
    return _type;
  }

  set type(SequenceType newType) {
    _type = newType;

    for (final letterCodeObject in sequence) {
      letterCodeObject.type = _type;
    }
  }

  String get id {
    if (_id.isEmpty) {
      _id = _internalGenerate();
    }

    return _id;
  }

  set id(String newId) {
    if (newId.isEmpty) {
      _id = _internalGenerate();
      return;
    }

    _id = newId;
  }

  String _internalGenerate() {
    final rand = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

    return List.generate(21, (index) => _chars[rand.nextInt(_chars.length)])
        .join();
  }

  @override
  String toString() {
    final buf = StringBuffer(defLine)
      ..write('\n')
      ..write(sequenceString.wrap(70).map(((e) => e.join())).join('\n'))
      ..write('\n');

    return buf.toString();
  }

  SequenceType _type = SequenceType.nucleotide;
  String _id;
  String description;
  List<LetterCode> sequence = [];
}
