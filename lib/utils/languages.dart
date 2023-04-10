final isoLangs = {
  "en": {"name": "English", "nativeName": "English", "3letters": "eng"},
  "vi": {"name": "Vietnamese", "nativeName": "Tiếng Việt", "3letters": "vie"},
};

String? getLanguageName(String languageCode) {
  return isoLangs[languageCode]?['nativeName'];
}
