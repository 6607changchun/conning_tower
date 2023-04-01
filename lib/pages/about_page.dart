import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../generated/l10n.dart';

class AboutPage extends StatelessWidget {
  final PackageInfo packageInfo;

  const AboutPage({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, bool innerBoxIsScrolled) {
        return [
          CupertinoSliverNavigationBar(
            largeTitle: Text(S.current.AboutButton.replaceAll('\n', '')),
          ),
        ];
      },
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SizedBox(
                      height: 280,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 200,
                              width: 200,
                              child: Image.asset('assets/images/logo.png'),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 200,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  AutoSizeText(
                                    packageInfo.appName,
                                    style: const TextStyle(fontSize: 36),
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '${S.of(context).AboutVersion}: ${packageInfo.version}(${packageInfo.buildNumber})',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  // InkWell(
                                  //   onTap: () => launchUrl(Uri.parse(
                                  //       'https://github.com/andychucs/conning_tower')),
                                  //   child: const Text(
                                  //     'Github',
                                  //     style: TextStyle(
                                  //         decoration: TextDecoration.underline,
                                  //         color: CupertinoColors.link),
                                  //   ),
                                  // ),
                                  // InkWell(
                                  //   onTap: () => launchUrl(Uri.parse(
                                  //       'https://github.com/andychucs/conning_tower/wiki')),
                                  //   child: const Text(
                                  //     'Wiki',
                                  //     style: TextStyle(
                                  //         decoration: TextDecoration.underline,
                                  //         color: CupertinoColors.link),
                                  //   ),
                                  // ),
                                  // InkWell(
                                  //   onTap: () => launchUrl(Uri.parse(
                                  //       'https://twitter.com/conntower')),
                                  //   child: const Text(
                                  //     'Twitter',
                                  //     style: TextStyle(
                                  //         decoration: TextDecoration.underline,
                                  //         color: CupertinoColors.link),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Text(
                        S.of(context).AboutDescription,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    SizedBox(
                      height: 30,
                      child:
                          Center(child: Text(S.of(context).AboutContributors, style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Container(
                      height: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Text('AndyChu'),
                          Text('Angus'),
                          Text('naayu'),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
