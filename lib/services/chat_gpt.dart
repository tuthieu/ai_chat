import 'package:ai_chat/models/message.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/cupertino.dart';

class ChatGPTProvider {
  ChatGPTProvider._();

  static final ChatGPTProvider ai = ChatGPTProvider._();
  static const _token = /*"YOUR-CHATGPT-API-TOKEN"*/;
  static final OpenAI _openAI = OpenAI.instance.build(
    token: _token,
    baseOption: HttpSetup(
        receiveTimeout: const Duration(seconds: 120),
        connectTimeout: const Duration(seconds: 20)),
  );

  Future<String?> chat(List<Message> messages) async {
    const maxPreviousMessages = 5;
    final List<Message> newestMessages = messages.length > maxPreviousMessages
        ? messages.sublist(messages.length - maxPreviousMessages)
        : messages;
    final request = ChatCompleteText(
      model: ChatModel.ChatGptTurbo0301Model,
      messages: [
        for (final message in newestMessages)
          Map.of({
            "role": message.sender == Sender.me ? "user" : "assistant",
            "content": message.content,
          })
      ],
      maxToken: 1000,
    );

    final response = await _openAI
        .onChatCompletion(request: request)
        .onError((error, stackTrace) {
      debugPrint("ChatGPT error: $error\nstackTrace: $stackTrace");
      return null;
    });
    return response?.choices.first.message.content;
  }
}
