# Share anything plugin

A Flutter plugin to share content from your Flutter app via the platform's share dialog and receive shares from other apps on the platform with support result!

## Usage

To use this plugin:

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
 then, just call Share.share() with share item:
```
ShareItem.plainText(String text, String title);
ShareItem.file(String path, ShareType mimeType, String title, String text);
ShareItem.image(String path, ShareType mimeType, title: <String>, String text);
ShareItem.multiple(List<Share> shares, ShareType mimeType, String title);
```
with only the first shown argument required,
and then call `Share.share(ShareItem item, Rect sharePositionOrigin)`

3. to receive any kind of share, just listen `Share.onShareReceived`.

## Platform Support

| Android | iOS | MacOS | Web |
|:-------:|:---:|:-----:|:---:|
|    ✔️    |  ✔️  |       |     |

## Example

Check out the example in the example project folder for a working example.