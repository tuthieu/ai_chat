import 'package:ai_chat/global_key.dart';
import 'package:ai_chat/utils/alert_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextProvider {
  SpeechToTextProvider._();

  static final SpeechToTextProvider stt = SpeechToTextProvider._();
  static SpeechToText? _speechToText;

  Future<SpeechToText> get speechToText async =>
      _speechToText ??= await initSTT();
  late bool _isSpeechEnabled;
  void Function(SpeechRecognitionError)? _onError;

  Future<SpeechToText> initSTT() async {
    SpeechToText stt = SpeechToText();
    _isSpeechEnabled = await stt.initialize(
      onError: (error) {
        if (_onError != null) {
          _onError!(error);
          _onError = null;
        }
      },
    );
    return stt;
  }

  Future<void> startListening(
      {void Function(SpeechRecognitionResult)? onResult,
      void Function(SpeechRecognitionError)? onError}) async {
    SpeechToText fstt = await speechToText;
    _onError = onError;
    if (!_isSpeechEnabled) {
      showAlertDialog(
          AppLocalizations.of(navigatorKey.currentContext!)!.error,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .speechNotAvailable);
      return;
    }

    await fstt.listen(
      localeId: 'en_US',
      onResult: (value) {
        if (onResult != null) {
          onResult(value);
          if (value.finalResult) {
            _onError = null;
          }
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    SpeechToText fstt = await speechToText;
    await fstt.stop();
  }
}
