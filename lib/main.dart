import 'dart:async';

import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_easyrefresh/material_header.dart';
import 'package:flutter_typeahead/cupertino_flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/api.dart' as api;
import 'package:time_tracker/data.dart';

const Color green = Color.fromRGBO(91, 182, 91, 1);
const Color red = Color.fromRGBO(218, 78, 73, 1);

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
    if (state.project is StateProject) {
      _project.text = "${state.project.customer}: ${state.project.name}";
    } else {
      _project.text = "";
    }
    _task.text = state.task_name;
    _comment.text = state.comment;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Papierkram.de TimeTracker',
      theme: CupertinoThemeData(
        primaryColor: Color.fromRGBO(185, 213, 222, 1),
        primaryContrastingColor: Color.fromRGBO(0, 59, 78, 1),
        barBackgroundColor: Color.fromRGBO(0, 59, 78, 1),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
          ),
        ),
        scaffoldBackgroundColor: Color.fromRGBO(0, 102, 136, 1),
      ),
      home: state != null
          ? CupertinoTabScaffold(
              controller: _tabController,
              tabBar: CupertinoTabBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(
                      IconData(
                        0xF2FD,
                        fontFamily: CupertinoIcons.iconFont,
                        fontPackage: CupertinoIcons.iconFontPackage,
                        matchTextDirection: true,
                      ),
                    ),
                    title: Text('Tracken'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.pen),
                    title: Text('Zeiterfassung'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.clock),
                    title: Text('Buchungen'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.settings),
                    title: Text('Zugangsdaten'),
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
                                        state.project is StateProject
                                            ? "${state.project.customer}:"
                                                " ${state.project.name}"
                                            : "",
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
                          physics: ClampingScrollPhysics(),
                          children: <Widget>[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
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
                                      "${itemData.customer.name}: ${itemData.name}",
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
                                      ? [
                                          BoxShadow(color: Color.fromRGBO(209, 208, 203, 1)),
                                        ]
                                      : [],
                                  border: Border(
                                    top: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    bottom: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    left: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                    right: BorderSide(
                                      color: CupertinoColors.lightBackgroundGray,
                                      style: BorderStyle.solid,
                                      width: 0.0,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            IconData(
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
                                              child: Text(DateFormat("dd.MM.yyyy").format(state.getStartedAt())),
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
                                                            state.setPausedDuration(Duration());
                                                            state.setStartedAt(newDateTime);
                                                            if (!state.hasStoppedTime())
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
                                        ],
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            CupertinoIcons.time_solid,
                                            color: CupertinoColors.white,
                                          ),
                                          GestureDetector(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(DateFormat("HH:mm").format(state.getStartedAt())),
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
                                                            state.setPausedDuration(Duration());
                                                            state.setStartedAt(newDateTime);
                                                            if (!state.hasStoppedTime())
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
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text("bis"),
                                          ),
                                          GestureDetector(
                                            child: Text(DateFormat("HH:mm").format(state.getEndedAt())),
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
                                                            state.setPausedDuration(Duration());
                                                            if (!state.hasStartedTime())
                                                              state.setStartedAt(DateTime.now());
                                                            state.setStoppedAt(newDateTime);
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
                                child: Text("Buchen"),
                                onPressed: state.getStatus()
                                    ? null
                                    : () async {
                                        if (state.task_name.isNotEmpty) {
                                          await api.postTrackedTime(state);
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
                                child: Text("Verwerfen"),
                                onPressed: () {
                                  state.hasStartedTime() || state.hasStoppedTime()
                                      ? showCupertinoDialog(
                                          context: context,
                                          builder: (BuildContext context) => CupertinoAlertDialog(
                                            title: Icon(
                                              IconData(
                                                0xF3BC,
                                                fontFamily: CupertinoIcons.iconFont,
                                                fontPackage: CupertinoIcons.iconFontPackage,
                                                matchTextDirection: true,
                                              ),
                                              color: CupertinoTheme.of(context).primaryContrastingColor,
                                            ),
                                            content: Text("Wollen Sie die erfassten Zeiten wirklich verwerfen?"),
                                            actions: [
                                              CupertinoDialogAction(
                                                isDefaultAction: true,
                                                child: Text(
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
                                                child: Text(
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
                            physics: ClampingScrollPhysics(),
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
                    return Text("Something went wrong");
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
                IconData(
                  0xF3BC,
                  fontFamily: CupertinoIcons.iconFont,
                  fontPackage: CupertinoIcons.iconFontPackage,
                  matchTextDirection: true,
                ),
                color: CupertinoTheme.of(context).primaryContrastingColor,
              ),
              content: Text("Sollen die manuellen Änderungen zurückgesetzt werden?"),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(
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
                  child: Text(
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
          IconData(
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
            child: Text(
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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: CupertinoColors.lightBackgroundGray,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9.0),
          child: Row(
            children: <Widget>[
              Text(
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
          });
        },
      ));
    }

    for (Entry e in state.getTodaysEntries()) addRecentTaskWidget(e);

    widgets.add(Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: CupertinoColors.lightBackgroundGray,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Text(
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
  final Function _refresh;

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
      padding: EdgeInsets.all(10),
      child: ListView(
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
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
                  Text("Passwort anzeigen")
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoButton.filled(
              child: Text("Speichern"),
              onPressed: () async {
                if (widget._password.text.isNotEmpty) {
                  try {
                    await api.saveSettingsCheckToken(widget._company.text, widget._user.text, widget._password.text);
                    this.widget._refresh();
                  } catch (e) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) => CupertinoAlertDialog(
                        title: Text("Ein Fehler ist beim Login aufgetreten"),
                        content: Text(e.message),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: Text(
                              "Schließen",
                              style: TextStyle(color: CupertinoColors.destructiveRed),
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
  final Function onPressed;

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
              "${entry.customer_name}: ${entry.project_name}",
              textScaleFactor: 0.75,
              style: TextStyle(
                color: CupertinoColors.lightBackgroundGray,
              ),
            ),
            Row(
              children: <Widget>[
                Text(entry.task_name),
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
  final Function onPressed;
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
  Duration _d = Duration();
  Timer _t;

  _TrackingLabelState() {
    this._t = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _d = widget.state.getEndedAt().difference(widget.state.getStartedAt()) - widget.state.getPausedDuration();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      prettyDuration(
        _d,
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
