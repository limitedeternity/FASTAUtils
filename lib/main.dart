import 'package:arna/arna.dart';
import 'package:fastautils/screens/slicer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: FastaUtilsApp()));

class FastaUtilsApp extends ConsumerWidget {
  const FastaUtilsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArnaApp(
      debugShowCheckedModeBanner: false,
      theme: ArnaThemeData(
        brightness: Brightness.dark,
        accentColor: ArnaColors.orange,
      ),
      home: const Home(),
    );
  }
}

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  Widget build(BuildContext context) {
    return ArnaMasterDetailScaffold(
      title: 'FASTAUtils',
      leading: const Padding(
        padding: Styles.normal,
        child: Icon(
          Icons.vertical_split,
          size: Styles.buttonSize,
          color: ArnaColors.buttonColor,
        ),
      ),
      items: <MasterNavigationItem>[
        MasterNavigationItem(
          title: 'Slicer',
          leading: const Icon(Icons.view_timeline_outlined),
          builder: (_) => const SlicerScreen(),
        ),
      ],
    );
  }
}
