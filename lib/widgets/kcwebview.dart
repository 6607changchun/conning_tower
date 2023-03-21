import 'dart:async';
import 'dart:io';
import 'package:conning_tower/constants.dart';
import 'package:conning_tower/helper.dart';
import 'package:conning_tower/pages/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:conning_tower/kc/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../generated/l10n.dart';
import '../helper.dart';
import '../pages/home.dart';

class KCWebView extends StatefulWidget {
  const KCWebView(this.webViewController, {super.key});

  final Completer<InAppWebViewController> webViewController;
  @override
  State<StatefulWidget> createState() => KCWebViewState();
}

class KCWebViewState extends State<KCWebView> {
  // late String defaultUA;
  final GlobalKey webViewKey = GlobalKey();

  static get defaultUA {
    if (Platform.isAndroid) {
      return kChromeUA;
    } else if (Platform.isIOS) {
      return kSafariUA;
    }
  }

  @override
  void initState() {
    beforeRedirect = false;
    super.initState();
  }



  InAppWebViewSettings webViewSetting = InAppWebViewSettings(
    javaScriptEnabled: true,
    userAgent: customUA.isNotEmpty ? customUA : defaultUA,
    preferredContentMode: UserPreferredContentMode.DESKTOP,
    //Allow window.open JS
    javaScriptCanOpenWindowsAutomatically: true,
    //Android intercept kancolle API
    useShouldInterceptRequest: true,
    isElementFullscreenEnabled: false,
  );

  @override
  Widget build(BuildContext context) {
    String homeUrl = getHomeUrl();
    return AspectRatio(aspectRatio: 5/3,child: InAppWebView(
      key: webViewKey,
      initialSettings: webViewSetting,
      initialUrlRequest: URLRequest(
          url: WebUri(homeUrl)),
      onWebViewCreated: (InAppWebViewController controller) {
        widget.webViewController.complete(controller);

        if(Platform.isAndroid){ //Listen Kancolle API
          WebMessageListener kcListener= WebMessageListener(jsObjectName: "kcMessage",
              onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
                kancolleRawMessageHandle(message!);
              }
          );
          controller.addWebMessageListener(kcListener);
        }

      },
      onLoadStart: (controller,uri){
        print('Page started loading: $uri');
        // var uri = Uri.parse(uri);
        beforeRedirect = false;
        if (uri!.path.startsWith(
            '/netgame/social/-/gadgets/=/app_id=854854')) {
          beforeRedirect = true;
          inKancolleWindow = false;
          autoAdjusted = false;
        } else if (uri.host == 'osapi.dmm.com') {
          inKancolleWindow = true;
          autoAdjusted = false;
        }
      },
      onLoadStop: (controller,uri){
        if(Platform.isIOS){
          if(uri!.path.startsWith('/netgame/social/-/gadgets/=/app_id=854854')){
            controller.injectJavascriptFileFromAsset(assetFilePath: httpRedirectJS);
            Fluttertoast.showToast(
                msg: S.current.KCViewFuncMsgAutoGameRedirect);
          }else if(uri.host == 'osapi.dmm.com'){
            inKancolleWindow = true;
            gameLoadCompleted = true;
            Fluttertoast.showToast(
                msg: S.of(context).KCViewFuncMsgNaviGameLoadCompleted);
            HapticFeedback.mediumImpact();
            if(enableAutoScale){
              autoAdjustWindowV2(controller).whenComplete(() => (){
                controller.evaluateJavascript(source: """
                console.log("Msg Start - script is running.");
                var origOpen = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function() {
                    this.addEventListener('load', function() {
                        if (this.responseURL.includes('/kcsapi/')) {
                            console.log("Msg URL - " + this.responseURL);
                            KcapiToFlutter(this);
                        }
                    });
                    origOpen.apply(this, arguments);
                };
                
                function KcapiToFlutter(data) {
                    console.log("Msg Data - " + data.responseText);
                }
                """, contentWorld: ContentWorld.world(name: "flashWrap"));
              });
            }
          }
        }else if (Platform.isAndroid) {
          if(uri!.path.startsWith('/netgame/social/-/gadgets/=/app_id=854854')){
            inKancolleWindow = true;
            gameLoadCompleted = true;
            Fluttertoast.showToast(
                msg: S.of(context).KCViewFuncMsgNaviGameLoadCompleted);
            HapticFeedback.mediumImpact();
            if(enableAutoScale){
              autoAdjustWindowV2(controller);
            }
          }
        }
      },
      onZoomScaleChanged: (controller,oldScale,newScale) async {
        if(controller.getUrl().toString().contains('osapi.dmm.com') && Platform.isIOS  ){
          await controller.injectJavascriptFileFromAsset(assetFilePath: autoScaleIOSJS);
        }
      },
      onCreateWindow: (controller,uri){
        return true as Future<bool>;
      },
      shouldInterceptRequest: (
          controller,
          WebResourceRequest request,
          ) async {
        if (request.url.path.contains("/kcs2/js/main.js")) {
          Future<WebResourceResponse?> customResponse = interceptRequest(request);
          return customResponse;
        }
        return null;
      },
      onConsoleMessage: (controller, consoleMessage){
        debugPrint(consoleMessage.message);
      },
    ),);
  }
}