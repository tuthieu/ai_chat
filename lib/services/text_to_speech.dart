import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechProvider {
  TextToSpeechProvider._();

  static final TextToSpeechProvider tts = TextToSpeechProvider._();
  static FlutterTts? _textToSpeech;
  Future<FlutterTts> get textToSpeech async =>
      _textToSpeech ??= await initTTS();

  Future<FlutterTts> initTTS() async {
    FlutterTts ftts = FlutterTts();
    await ftts.setLanguage("en-US");
    await ftts.setSpeechRate(0.5);
    await ftts.awaitSpeakCompletion(true);
    return ftts;
  }

  Future<void> speak(String text) async {
    final ftts = await textToSpeech;
    await ftts.stop();
    await ftts.speak(text);
  }

  Future<void> stop() async {
    final ftts = await textToSpeech;
    await ftts.stop();
  }
}
