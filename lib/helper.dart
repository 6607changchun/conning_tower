import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:conning_tower/pages/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'constants.dart';
import 'generated/l10n.dart';


Future<bool> autoAdjustWindowV2(
  InAppWebViewController controller,{bool force = false})
) async {
  //Adjust Kancolle window
  if ((inKancolleWindow && !autoAdjusted && enableAutoProcess) ||
      (force && inKancolleWindow)) {
    if (Platform.isIOS) {
      await controller.injectJavascriptFileFromAsset(assetFilePath: autoScaleIOSJS);
    } else if (Platform.isAndroid) {
      await controller.injectJavascriptFileFromAsset(assetFilePath: autoScaleAndroidJS);
    }
    autoAdjusted = true;
    Fluttertoast.showToast(msg: S.current.FutureAutoAdjustWindowSuccess);
    print("Auto adjust success");
    allowNavi = false;
    return true;
  }
  print("autoAdjustWindow fail");
  return false;
}

Future<bool> autoAdjustWindow(
    InAppWebViewController controller,
    ) async {
  //Adjust Kancolle window
  if (inKancolleWindow && !autoAdjusted) {
    int getWebviewSizeCount = 0;
    do {
      kWebviewHeight = await controller
          .evaluateJavascript(source: '''window.innerHeight;''') as double;
      kWebviewWidth = await controller
          .evaluateJavascript(source: '''window.innerWidth;''') as double;
      if (kWebviewHeight == 0.0 || kWebviewWidth == 0.0) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        getWebviewSizeCount = 99;
      }
      print("obtaining webview size");
      getWebviewSizeCount++;
    } while (getWebviewSizeCount < 5);
    var resizeScale = 1.0;
    if (kWebviewHeight != 0.0 && kWebviewWidth != 0.0) {
      resizeScale = getResizeScale(kWebviewHeight, kWebviewWidth);
      autoAdjusted = true;
    } else {
      print("autoAdjustWindow fail");
      return false;
    }
    await controller.evaluateJavascript(
        source: '''document.getElementById("spacing_top").style.display = "none";''');
    if (Platform.isIOS) {
      await controller.evaluateJavascript(
        //Scale to correct size(ios webkit)
          source: '''document.getElementById("htmlWrap").style.webkitTransform = "scale($resizeScale,$resizeScale)";''');
    } else if (Platform.isAndroid) {
      await controller.evaluateJavascript(//Scale to correct size(android chrome)
          source: '''document.getElementById("htmlWrap").style.transform = "scale($resizeScale,$resizeScale)";''');
    }
    await Future.delayed(const Duration(seconds: 2));
    await controller.evaluateJavascript(
        source: '''document.getElementById("sectionWrap").style.display = "none";''');
    Fluttertoast.showToast(msg: S.current.FutureAutoAdjustWindowSuccess);
    print("Auto adjust success");
    allowNavi = false;
    return true;
  }
  print("autoAdjustWindow fail");
  return false;
}

getResizeScale(double height, double width) {
  //Get Kancolle iframe resize scale
  var scale = (height * width) / kKancollePixel;
  if (scale < 0.5) {
    while (kKancolleWidth * scale < kWebviewWidth ||
        kKancolleHeight * scale < kWebviewHeight) {
      scale = scale + 0.05;
    }
    return scale;
  } else {
    while (kKancolleWidth * scale > kWebviewWidth ||
        kKancolleHeight * scale > kWebviewHeight) {
      scale = scale - 0.05;
    }
    return scale;
  }
}

String getHomeUrl() {
  String homeUrl = 'data:text/html;base64,$kHomeBase64';

  // If user never load dmm website, default home page show google. Might be helpful for app store review.
  if (loadedDMM) {
    homeUrl =
        'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(kHome.replaceAll(kGoogle, kGameUrl)))}';
  }

  if (enableAutLoadKC) {
    homeUrl = kGameUrl;
  } else if (isURL(customHomeUrl)) {
    homeUrl = customHomeUrl;
  } else if (customHomeBase64Url.isNotEmpty) {
    debugPrint('getHomeUrl:$customHomeBase64Url');
    customHomeBase64 = base64Encode(const Utf8Encoder()
        .convert(kHome.replaceAll(kGoogle, customHomeBase64Url)));
    homeUrl = 'data:text/html;base64,$customHomeBase64';
  }
  return homeUrl;
}

List<DeviceOrientation> getDeviceOrientation(int? index) {
  if (index == 0) return [DeviceOrientation.landscapeRight];
  if (index == 1) return [DeviceOrientation.landscapeLeft];
  if (index == 2) return [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];
  if (index == 3) return [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft];
  return DeviceOrientation.values;
}