import 'package:ai_chat/models/message.dart';
import 'package:ai_chat/models/session.dart';
import 'package:ai_chat/services/chat_gpt.dart';
import 'package:ai_chat/services/database.dart';
import 'package:ai_chat/services/speech_to_text.dart';
import 'package:ai_chat/services/text_to_speech.dart';
import 'package:ai_chat/utils/alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class ChatPage extends StatefulWidget {
  final String title;
  final Session _session;
  final bool _autoReadAloud;

  const ChatPage(this.title, this._session, this._autoReadAloud, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  List<Message> _messages = [];
  int _incomingMessageCount = 0;
  int? _speakingMessageIndex;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    DatabaseProvider.db.getMessages(widget._session.id).then((value) {
      setState(() {
        _messages = value;
      });
    });
  }

  void _sendMessage() {
    if (_textController.text.isEmpty) {
      return;
    }

    setState(() {
      _incomingMessageCount++;
    });

    DatabaseProvider.db
        .newMessage(widget._session.id, _textController.text, Sender.me)
        .then((value) {
      if (value == -1) {
        showAlertDialog(AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.createMessageFailed);
        return;
      }

      DatabaseProvider.db.getMessage(value).then((value) {
        if (value == null) {
          showAlertDialog(AppLocalizations.of(context)!.error,
              AppLocalizations.of(context)!.retrieveMessagesFailed);
          return;
        }
        _textController.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _messages.add(value);
        });

        ChatGPTProvider.ai.chat(_messages).then((value) {
          if (value == null) {
            return;
          }

          DatabaseProvider.db
              .newMessage(widget._session.id, value, Sender.ai)
              .then((value) {
            if (value == -1) {
              showAlertDialog(AppLocalizations.of(context)!.error,
                  AppLocalizations.of(context)!.saveAIResponseFailed);
              return;
            }

            DatabaseProvider.db.getMessage(value).then((value) {
              setState(() {
                _incomingMessageCount--;
              });
              if (value == null) {
                showAlertDialog(AppLocalizations.of(context)!.error,
                    AppLocalizations.of(context)!.saveAIResponseFailed);
                return;
              }
              setState(() {
                _messages.add(value);
              });
              if (widget._autoReadAloud) {
                _handleSpeaking(_messages.length - 1);
              }
            });
          });
        });
      });
    });
  }

  void _handleListening() {
    if (_isListening) {
      SpeechToTextProvider.stt.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    onResult(SpeechRecognitionResult result) {
      setState(() {
        if (result.recognizedWords.isNotEmpty) {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
        }
        if (result.finalResult) {
          _isListening = false;
        }
      });
    }

    onError(SpeechRecognitionError error) {
      setState(() {
        _isListening = false;
      });
    }

    SpeechToTextProvider.stt
        .startListening(onResult: onResult, onError: onError)
        .then((value) => setState(() {
              _isListening = true;
            }));
  }

  void _handleSpeaking(int index) {
    if (index == _speakingMessageIndex) {
      TextToSpeechProvider.tts.stop();
      setState(() {
        _speakingMessageIndex = null;
      });
      return;
    }
    setState(() {
      _speakingMessageIndex = index;
    });
    TextToSpeechProvider.tts.speak(_messages[index].content).then((value) {
      if (index == _speakingMessageIndex) {
        setState(() {
          _speakingMessageIndex = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: WillPopScope(
            onWillPop: () async {
              if (_speakingMessageIndex != null) {
                TextToSpeechProvider.tts.stop();
              }
              Navigator.pop(
                  context, _messages.isNotEmpty ? _messages.last : null);
              return true;
            },
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    _buildMessageList(context),
                    _buildMessageBar(context),
                  ],
                ))));
  }

  Widget _buildMessageBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
            icon: _isListening
                ? const Icon(Icons.mic_off, color: Colors.red)
                : const Icon(Icons.mic, color: Colors.blue),
            onPressed: _handleListening,
            tooltip: AppLocalizations.of(context)!.startRecording),
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              hintText: AppLocalizations.of(context)!.enterMessage,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.blue),
          onPressed: _sendMessage,
          tooltip: AppLocalizations.of(context)!.send,
        ),
      ],
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          reverse: true,
          child: Container(
            margin:
                const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 15.0)),
                for (int i = 0; i < _messages.length; i++)
                  Row(
                    mainAxisAlignment: _messages[i].sender == Sender.me
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: _messages[i].sender == Sender.me
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 10.0)),
                          Text(AppLocalizations.of(context)!.sentAt(
                            DateFormat('hh:mm dd/MM/yyyy')
                                .format(_messages[i].time.toLocal()),
                            _messages[i].sender == Sender.me
                                ? AppLocalizations.of(context)!.me
                                : AppLocalizations.of(context)!.ai,
                          )),
                          Center(
                            child: Row(
                              children: [
                                if (_messages[i].sender == Sender.me)
                                  IconButton(
                                      onPressed: () => _handleSpeaking(i),
                                      icon: _speakingMessageIndex == i
                                          ? const Icon(
                                              Icons.stop_circle_outlined,
                                              color: Colors.red)
                                          : const Icon(
                                              Icons.play_circle_outline,
                                              color: Colors.blue)),
                                Container(
                                  constraints: BoxConstraints(
                                      maxWidth: 0.7 *
                                          MediaQuery.of(context).size.width),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  decoration: BoxDecoration(
                                    color: _messages[i].sender == Sender.me
                                        ? Colors.blueGrey
                                        : Colors.black12,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: SelectableText(_messages[i].content,
                                      style: TextStyle(
                                          color:
                                              _messages[i].sender == Sender.me
                                                  ? Colors.white
                                                  : Colors.black)),
                                ),
                                if (_messages[i].sender == Sender.ai)
                                  IconButton(
                                      onPressed: () => _handleSpeaking(i),
                                      icon: _speakingMessageIndex == i
                                          ? const Icon(
                                              Icons.stop_circle_outlined,
                                              color: Colors.red)
                                          : const Icon(
                                              Icons.play_circle_outline,
                                              color: Colors.blue),
                                      tooltip: _speakingMessageIndex == i
                                          ? AppLocalizations.of(context)!
                                              .stopNarrator
                                          : AppLocalizations.of(context)!
                                              .startNarrator
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_incomingMessageCount > 0) ...[
                  const Padding(padding: EdgeInsets.only(top: 10.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.waitAIResponse),
                    ],
                  ),
                ],
              ],
            ),
          )),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
