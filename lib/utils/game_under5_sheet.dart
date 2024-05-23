import 'package:flutter/material.dart';
import 'package:chronomap_mobile/register/register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameUnder5 extends StatefulWidget {
  const GameUnder5({super.key});

  @override
  GameUnder5State createState() => GameUnder5State();
}

class GameUnder5State extends State<GameUnder5> {
  bool selectCountry = false;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.gameAlertA),
      content: Text(AppLocalizations.of(context)!.gameAlertB),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.gameAlertC),
          onPressed: () {
            Navigator.push<String>(
                context,
                MaterialPageRoute(
                    builder: (context) => const RegisterPage()));
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.gameAlertD),
          onPressed: () {
            Navigator.of(context).pop(); // ダイアログを閉じる
            setState(() {
              selectCountry = false;// 国を選ぶステップに戻る
            });
          },
        ),
      ],

    );
  }
}