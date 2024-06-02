import 'package:chronomap_mobile/register/register_model.dart';
import 'package:chronomap_mobile/utils/textformfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/dropdown_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterModel>(
        create: (_) => RegisterModel(),
        child: Consumer<RegisterModel>(builder: (_, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.registerA),
            ),
            floatingActionButton: FloatingActionButton.extended(
                backgroundColor: Colors.green[200],
                onPressed: () async {
                  model.convertPoint();
                  int result = await model.save();
                  String title;
                  String content;

                  switch (result) {
                    case 0:
                      title = 'Succeeded';
                      content = 'Thank you for adding Information';
                      break;
                    case 1:
                      title = 'Failed';
                      content = 'Oops! Something went wrong...';
                      break;
                    case 2:
                      title = 'Failed';
                      content = 'Required fields are missing';
                      break;
                    default:
                      title = 'Unexpected Error';
                      content = 'Please try again later';
                      break;
                  }

                  if (!context.mounted) return;

                  model.showCustomDialog(context, title, content);
                },
                label: Text(AppLocalizations.of(context)!.registerE)),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(AppLocalizations.of(context)!.registerB),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomDropdownButton(
                      selectedValue: model.selectedCalendar,
                      options: model.periods,
                      onChanged: (value) {
                        model.setCalendar(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: NumberFormat(
                      hintText: 'year',
                      onChanged: (value) {
                        model.setNewYearD(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: NumberFormat(
                      hintText: "month 1-12 or 0",
                      onChanged: (value) {
                        model.setNewMonth(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: NumberFormat(
                      hintText: "date 1-31 or 0",
                      onChanged: (value) {
                        model.setNewDay(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(AppLocalizations.of(context)!.registerC),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        } else {
                          return model.options.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        }
                      },
                      onSelected: (String selection) {
                        model.setSelectedCountry(selection);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(AppLocalizations.of(context)!.registerD),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: TffFormat(
                      hintText: "",
                      onChanged: (text) {
                        model.setNewName(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        })
    );
  }
}