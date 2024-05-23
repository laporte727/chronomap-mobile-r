import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'utils/discribe_card.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Information'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoA),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoB),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoC),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoD),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoE),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoF),
                CustomTextContainer(textContent:
                AppLocalizations.of(context)!.infoG),
                CustomTextContainer(textContent: AppLocalizations.of(context)!.infoH),
                const LaunchUrlContainer(),
              ],
            ),
          ),
        )
    );
  }

}