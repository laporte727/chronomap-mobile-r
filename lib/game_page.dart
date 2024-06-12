import 'package:acorn_client/acorn_client.dart';
import 'package:chronomap_mobile/utils/autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_repository.dart';
import 'utils/game_dialog.dart';
import 'serverpod_client.dart';
import 'utils/countries_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => GamePageState();
}

class GamePageState extends State<GamePage> with TickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> values = [];

  void getCountries() {
    for (var country in countries) {
      values.add(country['name']);
    }
  }

  final List<int> _items = List<int>.generate(5, (int index) => index);
  List answers = [];
  List options = [];
  int correctAnswer = 0;
  int incorrectAnswer = 0;
  bool answered = false;
  bool selectCountry = false;
  bool bottomSheet = false;

  final List<Color> backgroundColors =
      List.filled(5, Colors.grey.withOpacity(0.15));
  final Color correctBackgroundColor = Colors.green.withOpacity(0.15);
  final List<Color> stringColors = List.filled(5, Colors.black);
  final Color incorrectStingColor = Colors.red;

  List<Principal> listPrincipal = [];
  List<int> principalIds = [];

  Future<void> fetchPrincipalByLocation(String keywords) async {
    try {
      List<String> location = keywords.split(',').map((e) => e.trim()).toList();
      listPrincipal = await client.principal.getPrincipal(keywords: location);
      principalIds = listPrincipal.map((item) => item.id as int).toList();

      if (!mounted) return;

      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      if (dataRepository.isJapaneseLanguage(context)) {
        for (var item in listPrincipal) {
          var japaneseName = dataRepository.getJapaneseName(item.id!);
          item.affair = japaneseName != 'N/A' ? japaneseName : item.affair;
        }
      }

      if (listPrincipal.length < 5) {
        // データが5件に満たない場合、アラートを表示
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const GameUnder5();
          },
        );
      } else {
        // データが5件以上存在する場合、ゲームのオプションを設定
        for (var item in listPrincipal) {
          options.add([item.affair, item.point]);
        }
        options = List.from(options)..shuffle();
        options = options.sublist(0, 5);
        answers = List.from(options);
        answers.sort((a, b) => a[1].compareTo(b[1]));
        setState(() {});
      }
    } on Exception catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _answer() async {
    correctAnswer = 0;
    incorrectAnswer = 0;
    answered = true;
    for (int index = 0; index < _items.length; index += 1) {
      if (answers[index] == options[_items[index]]) {
        correctAnswer += 1;
        backgroundColors[index] = correctBackgroundColor;
      } else {
        incorrectAnswer += 1;
        stringColors[index] = incorrectStingColor;
      }
    }

    setState(() {});

    if (correctAnswer == _items.length) {
      _animationController.forward(from: 0.0).then((_) {
        _resetGame();
      });
    } else {
      showGameBottomSheet(context, _retry, _resetGame);
      bottomSheet = true;
    }
  }

  void _resetGame() {
    // ゲーム状態のリセット
    for (int index = 0; index < 5; index += 1) {
      backgroundColors[index] = Colors.grey.withOpacity(0.15);
      stringColors[index] = Colors.black;
    }
    correctAnswer = 0;
    incorrectAnswer = 0;
    answered = false;
    selectCountry = false;
    options.clear();
    setState(() {});
  }

  void _retry() {
    for (int index = 0; index < 5; index += 1) {
      backgroundColors[index] = Colors.grey.withOpacity(0.15);
      stringColors[index] = Colors.black;
    }
    correctAnswer = 0;
    incorrectAnswer = 0;
    answered = false;
    bottomSheet = false;
    options.shuffle();
    setState(() {});
  }

  void resetText() {
    setState(() {
      searchController.clear();
    });
  }

  @override
  initState() {
    super.initState();
    getCountries();
    _animationController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: !selectCountry
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    AppLocalizations.of(context)!.gameA,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 80.0),
                  child: GameAutocompleteFormat(
                    value: values,
                    searchController: searchController,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  onPressed: () {
                    fetchPrincipalByLocation(searchController.text);
                    selectCountry = true;
                  },
                  child: const Text('Start Game'),
                )
              ],
            )
          : options.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    !answered
                        ? Text(
                            AppLocalizations.of(context)!.gameB,
                            style: const TextStyle(fontSize: 18),
                          )
                        : Column(
                            children: [
                              Text(
                                '👍: $correctAnswer / 👎: $incorrectAnswer',
                                style: const TextStyle(fontSize: 18),
                              ),
                              if (!bottomSheet)
                                FadeTransition(
                                  opacity: _animation,
                                  child: const Center(
                                    child: Text(
                                      'Perfect!',
                                      style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ),
                                )
                            ],
                          ),
                    const SizedBox(height: 20),
                    Material(
                      child: ReorderableListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        children: <Widget>[
                          for (int index = 0; index < _items.length; index += 1)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.blueGrey, // 枠線の色
                                  width: 1.0, // 枠線の幅
                                ),
                              ),
                              key: Key('$index'),
                              child: ListTile(
                                tileColor: backgroundColors[index],
                                title: Text(
                                  options[_items[index]][0],
                                  style: TextStyle(color: stringColors[index]),
                                ),
                              ),
                            ),
                        ],
                        onReorder: (int oldIndex, int newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final int item = _items.removeAt(oldIndex);
                            _items.insert(newIndex, item);
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (!bottomSheet)
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              elevation: 2),
                          onPressed: _answer,
                          child: const Text('Answer')),
                    if (bottomSheet)
                      const SizedBox(
                        height: 120,
                      )
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
    );
  }
}
