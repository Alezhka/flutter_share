// Copyright 2018 Duarte Silveira
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'share_item.dart';
import 'share_type.dart';


/// Plugin for summoning a platform share sheet.
class Share {

  /// [MethodChannel] used to communicate with the platform side.
  @visibleForTesting
  static const MethodChannel _methodChannel = const MethodChannel('plugins.flutter.io/share');
  static const EventChannel _eventChannel = const EventChannel('plugins.flutter.io/receiveshare');

  static Stream<ShareItem> get onShareReceived =>
      _eventChannel.receiveBroadcastStream().map(_toReceiveShare);

  static Future<void> share(ShareItem item, {Rect sharePositionOrigin}) {
    final Map<String, dynamic> params = <String, dynamic>{
      ShareItem.TYPE: item.mimeType.toString(),
      ShareItem.IS_MULTIPLE: item.isMultiple
    };
    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }
    if (item.title != null && item.title.isNotEmpty) {
      params[ShareItem.TITLE] = item.title;
    }

	  if (item.package != null && item.package.isNotEmpty) {
      params[ShareItem.PACKAGENAME] = item.package;
    }
	
    switch (item.mimeType) {
      case ShareType.TYPE_PLAIN_TEXT:
        if (item.isMultiple) {
          for(var i = 0; i < item.shares.length; i++) {
            params["$i"] = item.shares[i].text;
          }
        } else {
          params[ShareItem.TEXT] = item.text;
        }
        break;

      case ShareType.TYPE_IMAGE:
      case ShareType.TYPE_FILE:
        if (item.isMultiple) {
          for (var i = 0; i < item.shares.length; i++) {
            params["$i"] = item.shares[i].path;
          }
        } else {
          params[ShareItem.PATH] = item.path;
          if (item.text != null && item.text.isNotEmpty) {
            params[ShareItem.TEXT] = item.text;
          }
        }
        break;

    }

    return _methodChannel.invokeMethod('share', params);
  }

  static ShareItem _toReceiveShare(dynamic shared) {
    debugPrint("Share received - $shared");
    return ShareItem.fromReceived(shared);
  }

}
