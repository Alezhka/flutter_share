
class ShareType {

  static const ShareType TYPE_PLAIN_TEXT = const ShareType._internal("text/plain");
  static const ShareType TYPE_IMAGE = const ShareType._internal("image/*");
  static const ShareType TYPE_FILE = const ShareType._internal("*/*");

  static List<ShareType> values() {
    List values = new List<ShareType>();
    values.add(TYPE_PLAIN_TEXT);
    values.add(TYPE_IMAGE);
    values.add(TYPE_FILE);
    return values;
  }

  final String _type;

  const ShareType._internal(this._type);

  static ShareType fromMimeType(String mimeType) {
    for(ShareType shareType in values()) {
      if (shareType.toString() == mimeType) {
        return shareType;
      }
    }
    return TYPE_FILE;
  }

  @override
  String toString() {
    return _type;
  }

}