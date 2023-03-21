import 'dart:io';

import 'package:conning_tower/constants.dart';
import 'package:conning_tower/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../constants.dart';
import '../generated/l10n.dart';
import '../helper.dart';
import '../widgets/dailog.dart';
import 'home.dart';

class ToolsPage extends StatefulWidget {
  ToolsPage(this.controller, CookieManager? cookieManager,
      {Key? key, required this.notifyParent, required this.reloadConfig})
      : cookieManager = cookieManager ?? CookieManager.instance(),
        super(key: key);

  final Function() notifyParent;
  final Future<InAppWebViewController> controller;
  late final CookieManager cookieManager;
  final Function() reloadConfig;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  late TextEditingController _uaTextController;

  @override
  void initState() {
    _uaTextController = TextEditingController(text: customUA.isNotEmpty ? customUA : kSafariUA);
    super.initState();
  }
  Future<void> _onHttpRedirect(InAppWebViewController controller) async {
    if (!inKancolleWindow) {
      String? currentUrl = controller.getUrl().toString();
      Uri uri = Uri.parse(currentUrl!);
      if (uri.path.startsWith('/netgame/social/-/gadgets/=/app_id=854854')) {
        // May be HTTPS or HTTP
        allowNavi = true;
        if (Platform.isIOS) {
          await controller.injectJavascriptFileFromAsset(assetFilePath: httpRedirectJS);
        }
        inKancolleWindow = true;
      }
      Fluttertoast.showToast(msg: S.current.KCViewFuncMsgAutoGameRedirect);
      print("HTTP Redirect success");
    } else {
      Fluttertoast.showToast(msg: S.current.KCViewFuncMsgAlreadyGameRedirect);
      print("HTTP Redirect fail");
    }
    print("inKancolleWindow: $inKancolleWindow");
  }

  Future<void> _onClearCache(
      BuildContext context, InAppWebViewController controller) async {
    bool? value = await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
              msg: S.current.AppClearCache.replaceAll('\n', ''),
              isNormal: true);
        });
    if (value ?? false) {
      allowNavi = true;
      await controller.clearCache();
      Fluttertoast.showToast(msg: S.current.AppLeftSideControlsClearCache);
    }
  }

  Future<void> _onClearCookies(BuildContext context) async {
    bool? value = await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
              msg: S.current.AppClearCookie, isNormal: true);
        });
    if (value ?? false) {
      await cookieManager.deleteAllCookies();
      String message = S.current.AppLeftSideControlsLogoutSuccess;
      Fluttertoast.showToast(msg: message);
    }
  }

  Future<void> _onAdjustWindow(InAppWebViewController controller) async {
    if (gameLoadCompleted) {
      await autoAdjustWindowV2(controller, force: true);
    } else {
      Fluttertoast.showToast(
          msg: S.current.KCViewFuncMsgNaviGameLoadNotCompleted);
    }
  }

  Future<void> _onMuteGame(InAppWebViewController controller) async {
    await controller.injectJavascriptFileFromAsset(assetFilePath: muteKancolleJS);
    Fluttertoast.showToast(msg: S.current.MsgMuteGame);
  }

  Future<void> _onUnmuteGame(InAppWebViewController controller) async {
    await controller.injectJavascriptFileFromAsset(assetFilePath: unMuteKancolleJS);
    Fluttertoast.showToast(msg: S.current.MsgUnmuteGame);
  }

  Future<void> _onHomeSave(WebViewController controller) async {
    final String? curUrl = await controller.currentUrl();
    if (isURL(curUrl)) {
      final prefs = await SharedPreferences.getInstance();
      if (curUrl == customHomeUrl) {
        prefs.setString('customHomeUrl', '');
      } else {
        prefs.setString('customHomeUrl', curUrl!);
      }
      prefs.setString('customHomeBase64Url', curUrl!);
      customHomeBase64Url = curUrl;
      widget.reloadConfig();
    }
  }

  Future _showDialogWithInput() async {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(S.current.ToolUATip),
          content: CupertinoTextField(
            controller: _uaTextController,
          ),
          actions: [
            CupertinoDialogAction(child: Text(S.current.Cancel),
              onPressed: (){
                Navigator.of(context).pop(false);
              },),
            CupertinoDialogAction(child: const Text("OK"),
              onPressed: (){
                Navigator.of(context).pop(true);
              },),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.controller,
      builder:
          (BuildContext context, AsyncSnapshot<InAppWebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final InAppWebViewController? controller = snapshot.data;
        return NestedScrollView(
          headerSliverBuilder: (context, bool innerBoxIsScrolled) {
            return [
              CupertinoSliverNavigationBar(
                largeTitle: Text(S.current.ToolsButton),
              ),
            ];
          },
          body: SafeArea(
            top: false,
            bottom: false,
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: Text(S.of(context).ToolTitleWeb),
                  tiles: [
                    SettingsTile.navigation(
                      title: Text(S.of(context).ToolUASetting),
                      leading: const Icon(FontAwesomeIcons.safari),
                      onPressed: (context) async {
                        var value = _uaTextController.value;
                        bool flag = await _showDialogWithInput();
                        if(!flag) {
                          _uaTextController.value = value;
                        }else{
                          customUA = _uaTextController.value.text;
                          localStorage.setString("customUA", customUA);
                        }
                      },
                    ),
                    SettingsTile.navigation(
                      // trailing: Icon(customHomeUrl.isEmpty ? CupertinoIcons.star : CupertinoIcons.star_fill),
                      title: Text(S.of(context).SettingsHomeSave),
                      leading: Icon(customHomeUrl.isEmpty
                          ? CupertinoIcons.star
                          : CupertinoIcons.star_fill),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onHomeSave(controller!);
                      },
                    ),
                    SettingsTile.navigation(
                      leading:
                          const Icon(CupertinoIcons.rectangle_expand_vertical),
                      title: Text(S.of(context).AppRedirect),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onHttpRedirect(controller!);
                      },
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(CupertinoIcons.delete),
                      title: Text(S.of(context).AppClearCache),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onClearCache(context, controller!);
                      },
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(CupertinoIcons.square_arrow_left),
                      title: Text(S.of(context).AppClearCookie),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onClearCookies(context);
                      },
                    ),
                  ],
                ),
                SettingsSection(
                  title: Text(S.of(context).ToolTitleGameSound),
                  tiles: [
                    SettingsTile.navigation(
                      leading: const Icon(CupertinoIcons.volume_down),
                      title: Text(S.of(context).GameUnmute),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onUnmuteGame(controller!);
                      },
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(CupertinoIcons.volume_off),
                      title: Text(S.of(context).GameMute),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onMuteGame(controller!);
                      },
                    ),
                  ],
                ),
                SettingsSection(
                  title: Text(S.of(context).ToolTitleGameScreen),
                  tiles: [
                    SettingsTile.navigation(
                      leading: const Icon(CupertinoIcons.fullscreen),
                      title: Text(S.of(context).AppResize),
                      onPressed: (context) {
                        HapticFeedback.heavyImpact();
                        _onAdjustWindow(controller!);
                      },
                    ),
                    SettingsTile.switchTile(
                      initialValue: bottomPadding,
                      leading: const Icon(CupertinoIcons.rectangle_dock),
                      title: Text(S.of(context).AppBottomSafe),
                      onToggle: (value) async {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          bottomPadding = value;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('bottomPadding', value);
                        widget.reloadConfig();
                        widget.notifyParent();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
