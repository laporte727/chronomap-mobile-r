import 'package:chronomap_mobile/utils/discribe_card.dart';
import 'package:chronomap_mobile/utils/language_button.dart';
import 'package:chronomap_mobile/utils/shadowed_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'info_page.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  IndexPageState createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> {

  bool _isVisible = false; // テキストの表示状態を管理するフラグ

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible; // 表示状態を切り替える
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          const LanguageDropdownButton(),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InfoPage()));
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Visibility(
                  visible: !_isVisible,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _toggleVisibility,
                        icon: const Icon(
                            Icons.question_mark_sharp,
                            color: Colors.green),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(60, 20, 60, 60),
                        child: ShadowedContainer(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(AppLocalizations.of(context)!.cover)),
                            )),
                      ),
                    ],
                  )
              ),
              Visibility(
                visible: _isVisible,
                child: Column(
                    children: [
                      CustomTextContainer(textContent:
                      AppLocalizations.of(context)!.indexA,
                      ),
                      CustomTextContainer(textContent:
                      AppLocalizations.of(context)!.indexB,
                      ),
                      CustomTextContainer(textContent:
                      AppLocalizations.of(context)!.indexC,
                      ),
                      IconButton(
                          onPressed: _toggleVisibility,
                          icon: const Icon(
                            Icons.thumb_up_alt_sharp,
                            color: Colors.green,
                          )),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}