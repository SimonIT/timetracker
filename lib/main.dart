import 'dart:async';

import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_typeahead/cupertino_flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/api.dart' as api;
import 'package:time_tracker/data.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DateTime _startDate;
  DateTime _endDate;
  Duration _paused = Duration();

  TrackerState state;
  Project currentProject;

  TextEditingController _project = TextEditingController();
  TextEditingController _task = TextEditingController();
  TextEditingController _comment = TextEditingController();
  TextEditingController _company = TextEditingController();
  TextEditingController _user = TextEditingController();
  TextEditingController _password = TextEditingController();

  _MyAppState() {
    _refresh();
  }

  void _refresh() async {
    await api.authenticate();
    api.loadTrackerState().then((TrackerState state) {
      if (state != null) {
        setState(() {
          this.state = state;
          updateInputs();
          int startedMillis = int.parse(state.started_at);
          _startDate = startedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(startedMillis) : null;
          int endedMillis = int.parse(state.ended_at);
          _endDate = endedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(endedMillis) : null;
          _paused =
              state.paused_duration != null ? Duration(milliseconds: int.parse(state.paused_duration)) : Duration();
        });
      }
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
      home: CupertinoTabScaffold(
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
                                Text(
                                  state != null ? state.task_name : "",
                                ),
                                Text(
                                  state != null && state.project is StateProject
                                      ? "${state.project.customer}:"
                                          " ${state.project.name}"
                                      : "",
                                ),
                              ],
                            ),
                          ),
                          TrackingLabel(state, _startDate, _endDate, _paused),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      TrackingButton(
                        onPressed: () {
                          setState(() {
                            if (state != null) {
                              state.setTracking(!state.isTracking());
                              if (state.isTracking()) {
                                if (_startDate == null) {
                                  _startDate = DateTime.now();
                                } else {
                                  _paused += DateTime.now().difference(_endDate);
                                }
                                _endDate = null;
                              } else {
                                _endDate = DateTime.now();
                              }
                            }
                          });
                        },
                        tracking: state != null ? state.isTracking() : false,
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
                          textFieldConfiguration: CupertinoTextFieldConfiguration(
                            enabled: state == null ? true : state.project == null,
                            controller: _project,
                            clearButtonMode: OverlayVisibilityMode.editing,
                            placeholder: "Kunde/Projekt",
                            autocorrect: false,
                            maxLines: 1,
                          ),
                          itemBuilder: (BuildContext context, Project itemData) {
                            return Container(
                              child: Container(
                                color: CupertinoTheme.of(context).primaryColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    "${itemData.customer.name}: ${itemData.name}",
                                    style: TextStyle(color: CupertinoColors.black),
                                  ),
                                ),
                              ),
                            );
                          },
                          onSuggestionSelected: (Project suggestion) {
                            if (state != null) {
                              setState(() {
                                if (state.project == null) state.project = StateProject();
                                state.project.id = suggestion.id.toString();
                                state.project.name = suggestion.name;
                                state.project.customer = suggestion.customer.name;
                                updateInputs();
                              });
                            }
                          },
                          suggestionsCallback: (String pattern) async {
                            return await api.loadProjects(searchPattern: pattern);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoTextField(
                          controller: _task,
                          placeholder: "Aufgabe",
                          autocorrect: false,
                          maxLines: 1,
                          onChanged: (String text) {
                            if (state == null) state = TrackerState();
                            state.task_name = text;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoTextField(
                          controller: _comment,
                          placeholder: "Kommentar",
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (String text) {
                            if (state == null) state = TrackerState();
                            state.comment = text;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: state != null && state.isTracking()
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
                                        child: Text(
                                            _startDate != null ? DateFormat("dd.MM.yyyy").format(_startDate) : "heute"),
                                      ),
                                      onTap: () {
                                        if (state != null && !state.isTracking()) {
                                          showCupertinoModalPopup<void>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return _buildBottomPicker(
                                                CupertinoDatePicker(
                                                  mode: CupertinoDatePickerMode.date,
                                                  initialDateTime: _startDate != null ? _startDate : DateTime.now(),
                                                  use24hFormat: true,
                                                  onDateTimeChanged: (DateTime newDateTime) {
                                                    setState(() {
                                                      _startDate = newDateTime;
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
                                        child:
                                            Text(_startDate != null ? DateFormat("HH:mm").format(_startDate) : "00:00"),
                                      ),
                                      onTap: () {
                                        if (state != null && !state.isTracking()) {
                                          showCupertinoModalPopup<void>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return _buildBottomPicker(
                                                CupertinoDatePicker(
                                                  mode: CupertinoDatePickerMode.time,
                                                  initialDateTime: _startDate != null ? _startDate : DateTime.now(),
                                                  use24hFormat: true,
                                                  onDateTimeChanged: (DateTime newDateTime) {
                                                    setState(() {
                                                      _startDate = newDateTime;
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
                                      child: Text(_endDate != null ? DateFormat("HH:mm").format(_endDate) : "00:00"),
                                      onTap: () {
                                        if (state != null && !state.isTracking()) {
                                          showCupertinoModalPopup<void>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return _buildBottomPicker(
                                                CupertinoDatePicker(
                                                  mode: CupertinoDatePickerMode.time,
                                                  minimumDate: _startDate != null ? _startDate : DateTime.now(),
                                                  initialDateTime: _endDate != null ? _endDate : DateTime.now(),
                                                  use24hFormat: true,
                                                  onDateTimeChanged: (DateTime newDateTime) {
                                                    setState(() {
                                                      _endDate = newDateTime;
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
                            TrackingLabel(state, _startDate, _endDate, _paused),
                            TrackingButton(
                              onPressed: () {
                                setState(() {
                                  if (state != null) {
                                    state.setTracking(!state.isTracking());
                                    if (state.isTracking()) {
                                      if (_startDate == null) {
                                        _startDate = DateTime.now();
                                      } else {
                                        _paused += DateTime.now().difference(_endDate);
                                      }
                                      _endDate = null;
                                    } else {
                                      _endDate = DateTime.now();
                                    }
                                  }
                                });
                              },
                              tracking: state != null ? state.isTracking() : false,
                            ),
                          ],
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoButton.filled(
                          child: Text("Buchen"),
                          onPressed: () {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoButton.filled(
                          child: Text("Verwerfen"),
                          onPressed: () {
                            setState(() {
                              state.project = null;
                              state.task_name = "";
                              state.comment = "";
                              _startDate = null;
                              _endDate = null;
                              _paused = Duration();
                              updateInputs();
                            });
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    child: ListView.builder(
                      physics: ClampingScrollPhysics(),
                      /*children: <Widget>[
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
                                    Text("19m"),
                                  ],
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                ),
                              ),
                            ),
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
                                child: Text(
                                  "Frühere Einträge",
                                  textScaleFactor: 1.5,
                                ),
                              ),
                            ),
                          ],*/
                      itemBuilder: (BuildContext context, int index) {
                        if (state != null) {
                          Entry recent = state.recent_entries[index];
                          return RecentTasks(
                            customer: recent.customer_name,
                            project: recent.project_name,
                            task: recent.task_name,
                            duration: recent.task_duration,
                            onPressed: () {
                              setState(() {
                                if (state.project == null) {
                                  state.project = StateProject();
                                }
                                state.project.id = recent.id.toString();
                                state.project.name = recent.project_name;
                                state.project.customer = recent.customer_name;
                                state.task_name = recent.task_name;
                                updateInputs();
                              });
                            },
                          );
                        } else {
                          return Container();
                        }
                      },
                      itemCount: state != null ? state.recent_entries.length : 0,
                    ),
                  );
                },
              );
            case 3:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return FutureBuilder(
                      future: api.loadCredentials(),
                      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData && snapshot.data) {
                          _company.text = api.authCompany;
                          _user.text = api.authUsername;
                        }
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
                                  controller: _company,
                                  placeholder: "Firmen ID",
                                  autocorrect: false,
                                  maxLines: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: CupertinoTextField(
                                  controller: _user,
                                  placeholder: "Nutzer",
                                  autocorrect: false,
                                  maxLines: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: CupertinoTextField(
                                  controller: _password,
                                  placeholder: "Passwort",
                                  autocorrect: false,
                                  maxLines: 1,
                                  obscureText: true,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: CupertinoButton.filled(
                                  child: Text("Speichern"),
                                  onPressed: () {
                                    if (_password.text.isNotEmpty) {
                                      api.saveSettingsCheckToken(_company.text, _user.text, _password.text);
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        );
                      });
                },
              );
          }
        },
      ),
    );
  }
}

class RecentTasks extends StatelessWidget {
  final String customer;
  final String project;
  final String task;
  final int duration;
  final Function onPressed;

  RecentTasks({
    @required this.customer,
    @required this.project,
    @required this.task,
    @required this.duration,
    @required this.onPressed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  "$customer: $project",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                    color: CupertinoColors.lightBackgroundGray,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(task),
                Text(
                  prettyDuration(
                    Duration(
                      seconds: duration,
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
        color: tracking ? Color.fromRGBO(218, 78, 73, 1) : Color.fromRGBO(91, 182, 91, 1),
      ),
    );
  }
}

class TrackingLabel extends StatefulWidget {
  final TrackerState state;
  final DateTime _startDate;
  final DateTime _endDate;
  final Duration _paused;

  const TrackingLabel(this.state, this._startDate, this._endDate, this._paused, {Key key}) : super(key: key);

  @override
  _TrackingLabelState createState() => _TrackingLabelState();
}

class _TrackingLabelState extends State<TrackingLabel> {
  Duration d = Duration();

  _TrackingLabelState() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (widget._startDate != null) {
        setState(() {
          if (widget.state != null && widget.state.isTracking()) {
            d = DateTime.now().difference(widget._startDate) - widget._paused;
          } else {
            if (widget._endDate != null) {
              d = widget._endDate.difference(widget._startDate) - widget._paused;
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      prettyDuration(
        d,
        abbreviated: true,
      ),
      textScaleFactor: 1.5,
    );
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
