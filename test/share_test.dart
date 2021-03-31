// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:share/share.dart';

import 'package:flutter/services.dart';

void main() {
  final mockChannel = MockMethodChannel();

  setUp(() {
    // Re-pipe to mockito for easier verifies.
    Share.methodChannel.setMockMethodCallHandler((MethodCall call) {
      return mockChannel.invokeMethod(call.method, call.arguments);
    });
  });

  test('sharing null fails', () {
    expect(
      () => Share.share(ShareItem.plainText(text: null)),
      throwsA(isA<AssertionError>()),
    );
    verifyZeroInteractions(mockChannel);
  });

  test('sharing empty fails', () {
    expect(
      () => Share.share(ShareItem.plainText(text:'')),
      throwsA(isA<AssertionError>()),
    );
    verifyZeroInteractions(mockChannel);
  });

  test('sharing origin sets the right params', () async {
    await Share.share(ShareItem.plainText(text: 'some text to share'), 
      sharePositionOrigin: Rect.fromLTWH(1.0, 2.0, 3.0, 4.0)
    );
    verify(mockChannel.invokeMethod('share', <String, dynamic>{
      'text': 'some text to share',
      'originX': 1.0,
      'originY': 2.0,
      'originWidth': 3.0,
      'originHeight': 4.0,
    }));
  });

  test('sharing image with empty mimeType', () {
    expect(
      () => Share.share(ShareItem.image(path: "content://0@media/external/images/media/2129")),
      throwsA(isA<AssertionError>()),
    );
    verifyZeroInteractions(mockChannel);
  });

  test('sharing image', () async {
    await Share.share(ShareItem.image(path: "content://0@media/external/images/media/2129", mimeType: ShareType.TYPE_IMAGE),
      sharePositionOrigin: Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
    );
    verify(mockChannel.invokeMethod('share', <String, dynamic>{
      'path': "content://0@media/external/images/media/2129",
      'mimeType': ShareType.TYPE_IMAGE.toString(),
      'originX': 1.0,
      'originY': 2.0,
      'originWidth': 3.0,
      'originHeight': 4.0,
    }));
  });
}

class MockMethodChannel extends Mock implements MethodChannel {}
