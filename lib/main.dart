import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:time_tracker/api.dart' as api;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool tracking = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  TextEditingController _project = TextEditingController();
  TextEditingController _task = TextEditingController();
  TextEditingController _comment = TextEditingController();
  TextEditingController _company = TextEditingController();
  TextEditingController _user = TextEditingController();
  TextEditingController _password = TextEditingController();

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
                              children: <Widget>[
                                Text(
                                  'Aufgabe',
                                ),
                                Text(
                                  "Projekt",
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "0m",
                            textScaleFactor: 2,
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      TrackingButton(
                        onPressed: () {
                          setState(() {
                            this.tracking = !this.tracking;
                            if (tracking) {
                              _startDate = DateTime.now();
                            } else {
                              _endDate = DateTime.now();
                            }
                          });
                        },
                        tracking: this.tracking,
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoTextField(
                          controller: _comment,
                          placeholder: "Kommentar",
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
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
                                                  setState(() => _startDate = newDateTime);
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
                                                  setState(() => _startDate = newDateTime);
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
                                                  setState(() => _endDate = newDateTime);
                                                  print(_endDate.difference(_startDate));
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
                              "00:00:00",
                              textScaleFactor: 1.5,
                            ),
                            TrackingButton(
                              onPressed: () {
                                setState(() {
                                  this.tracking = !this.tracking;
                                  if (tracking) {
                                    _startDate = DateTime.now();
                                  } else {
                                    _endDate = DateTime.now();
                                  }
                                });
                              },
                              tracking: this.tracking,
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
                    child: ListView(
                      physics: ClampingScrollPhysics(),
                      children: <Widget>[
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
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
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
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                        Booking(
                          onPressed: () {
                            _project.text = "IteaSoft: Intern";
                            _task.text = "Customer Desk";
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            case 3:
              return CupertinoTabView(
                builder: (BuildContext context) {
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
                              api.saveSettingsCheckToken(_company.text, _user.text, _password.text);
                            },
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class Booking extends StatelessWidget {
  final Function onPressed;

  const Booking({
    Key key,
    @required this.onPressed,
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
                  "IteaSoft: Intern",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                    color: CupertinoColors.lightBackgroundGray,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text("Customer Desk"),
                Text("2:53h"),
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
    Key key,
    @required this.onPressed,
    @required this.tracking,
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
