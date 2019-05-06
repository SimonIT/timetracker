import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/api.dart' as api;
import 'package:time_tracker/data.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool userChange = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
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
      setState(() {
        this.state = state;
        if (state.project is StateProject) {
          _project.text = "${state.project.customer}: ${state.project.name}";
        }
        _task.text = state.task_name;
        _comment.text = state.comment;
        int startedMillis = int.parse(state.started_at);
        _startDate = startedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(startedMillis) : DateTime.now();
        int endedMillis = int.parse(state.ended_at);
        _endDate = endedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(endedMillis) : DateTime.now();
        _paused = state.paused_duration != null ? Duration(milliseconds: int.parse(state.paused_duration)) : Duration();
      });
    });
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
              title:  Text('Zeiterfassung'),
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
                          Text(
                            prettyDuration(
                              _endDate.difference(_startDate) - _paused,
                              abbreviated: true,
                            ),
                            textScaleFactor: 2,
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      TrackingButton(
                        onPressed: () {
                          setState(() {
                            this.userChange = true;
                            state.setTracking(!state.isTracking());
                            if (state.isTracking()) {
                              _startDate = DateTime.now();
                            } else {
                              _endDate = DateTime.now();
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
                        child: CupertinoTextField(
                          controller: _project,
                          clearButtonMode: OverlayVisibilityMode.editing,
                          placeholder: "Kunde/Projekt",
                          autocorrect: false,
                          maxLines: 1,
                          onChanged: (String text) {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoTextField(
                          controller: _task,
                          placeholder: "Aufgabe",
                          autocorrect: false,
                          maxLines: 1,
                          onChanged: (String s) {
                            userChange = true;
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
                          onChanged: (String s) {
                            userChange = true;
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
                                        child: Text(DateFormat("dd.MM.yyyy").format(_startDate)),
                                      ),
                                      onTap: () {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode.date,
                                                initialDateTime: _startDate,
                                                use24hFormat: true,
                                                onDateTimeChanged: (DateTime newDateTime) {
                                                  setState(() {
                                                    userChange = true;
                                                    _startDate = newDateTime;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        );
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
                                        child: Text(DateFormat("HH:mm").format(_startDate)),
                                      ),
                                      onTap: () {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode.time,
                                                initialDateTime: _startDate,
                                                use24hFormat: true,
                                                onDateTimeChanged: (DateTime newDateTime) {
                                                  setState(() {
                                                    userChange = true;
                                                    _startDate = newDateTime;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text("bis"),
                                    ),
                                    GestureDetector(
                                      child: Text(DateFormat("HH:mm").format(_endDate)),
                                      onTap: () {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode.time,
                                                minimumDate: _startDate,
                                                initialDateTime: _endDate,
                                                use24hFormat: true,
                                                onDateTimeChanged: (DateTime newDateTime) {
                                                  setState(() {
                                                    userChange = true;
                                                    _endDate = newDateTime;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        );
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
                            Text(
                              prettyDuration(
                                _endDate.difference(_startDate) - _paused,
                                abbreviated: true,
                              ),
                              textScaleFactor: 1.5,
                            ),
                            TrackingButton(
                              onPressed: () {
                                setState(() {
                                  this.userChange = true;
                                  if (state != null) {
                                    state.setTracking(!state.isTracking());
                                    if (state.isTracking()) {
                                      _startDate = DateTime.now();
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
                              _project.clear();
                              _task.clear();
                              _comment.clear();
                              _startDate = DateTime.now();
                              _endDate = DateTime.now();
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
                              _project.text = recent.project_name;
                              _task.text = recent.task_name;
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
