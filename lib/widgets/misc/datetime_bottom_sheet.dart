import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lotti/themes/theme.dart';

import '../journal/entry_tools.dart';

class DateTimeBottomSheet extends StatefulWidget {
  const DateTimeBottomSheet(this.initial, {super.key});

  final DateTime? initial;

  @override
  State<DateTimeBottomSheet> createState() => _DateTimeBottomSheetState();
}

class _DateTimeBottomSheetState extends State<DateTimeBottomSheet> {
  DateTime? dateTime = DateTime.now();

  @override
  void initState() {
    dateTime = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          color: styleConfig().primaryColor.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  localizations.cancelButton,
                  style: buttonLabelStyleLarger().copyWith(
                    color: styleConfig().secondaryTextColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, DateTime.now());
                },
                child: Text(
                  localizations.journalDateNowButton,
                  style: buttonLabelStyleLarger(),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, dateTime);
                },
                child: Text(
                  localizations.doneButton,
                  style: buttonLabelStyleLarger().copyWith(
                    color: styleConfig().primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        CupertinoTheme(
          data: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: formLabelStyle().copyWith(
                fontSize: fontSizeLarge,
                color: styleConfig().primaryTextColor,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          child: SizedBox(
            height: 265,
            child: CupertinoDatePicker(
              initialDateTime: widget.initial,
              use24hFormat: true,
              onDateTimeChanged: (DateTime value) {
                dateTime = value;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DateTimeField extends StatefulWidget {
  const DateTimeField({
    required this.dateTime,
    required this.labelText,
    required this.setDateTime,
    this.style,
    super.key,
  });

  final DateTime dateTime;
  final String labelText;
  final void Function(DateTime) setDateTime;
  final TextStyle? style;

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: createDialogInputDecoration(
        labelText: widget.labelText,
        style: widget.style,
      ),
      style: widget.style,
      readOnly: true,
      controller: TextEditingController(
        text: dfShorter.format(widget.dateTime),
      ),
      onTap: () async {
        final newDateTime = await showModalBottomSheet<DateTime>(
          context: context,
          builder: (context) {
            return DateTimeBottomSheet(widget.dateTime);
          },
        );

        if (newDateTime != null) {
          widget.setDateTime(newDateTime);
        }
      },
    );
  }
}
