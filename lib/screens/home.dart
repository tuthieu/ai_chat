import 'package:ai_chat/main.dart';
import 'package:ai_chat/models/message.dart';
import 'package:ai_chat/models/session.dart';
import 'package:ai_chat/screens/chat.dart';
import 'package:ai_chat/services/database.dart';
import 'package:ai_chat/utils/alert_dialog.dart';
import 'package:ai_chat/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Map<Session, Message?> _sessions;
  late String _language;
  late bool _autoReadAloud;
  bool _isLoading = true;

  Future<void> _initData() async {
    await Future.wait<void>([
      DatabaseProvider.db.getLanguage().then((value) {
        _language =
            value ?? AppLocalizations.supportedLocales.first.languageCode;
        MyApp.setLocale(context, Locale(_language));
        DatabaseProvider.db.setLanguage(_language);
      }),
      DatabaseProvider.db.getAutoReadAloud().then((value) {
        _autoReadAloud = value ?? true;
        DatabaseProvider.db.setAutoReadAloud(_autoReadAloud);
      }),
      DatabaseProvider.db.getSessionsWithLastMessage().then((value) {
        _sessions = value;
      }),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _initData().then((value) => setState(() => _isLoading = false));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(widget.title),
        ),
        actions: _buildAppBarActions(context),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        reverse: true,
        child: Center(
          child: _buildChatList(context),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
          onPressed: _newChatSession,
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.of(context)!.newChat),
      IconButton(
          onPressed: _changeAutoReadAloud,
          icon: Icon(
              _autoReadAloud == true ? Icons.volume_up : Icons.volume_off,
              size: 18),
          tooltip: _autoReadAloud == true
              ? AppLocalizations.of(context)!.turnOffReadAloud
              : AppLocalizations.of(context)!.turnOnReadAloud),
      DropdownButtonHideUnderline(
        child: DropdownButton(
          underline: Container(color: Colors.transparent),
          items: [
            for (Locale locale in AppLocalizations.supportedLocales)
              DropdownMenuItem(
                value: locale.languageCode,
                child: Text(getLanguageName(locale.languageCode) ?? 'Unknown'),
              )
          ],
          onChanged: _changeLanguage,
          value: _language,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          dropdownColor: Theme.of(context).primaryColor,
        ),
      ),
    ];
  }

  Widget _buildChatList(BuildContext context) {
    return Column(
      children: [
        for (MapEntry<Session, Message?> entry in _sessions.entries) ...[
          const Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            shape: const Border(
              top: BorderSide(width: 1.0, color: Colors.grey),
              bottom: BorderSide(width: 1.0, color: Colors.grey),
            ),
            title: Text(AppLocalizations.of(context)!.chatTitle(entry.key.id),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: entry.value != null
                ? Text(entry.value!.content,
                    overflow: TextOverflow.ellipsis, maxLines: 3)
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: AppLocalizations.of(context)!.deleteThisChat,
              onPressed: () => _deleteChatSession(entry.key),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                        AppLocalizations.of(context)!.chatTitle(entry.key.id),
                        entry.key,
                        _autoReadAloud)),
              ).then((value) => setState(() {
                    _sessions[entry.key] = value;
                  }));
            },
          ),
        ],
      ],
    );
  }

  void _newChatSession() {
    DatabaseProvider.db.newSession().then((value) {
      if (value == -1) {
        showAlertDialog(AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.createChatFailed);
        return;
      }
      setState(() {
        _sessions[Session(id: value)] = null;
      });
    });
  }

  void _deleteChatSession(Session session) {
    showAlertDialog(AppLocalizations.of(context)!.deleteChatTitle(session.id),
            AppLocalizations.of(context)!.deleteChatConfirmation,
            dialogType: AlertDialogType.yesNo)
        .then((value) {
      if (value == false) {
        return;
      }
      DatabaseProvider.db.deleteSession(session.id).then((value) {
        if (value == -1) {
          showAlertDialog(AppLocalizations.of(context)!.error,
              AppLocalizations.of(context)!.deleteChatFailed);
          return;
        }
        setState(() {
          _sessions.remove(session);
        });
      });
    });
  }

  void _changeLanguage(String? language) {
    String newLanguage = language!;
    DatabaseProvider.db.setLanguage(newLanguage).then((value) {
      if (value == false) {
        showAlertDialog(AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.changeLanguageFailed);
        return;
      }
      MyApp.setLocale(context, Locale(newLanguage));
    });
    setState(() {
      _language = newLanguage;
    });
  }

  void _changeAutoReadAloud() {
    bool newAutoReadAloud = !_autoReadAloud;
    DatabaseProvider.db.setAutoReadAloud(newAutoReadAloud).then((value) {
      if (value == false) {
        showAlertDialog(AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.changeReadAloudFailed);
        return;
      }
    });
    setState(() {
      _autoReadAloud = newAutoReadAloud;
    });
  }
}
