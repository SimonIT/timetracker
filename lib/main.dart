import 'dart:async';

import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_easyrefresh/material_header.dart';
import 'package:flutter_typeahead/cupertino_flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:timetracker/api.dart' as api;
import 'package:timetracker/data.dart';

import 'helpers.dart';

const Color green = Color.fromRGBO(91, 182, 91, 1);
const Color red = Color.fromRGBO(218, 78, 73, 1);
final DateFormat hoursSeconds = DateFormat("HH:mm");
final DateFormat dayMonthYear = DateFormat("dd.MM.yyyy");

void main() => runApp(TimeTrackerApp());

class TimeTrackerApp extends StatefulWidget {
  @override
  _TimeTrackerAppState createState() => _TimeTrackerAppState();
}

class _TimeTrackerAppState extends State<TimeTrackerApp> {
  TrackerState state;

  CupertinoTabController _tabController = CupertinoTabController();
  TextEditingController _project = TextEditingController();
  TextEditingController _task = TextEditingController();
  TextEditingController _comment = TextEditingController();
  TextEditingController _company = TextEditingController();
  TextEditingController _user = TextEditingController();
  TextEditingController _password = TextEditingController();
  CupertinoSuggestionsBoxController _projectSuggestion = CupertinoSuggestionsBoxController();
  FocusNode _projectFocus = FocusNode();
  FocusNode _taskFocus = FocusNode();
  FocusNode _commentFocus = FocusNode();

  _TimeTrackerAppState() {
    _refresh();
  }

  Future<void> _refresh() async {
    await api.authenticate();
    api.loadTrackerState().then((TrackerState state) {
      setState(() {
        this.state = state;
        if (state != null) updateInputs();
      });
    });
  }

  void updateInputs() {
    _project.text = state.project is StateProject ? state.project.title : "";
    _task.text = state.task_name;
    _comment.text = state.comment;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Papierkram.de TimeTracker',
      theme: const CupertinoThemeData(
        primaryColor: const Color.fromRGBO(185, 213, 222, 1),
        primaryContrastingColor: const Color.fromRGBO(0, 59, 78, 1),
        barBackgroundColor: const Color.fromRGBO(0, 59, 78, 1),
        textTheme: const CupertinoTextThemeData(
          textStyle: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
          ),
        ),
        scaffoldBackgroundColor: const Color.fromRGBO(0, 102, 136, 1),
      ),
      home: state != null
          ? CupertinoTabScaffold(
              controller: _tabController,
              tabBar: CupertinoTabBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: const Icon(
                      const IconData(
                        0xF2FD,
                        fontFamily: CupertinoIcons.iconFont,
                        fontPackage: CupertinoIcons.iconFontPackage,
                        matchTextDirection: true,
                      ),
                    ),
                    title: const Text('Tracken'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.pen),
                    title: const Text('Zeiterfassung'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.clock),
                    title: const Text('Buchungen'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.settings),
                    title: const Text('Zugangsdaten'),
                  ),
                ],
              ),
              tabBuilder: (BuildContext context, int index) {
                switch (index) {
                  case 0:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(state.task_name),
                                      Text(
                                        state.project is StateProject ? state.project.title : "",
                                      ),
                                    ],
                                  ),
                                ),
                                TrackingLabel(state),
                              ],
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            TrackingButton(
                              onPressed: () => track(context),
                              tracking: state.getStatus(),
                            ),
                          ],
                          mainAxisAlignment: MainAxisAlignment.center,
                        );
                      },
                    );
                  case 1:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return ListView(
                          physics: const ClampingScrollPhysics(),
                          children: <Widget>[
                            Center(
                              child: const Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const Text(
                                  "Zeiterfassung",
                                  textScaleFactor: 2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTypeAheadField(
                                suggestionsBoxController: _projectSuggestion,
                                textFieldConfiguration: CupertinoTextFieldConfiguration(
                                  enabled: state.project == null,
                                  controller: _project,
                                  focusNode: _projectFocus,
                                  autofocus: state.project == null,
                                  clearButtonMode: OverlayVisibilityMode.editing,
                                  placeholder: "Kunde/Projekt",
                                  autocorrect: false,
                                  maxLines: 1,
                                  style: state.project != null
                                      ? TextStyle(
                                          color: CupertinoTheme.of(context).primaryContrastingColor,
                                        )
                                      : null,
                                ),
                                itemBuilder: (BuildContext context, Project itemData) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      itemData.title,
                                      style: TextStyle(color: CupertinoTheme.of(context).primaryContrastingColor),
                                    ),
                                  );
                                },
                                onSuggestionSelected: (Project suggestion) {
                                  setState(() {
                                    state.setProject(suggestion);
                                    api.setTrackerState(state);
                                    updateInputs();
                                  });
                                  FocusScope.of(context).requestFocus(_taskFocus);
                                },
                                suggestionsCallback: (String pattern) async {
                                  List<Project> p = await api.loadProjects(searchPattern: pattern);
                                  if (p.length == 1) {
                                    _projectSuggestion.close();
                                    setState(() {
                                      state.setProject(p[0]);
                                      api.setTrackerState(state);
                                      updateInputs();
                                    });
                                    FocusScope.of(context).requestFocus(_taskFocus);
                                  }
                                  return p;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTextField(
                                controller: _task,
                                focusNode: _taskFocus,
                                autofocus: state.project != null && _task.text.isEmpty,
                                enabled: state.project != null,
                                placeholder: "Aufgabe",
                                autocorrect: false,
                                maxLines: 1,
                                onChanged: (String text) {
                                  state.task_name = text;
                                  api.setTrackerState(state);
                                },
                                style: state.project == null
                                    ? TextStyle(
                                        color: CupertinoTheme.of(context).primaryContrastingColor,
                                      )
                                    : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoTextField(
                                controller: _comment,
                                focusNode: _commentFocus,
                                autofocus: state.project != null && _task.text.isNotEmpty && _comment.text.isEmpty,
                                placeholder: "Kommentar",
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                onChanged: (String text) {
                                  state.comment = text;
                                  api.setTrackerState(state);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: state.getStatus()
                                      ? const [
                                          const BoxShadow(color: const Color.fromRGBO(209, 208, 203, 1)),
                                        ]
                                      : const [],
                                  border: const Border(
                                    top: const BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    bottom: const BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    left: const BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    right: const BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            const IconData(
                                              0xF2D1,
                                              fontFamily: CupertinoIcons.iconFont,
                                              fontPackage: CupertinoIcons.iconFontPackage,
                                              matchTextDirection: true,
                                            ),
                                            color: CupertinoColors.white,
                                          ),
                                          GestureDetector(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(dayMonthYear.format(state.getStartedAt())),
                                            ),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.date,
                                                        maximumDate: state.getEndedAt(),
                                                        initialDateTime: state.getStartedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(const Duration());
                                                            state.setStartedAt(
                                                                setDay(state.getStartedAt(), newDateTime));
                                                            state.setStoppedAt(
                                                                setDay(state.getStoppedAt(), newDateTime));
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            CupertinoIcons.time_solid,
                                            color: CupertinoColors.white,
                                          ),
                                          GestureDetector(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(hoursSeconds.format(state.getStartedAt())),
                                            ),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.time,
                                                        maximumDate: state.getEndedAt(),
                                                        initialDateTime: state.getStartedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(const Duration());
                                                            state.setStartedAt(newDateTime);
                                                            if (state.getStartedAt().isAfter(state.getStoppedAt()))
                                                              state.setStoppedAt(state.getStartedAt());
                                                            else if (!state.hasStoppedTime())
                                                              state.setStoppedAt(DateTime.now());
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          const Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: const Text("bis"),
                                          ),
                                          GestureDetector(
                                            child: Text(hoursSeconds.format(state.getEndedAt())),
                                            onTap: () {
                                              if (!state.getStatus()) {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _buildBottomPicker(
                                                      CupertinoDatePicker(
                                                        mode: CupertinoDatePickerMode.time,
                                                        minimumDate: state.getStartedAt(),
                                                        initialDateTime: state.getEndedAt(),
                                                        use24hFormat: true,
                                                        onDateTimeChanged: (DateTime newDateTime) {
                                                          setState(() {
                                                            state.setManualTimeChange(true);
                                                            state.setPausedDuration(const Duration());
                                                            state.setStoppedAt(newDateTime);
                                                            if (state.getStoppedAt().isBefore(state.getStartedAt()))
                                                              state.setStartedAt(state.getStoppedAt());
                                                            else if (!state.hasStartedTime())
                                                              state.setStartedAt(DateTime.now());
                                                            api.setTrackerState(state);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: <Widget>[
                                  TrackingLabel(state),
                                  TrackingButton(
                                    onPressed: () => track(context),
                                    tracking: state.getStatus(),
                                  ),
                                ],
                                mainAxisAlignment: MainAxisAlignment.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton.filled(
                                child: const Text("Buchen"),
                                disabledColor: Color.fromRGBO(91, 148, 222, 1),
                                onPressed: state.getStatus()
                                    ? null
                                    : () async {
                                        if (state.task_name.isNotEmpty) {
                                          try {
                                            await api.postTrackedTime(state);
                                          } catch (e) {
                                            showCupertinoDialog(
                                              context: context,
                                              builder: (BuildContext context) => CupertinoAlertDialog(
                                                title: const Text("Ein Fehler ist beim Buchen aufgetreten"),
                                                content: Text(e.message),
                                                actions: [
                                                  CupertinoDialogAction(
                                                    isDefaultAction: true,
                                                    child: const Text(
                                                      "Schließen",
                                                      style: const TextStyle(color: CupertinoColors.destructiveRed),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context, rootNavigator: true).pop("Cancel");
                                                    },
                                                  )
                                                ],
                                              ),
                                            );
                                          }
                                          state.empty();
                                          await api.setTrackerState(state);
                                          _refresh();
                                          FocusScope.of(context).requestFocus(_projectFocus);
                                        } else {
                                          showNoProjectDialog(context);
                                        }
                                      },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton.filled(
                                child: const Text("Verwerfen"),
                                onPressed: () {
                                  state.hasStartedTime() || state.hasStoppedTime()
                                      ? showCupertinoDialog(
                                          context: context,
                                          builder: (BuildContext context) => CupertinoAlertDialog(
                                            title: Icon(
                                              const IconData(
                                                0xF3BC,
                                                fontFamily: CupertinoIcons.iconFont,
                                                fontPackage: CupertinoIcons.iconFontPackage,
                                                matchTextDirection: true,
                                              ),
                                              color: CupertinoTheme.of(context).primaryContrastingColor,
                                            ),
                                            content: const Text("Wollen Sie die erfassten Zeiten wirklich verwerfen?"),
                                            actions: [
                                              CupertinoDialogAction(
                                                isDefaultAction: true,
                                                child: const Text(
                                                  "OK",
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context, rootNavigator: true).pop("OK");
                                                  setState(() {
                                                    state.empty();
                                                    api.setTrackerState(state);
                                                    updateInputs();
                                                  });
                                                },
                                              ),
                                              CupertinoDialogAction(
                                                isDefaultAction: true,
                                                child: const Text(
                                                  "Abbrechen",
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context, rootNavigator: true).pop("Abbrechen");
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      : setState(() {
                                          state.empty();
                                          api.setTrackerState(state);
                                          updateInputs();
                                        });
                                  FocusScope.of(context).requestFocus(_projectFocus);
                                },
                              ),
                            )
                          ],
                        );
                      },
                    );
                  case 2:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return EasyRefresh(
                          header: MaterialHeader(),
                          onRefresh: _refresh,
                          bottomBouncing: false,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                            ),
                            physics: const ClampingScrollPhysics(),
                            children: getEntryWidgets(),
                          ),
                        );
                      },
                    );
                  case 3:
                    return CupertinoTabView(
                      builder: (BuildContext context) {
                        return CredentialsPage(_company, _user, _password, _refresh);
                      },
                    );
                  default:
                    return const Text("Something went wrong");
                }
              },
            )
          : CupertinoPageScaffold(
              child: CredentialsPage(_company, _user, _password, _refresh),
            ),
    );
  }

  void track(BuildContext context) {
    setState(() {
      if (state.task_name.isNotEmpty) {
        if (state.getManualTimeChange()) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: Icon(
                const IconData(
                  0xF3BC,
                  fontFamily: CupertinoIcons.iconFont,
                  fontPackage: CupertinoIcons.iconFontPackage,
                  matchTextDirection: true,
                ),
                color: CupertinoTheme.of(context).primaryContrastingColor,
              ),
              content: const Text("Sollen die manuellen Änderungen zurückgesetzt werden?"),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    "OK",
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("OK");
                    state.setManualTimeChange(false);
                    track(context);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    "Abbrechen",
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Cancel");
                  },
                )
              ],
            ),
          );
        } else {
          state.setStatus(!state.getStatus());
          if (state.getStatus()) {
            if (!state.hasStartedTime()) {
              state.setStartedAt(DateTime.now());
              api.setTrackerState(state);
            } else {
              state.setPausedDuration(state.getPausedDuration() + DateTime.now().difference(state.getEndedAt()));
              state.stopped_at = "0";
              state.ended_at = "0";
              api.setTrackerState(state);
            }
          } else {
            state.setStoppedAt(DateTime.now());
            api.setTrackerState(state);
          }
        }
      } else {
        showNoProjectDialog(context);
      }
    });
  }

  void showNoProjectDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Icon(
          const IconData(
            0xF3BC,
            fontFamily: CupertinoIcons.iconFont,
            fontPackage: CupertinoIcons.iconFontPackage,
            matchTextDirection: true,
          ),
          color: CupertinoTheme.of(context).primaryContrastingColor,
        ),
        content: Text("Es wurde noch kein Projekt bzw. Task ausgewählt."),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              "OK",
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop("OK");
            },
          )
        ],
      ),
    );
  }

  List<Widget> getEntryWidgets() {
    List<Widget> widgets = [
      Container(
        decoration: const BoxDecoration(
          border: const Border(
            bottom: const BorderSide(
              width: 1,
              color: CupertinoColors.lightBackgroundGray,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9.0),
          child: Row(
            children: <Widget>[
              const Text(
                "Heute",
                textScaleFactor: 1.5,
              ),
              Text(
                prettyDuration(
                  state.getTrackedToday(),
                  abbreviated: true,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
      ),
    ];

    void addRecentTaskWidget(Entry e) {
      widgets.add(RecentTasks(
        entry: e,
        onPressed: () {
          setState(() {
            state.setToEntry(e);
            api.setTrackerState(state);
            updateInputs();
            _tabController.index = 1;
            FocusScope.of(context).requestFocus(_commentFocus);
          });
        },
      ));
    }

    for (Entry e in state.getTodaysEntries()) addRecentTaskWidget(e);

    widgets.add(Container(
      decoration: const BoxDecoration(
        border: const Border(
          bottom: const BorderSide(
            width: 1,
            color: CupertinoColors.lightBackgroundGray,
          ),
        ),
      ),
      child: const Padding(
        padding: const EdgeInsets.all(9.0),
        child: const Text(
          "Frühere Einträge",
          textScaleFactor: 1.5,
        ),
      ),
    ));

    for (Entry e in state.getPreviousEntries()) addRecentTaskWidget(e);

    return widgets;
  }
}

class CredentialsPage extends StatefulWidget {
  final TextEditingController _company;
  final TextEditingController _user;
  final TextEditingController _password;
  final Function() _refresh;

  CredentialsPage(this._company, this._user, this._password, this._refresh, {Key key}) : super(key: key) {
    api.loadCredentials().then((bool success) {
      if (success) {
        _company.text = api.authCompany;
        _user.text = api.authUsername;
      }
    });
  }

  @override
  _CredentialsPageState createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListView(
        physics: const ClampingScrollPhysics(),
        children: <Widget>[
          const Center(
            child: const Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "Ihre Papierkram.de Zugangsdaten",
                textScaleFactor: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: widget._company,
              placeholder: "Firmen ID",
              autocorrect: false,
              maxLines: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: widget._user,
              placeholder: "Nutzer",
              autocorrect: false,
              maxLines: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: widget._password,
              placeholder: "Passwort",
              autocorrect: false,
              maxLines: 1,
              obscureText: !showPassword,
              onChanged: (value) {
                setState(() {
                  // needed for show password button
                });
              },
            ),
          ),
          if (widget._password.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CupertinoSwitch(
                    onChanged: (bool value) {
                      setState(() {
                        showPassword = value;
                      });
                    },
                    value: showPassword,
                    activeColor: green,
                  ),
                  const Text("Passwort anzeigen")
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoButton.filled(
              child: const Text("Speichern"),
              onPressed: () async {
                if (widget._password.text.isNotEmpty) {
                  try {
                    await api.saveSettingsCheckToken(widget._company.text, widget._user.text, widget._password.text);
                    this.widget._refresh();
                  } catch (e) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) => CupertinoAlertDialog(
                        title: const Text("Ein Fehler ist beim Login aufgetreten"),
                        content: Text(e.message),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text(
                              "Schließen",
                              style: const TextStyle(color: CupertinoColors.destructiveRed),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop("Cancel");
                            },
                          )
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          )
        ],
      ),
    );
  }
}

class RecentTasks extends StatelessWidget {
  final Entry entry;
  final Function() onPressed;

  RecentTasks({
    @required this.entry,
    @required this.onPressed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              entry.title,
              textScaleFactor: 0.75,
              style: const TextStyle(
                color: CupertinoColors.lightBackgroundGray,
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(child: Text(entry.task_name)),
                Text(
                  prettyDuration(
                    Duration(
                      seconds: entry.task_duration,
                    ),
                    abbreviated: true,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            )
          ],
        ),
      ),
      behavior: HitTestBehavior.translucent,
      onTap: onPressed,
    );
  }
}

class TrackingButton extends StatelessWidget {
  final Function() onPressed;
  final bool tracking;

  const TrackingButton({
    @required this.onPressed,
    @required this.tracking,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CupertinoButton(
        child: tracking ? Icon(CupertinoIcons.pause_solid) : Icon(CupertinoIcons.play_arrow_solid),
        onPressed: onPressed,
        color: tracking ? red : green,
      ),
    );
  }
}

class TrackingLabel extends StatefulWidget {
  final TrackerState state;

  const TrackingLabel(this.state, {Key key}) : super(key: key);

  @override
  _TrackingLabelState createState() => _TrackingLabelState();
}

class _TrackingLabelState extends State<TrackingLabel> {
  Timer _t;

  _TrackingLabelState() {
    this._t = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (widget.state.getStatus()) setState(() {});
    });
  }

  Duration get duration =>
      widget.state.getEndedAt().difference(widget.state.getStartedAt()) - widget.state.getPausedDuration();

  @override
  Widget build(BuildContext context) {
    return Text(
      prettyDuration(
        duration,
        abbreviated: true,
      ),
      textScaleFactor: 1.5,
    );
  }

  @override
  void dispose() {
    this._t.cancel();
    super.dispose();
  }
}

Widget _buildBottomPicker(Widget picker) {
  return Container(
    height: 216.0,
    padding: const EdgeInsets.only(top: 6.0),
    color: CupertinoColors.white,
    child: DefaultTextStyle(
      style: const TextStyle(
        color: CupertinoColors.black,
        fontSize: 22.0,
      ),
      child: GestureDetector(
        onTap: () {},
        child: SafeArea(
          top: false,
          child: picker,
        ),
      ),
    ),
  );
}
