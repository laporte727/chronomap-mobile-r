import 'package:chronomap_mobile/utils/shadowed_container.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomTextContainer extends StatelessWidget {
  final String textContent;

  const CustomTextContainer({
    super.key,
    required this.textContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 12),
      child: ShadowedContainer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.lightGreen[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Semantics(
              label: textContent,
              child: Text(
                textContent,
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LaunchUrlContainer extends StatelessWidget {
  final String textContent = 'Ecole la Porte Privacy Policy';

  const LaunchUrlContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLaunchUrl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 12),
        child: ShadowedContainer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.lightGreen[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Semantics(
                label: 'Link to the Privacy Policy',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(textContent),
                    const Icon(Icons.open_in_new),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> onLaunchUrl() async {
    final Uri url = Uri.parse('https://laporte727.github.io/ecole.la.porte/chronomap.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // エラーハンドリング: URLを開けない場合の処理
    }
  }
}