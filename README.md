# Form important!
Completely rewritten android code and added getting the result on IOS.
Now getting the result works correctly on android, ios.
Changed the design of calling the API library.

# Share Anything plugin

A Flutter plugin to share content from your Flutter app via the platform's share dialog and receive shares from other apps on the platform (currently only on Android).  

Wraps the ACTION_SEND Intent, and ACTION_SEND + ACTION_SEND_MULTIPLE IntentReceiver on Android
 and UIActivityViewController on iOS.

# this fork fixes v2 embedding

## Usage

To use this plugin

1. add share
```
 share:
    git:
     url: https://github.com/Alezhka/flutter-share.git
```
 as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

2. to send any kind of share, in your main.dart:
```
import 'package:share/share.dart';
```
 then, just instantiate a Share with the corresponding named constructor, with the relevant named arguments:
```
ShareItem.plainText(text: <String>, title: <String>);
ShareItem.file(path: <String>, mimeType: ShareType, title: , text: );
ShareItem.image(path: , mimeType: , title: , text: );
ShareItem.multiple(shares: List<Share>, mimeType: , title: );
```
with only the first shown argument required,
and then call `Share.share(ShareItem item, Rect sharePositionOrigin)`

3. to receive any kind of share, just listen `Share.onShareReceived`.

## Example

Check out the example in the example project folder for a working example.