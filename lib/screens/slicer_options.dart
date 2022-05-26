import 'package:arna/arna.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<int> sequenceMaxLengthProvider = StateProvider((_) => 90);

final StateProvider<int> overlapLengthProvider = StateProvider((_) => 20);

final StateProvider<int> overlapMeltingTempProvider = StateProvider((_) => 60);

class SlicerOptions extends ConsumerWidget {
  const SlicerOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ArnaList(
            title: 'Sequence max length',
            showDividers: true,
            showBackground: true,
            children: [
              ArnaTextFormField(
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                initialValue:
                    ref.read(sequenceMaxLengthProvider.state).state.toString(),
                onFieldSubmitted: (value) {
                  if (value.isEmpty) {
                    return;
                  }

                  ref
                      .read(sequenceMaxLengthProvider.state)
                      .update((_) => int.parse(value));
                },
              ),
            ],
          ),
          ArnaList(
            title: 'Overlap length',
            showDividers: true,
            showBackground: true,
            children: [
              ArnaTextFormField(
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                initialValue:
                    ref.read(overlapLengthProvider.state).state.toString(),
                onFieldSubmitted: (value) {
                  if (value.isEmpty) {
                    return;
                  }

                  ref
                      .read(overlapLengthProvider.state)
                      .update((_) => int.parse(value));
                },
              ),
            ],
          ),
          ArnaList(
            title: 'Overlap melting temperature',
            showDividers: true,
            showBackground: true,
            children: [
              ArnaTextFormField(
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                initialValue:
                    ref.read(overlapMeltingTempProvider.state).state.toString(),
                onFieldSubmitted: (value) {
                  if (value.isEmpty) {
                    return;
                  }

                  ref
                      .read(overlapMeltingTempProvider.state)
                      .update((_) => int.parse(value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
