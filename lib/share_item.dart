
import 'share_type.dart';

/// Plugin for summoning a platform share sheet.
class ShareItem {

  static const String TITLE = "title";
  static const String TEXT = "text";
  static const String PATH = "path";
  static const String TYPE = "type";
  static const String PACKAGENAME = "package";
  static const String IS_MULTIPLE = "is_multiple";
  static const String COUNT = "count";

  final ShareType mimeType;
  final String title;
  final String text;
  final String path;
  final String package;
  final List<ShareItem> shares;

  bool get isNull => this.mimeType == null;

  bool get isMultiple => this.shares.length > 0;

  ShareItem.nullType() :
    this.mimeType = null,
    this.title = '',
    this.text = '',
    this.path = '',
	  this.package='',
    this.shares = const[]
  ;

  const ShareItem.plainText({
    this.title,
	  this.package,
    this.text
  }) : assert(text != null),
       this.mimeType = ShareType.TYPE_PLAIN_TEXT,
       this.path = '',
       this.shares = const[];

  const ShareItem.file({
    this.mimeType = ShareType.TYPE_FILE,
    this.title,
    this.path,
	  this.package,
    this.text = ''
  }) : assert(mimeType != null),
       assert(path != null),
       this.shares = const[];

  const ShareItem.image({
    this.mimeType = ShareType.TYPE_IMAGE,
    this.title,
    this.path,
	  this.package,
    this.text = ''
  }) : assert(mimeType != null),
       assert(path != null),
       this.shares = const[];

  const ShareItem.multiple({
    this.mimeType = ShareType.TYPE_FILE,
    this.title,
	  this.package='',
    this.shares
  }) : assert(mimeType != null),
       assert(shares != null),
       this.text = '',
       this.path = '';


  static ShareItem fromReceived(Map received) {
    assert(received.containsKey(TYPE));
    final ShareType type = ShareType.fromMimeType(received[TYPE]);
    final String package = received[PACKAGENAME];
    if (received.containsKey(IS_MULTIPLE)) {
      return _fromReceivedMultiple(received, type, package);
    } else {
      return _fromReceivedSingle(received, type, package);
    }
  }

  // ignore: missing_return
  static ShareItem _fromReceivedSingle(Map received, ShareType type, String package) {
    switch (type) {
      case ShareType.TYPE_PLAIN_TEXT:
        if (received.containsKey(TITLE)) {
          return ShareItem.plainText(
            package: package, 
            title: received[TITLE], 
            text: received[TEXT]
          );
        } else {
          return ShareItem.plainText(
            package: package, 
            text: received[TEXT]
          );
        }
        break;

      case ShareType.TYPE_IMAGE:
        if (received.containsKey(TITLE)) {
          if (received.containsKey(TEXT)) {
            return ShareItem.image(
                package: package,
                path: received[PATH],
                title: received[TITLE],
                text: received[TEXT]);
          } else {
            return ShareItem.image(
              package: package,
              path: received[PATH], 
              text: received[TITLE]
            );
          }
        } else {
          return ShareItem.image(
            package: package,
            path: received[PATH]
          );
        }
        break;

      case ShareType.TYPE_FILE:
        if (received.containsKey(TITLE)) {
          if (received.containsKey(TEXT)) {
            return ShareItem.file(
                package: package,
                path: received[PATH],
                title: received[TITLE],
                text: received[TEXT]
              );
          } else {
            return ShareItem.file(
              package: package,
              path: received[PATH], 
              text: received[TITLE]
            );
          }
        } else {
          return ShareItem.file(
            package: package,
            path: received[PATH]
          );
        }
        break;
    }

  }

  static ShareItem _fromReceivedMultiple(Map received, ShareType type, String package) {
    final int count = received.containsKey(COUNT) ? received[COUNT] : 0;
    final List<ShareItem> receivedShares = new List();
    for (var i = 0; i < count; i++) {
      receivedShares.add(ShareItem.file(path: received["$i"]));
    }
    String title;
    if (received.containsKey(TITLE)) {
      title = received[TITLE];
    }
    return ShareItem.multiple(
      package: package,
      mimeType: type,
      title: title,
      shares: receivedShares,
    );
  }

  @override
  String toString() => 
    'ShareType { mimeType: $mimeType, title: $title, text: $text, path: $path, shares: $shares, package: $package }';

}
