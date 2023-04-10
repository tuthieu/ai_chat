import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ai_chat/global_key.dart';

enum AlertDialogType { simple, yesNo }

Future<bool> showAlertDialog(String title, String content,
    {AlertDialogType dialogType = AlertDialogType.simple}) async {
  BuildContext context = navigatorKey.currentContext!;

  Widget okButton = TextButton(
    child: Text(AppLocalizations.of(context)!.ok),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );

  Widget yesButton = TextButton(
    child: Text(AppLocalizations.of(context)!.yes),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );

  Widget noButton = TextButton(
    child: Text(AppLocalizations.of(context)!.no),
    onPressed: () {
      Navigator.pop(context, false);
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      if (dialogType == AlertDialogType.simple) okButton,
      if (dialogType == AlertDialogType.yesNo) yesButton,
      if (dialogType == AlertDialogType.yesNo) noButton,
    ],
  );

  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
