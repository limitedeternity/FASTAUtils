import 'package:arna/arna.dart';
import 'package:darq/darq.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fastautils/fastaparser/operations.dart';
import 'package:fastautils/logic/slicer.dart';
import 'package:fastautils/screens/slicer_options.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' show ButtonBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<List<XFile>> fileProvider = StateProvider((_) => []);

final AutoDisposeStateProvider<bool> isDraggingProvider =
    StateProvider.autoDispose((_) => false);

class SlicerScreen extends ConsumerWidget {
  const SlicerScreen({super.key});

  static const double breakpoint = 500; // px

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Flexible(
          flex: ref.watch(fileProvider.state).state.isNotEmpty &&
                  MediaQuery.of(context).size.width > breakpoint
              ? 70
              : 100,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Flexible(
                flex: 90,
                child: DropTarget(
                  onDragDone: (details) {
                    if (details.files.isEmpty) {
                      return;
                    }

                    ref.read(fileProvider.state).update(
                          (state) => [
                            ...state,
                            ...details.files.where(
                              (file) => file.name.endsWith('.fasta'),
                            ),
                          ]
                              .distinct((file) => file.path)
                              .toList(growable: false),
                        );
                  },
                  onDragEntered: (_) {
                    ref.read(isDraggingProvider.state).update((_) => true);
                  },
                  onDragExited: (_) {
                    ref.read(isDraggingProvider.state).update((_) => false);
                  },
                  child: Container(
                    color: ref.watch(isDraggingProvider.state).state
                        ? ArnaColors.shade57
                        : ArnaColors.shade43,
                    margin: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Drop files here',
                            style: ArnaTheme.of(context).textTheme.title,
                          ),
                          Text(
                            'or',
                            style: ArnaTheme.of(context).textTheme.subtitle,
                          ),
                          ArnaButton(
                            label: 'Browse',
                            buttonType: ButtonType.colored,
                            onPressed: () {
                              openFiles(
                                acceptedTypeGroups: [
                                  XTypeGroup(
                                    label: 'FASTAs',
                                    extensions: ['fasta'],
                                  )
                                ],
                              ).then(
                                (files) {
                                  if (files.isEmpty) {
                                    return;
                                  }

                                  ref.read(fileProvider.state).update(
                                        (state) => [
                                          ...state,
                                          ...files,
                                        ]
                                            .distinct((file) => file.path)
                                            .toList(growable: false),
                                      );
                                },
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 10,
                child: ButtonBar(
                  mainAxisSize: MainAxisSize.min,
                  alignment: MainAxisAlignment.center,
                  children: [
                    if (ref.watch(fileProvider.state).state.isNotEmpty)
                      ArnaButton(
                        label: 'Dequeue all',
                        buttonType: ButtonType.colored,
                        accentColor: ArnaColors.red,
                        icon: Icons.clear_all_outlined,
                        onPressed: () {
                          ref.read(fileProvider.state).update((_) => []);
                        },
                      ),
                    ArnaButton(
                      label: 'Process',
                      buttonType: ButtonType.colored,
                      icon: Icons.chevron_right_outlined,
                      onPressed: ref.watch(fileProvider.state).state.isEmpty
                          ? null
                          : () {
                              showArnaPopupDialog<Tuple3<int, int, int>?>(
                                context: context,
                                useRootNavigator: false,
                                builder: (context) => const SlicerOptions(),
                                title: 'Options',
                                actions: [
                                  ArnaTextButton(
                                    label: 'Go',
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        Tuple3(
                                          ref
                                              .read(
                                                sequenceMaxLengthProvider.state,
                                              )
                                              .state,
                                          ref
                                              .read(
                                                overlapLengthProvider.state,
                                              )
                                              .state,
                                          ref
                                              .read(
                                                overlapMeltingTempProvider
                                                    .state,
                                              )
                                              .state,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ).then((params) {
                                if (params == null) {
                                  return;
                                }

                                if (params.item0 <= params.item1) {
                                  showArnaSnackbar(
                                    context: context,
                                    message: 'Task rejected: length mismatch',
                                  );

                                  return;
                                }

                                showArnaSnackbar(
                                  context: context,
                                  message:
                                      'Task accepted with parameters: $params',
                                );

                                ref
                                    .read(fileProvider.state)
                                    .state
                                    .map(
                                      (file) => Tuple2(
                                        file,
                                        fastaSequencesfromFile(file),
                                      ),
                                    )
                                    .map((data) => runSlicer(data, params))
                                    .awaitAll();

                                ref.read(fileProvider.state).update((_) => []);
                              });
                            },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        if (ref.watch(fileProvider.state).state.isNotEmpty &&
            MediaQuery.of(context).size.width > breakpoint)
          Flexible(
            flex: 30,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ArnaList(
                    showBackground: true,
                    showDividers: true,
                    children: ref
                        .watch(fileProvider.state)
                        .state
                        .asMap()
                        .entries
                        .map(
                          (entry) => ArnaListTile(
                            title: entry.value.name,
                          ),
                        )
                        .toList(growable: false),
                  ),
                )
              ],
            ),
          ),
      ],
    );
  }
}
