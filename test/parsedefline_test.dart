import 'package:darq/darq.dart';
import 'package:fastautils/fastaparser/operations.dart';
import 'package:test/test.dart';

void main() {
  group('parseDefinitionLine', () {
    test('Empty line', () {
      final result_1 = parseDefLine('');
      final result_2 = parseDefLine('>');
      final result_3 = parseDefLine('>     ');
      final result_4 = parseDefLine('  >     \n');

      expect(result_1, null);
      expect(result_2, result_3);
      expect(result_3, result_4);
      expect(result_4, const Tuple2('', ''));
    });

    test('Id and description', () {
      final result_1 = parseDefLine('ID123|moreID description and more text');

      final result_2 = parseDefLine('>ID123|moreID description and more text');

      final result_3 =
          parseDefLine('>  ID123|moreID description and more text\n');

      final result_4 =
          parseDefLine('   > ID123|moreID    description and more text');

      expect(result_1, null);
      expect(result_2, result_3);
      expect(result_3, result_4);
      expect(
        result_4,
        const Tuple2('ID123|moreID', 'description and more text'),
      );
    });

    test('Id only', () {
      final result_1 = parseDefLine('ID123|secondID|otherID     ');
      final result_2 = parseDefLine('>ID123|secondID|otherID');
      final result_3 = parseDefLine('>   ID123|secondID|otherID');
      final result_4 = parseDefLine('> ID123|secondID|otherID    \n');

      expect(result_1, null);
      expect(result_2, result_3);
      expect(result_3, result_4);
      expect(result_4, const Tuple2('ID123|secondID|otherID', ''));
    });
  });
}
