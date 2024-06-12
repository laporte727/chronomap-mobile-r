import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../register/register_page.dart';

// ゲームデータが5件未満のときに表示するダイアログ
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

// 底部シートの表示
void showGameBottomSheet(BuildContext context, VoidCallback onRetry, VoidCallback onResetGame) {
  showModalBottomSheet(
    backgroundColor: Colors.white.withOpacity(0.5),
    context: context,
    barrierColor: Colors.black.withOpacity(0.3),
    isDismissible: false,
    builder: (BuildContext context) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.gameDialogA,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                AppLocalizations.of(context)!.gameDialogB,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry(); // 同じカードで再挑戦
                },
                child: Text(
                  AppLocalizations.of(context)!.gameDialogC,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onResetGame(); // 新しいゲームを開始
                },
                child: Text(
                  AppLocalizations.of(context)!.gameDialogD,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
