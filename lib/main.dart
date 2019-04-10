import 'package:flutter/cupertino.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool tracking = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Papierkram.de TimeTracker',
      theme: CupertinoThemeData(
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
              icon: Icon(CupertinoIcons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear_big),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.clock),
              title: Text('Buchungen'),
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CupertinoButton(
                          child: tracking ? Icon(CupertinoIcons.pause_solid) : Icon(CupertinoIcons.play_arrow_solid),
                          onPressed: () {
                            setState(() {
                              tracking = !tracking;
                            });
                          },
                          color: tracking ? Color.fromRGBO(218, 78, 73, 1) : Color.fromRGBO(91, 182, 91, 1),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                  );
                },
              );
            case 1:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: ListView(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoTextField(
                            clearButtonMode: OverlayVisibilityMode.editing,
                            placeholder: "Kunde/Projekt",
                            autocorrect: false,
                            maxLines: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoTextField(
                            clearButtonMode: OverlayVisibilityMode.editing,
                            placeholder: "Aufgabe",
                            autocorrect: false,
                            maxLines: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoTextField(
                            clearButtonMode: OverlayVisibilityMode.editing,
                            placeholder: "Kommentar",
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: <Widget>[
                              Icon(CupertinoIcons.car),
                              Text("heute"),
                              Icon(CupertinoIcons.time),
                              Text("22:01"),
                              Text("bis"),
                              Text("22:01"),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Text("00"),
                            Text(":"),
                            Text("00"),
                            Text(":"),
                            Text("00"),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton(
                                child:
                                    tracking ? Icon(CupertinoIcons.pause_solid) : Icon(CupertinoIcons.play_arrow_solid),
                                onPressed: () {
                                  setState(() {
                                    tracking = !tracking;
                                  });
                                },
                                color: tracking ? Color.fromRGBO(218, 78, 73, 1) : Color.fromRGBO(91, 182, 91, 1),
                              ),
                            ),
                          ],
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
                            onPressed: () {},
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            case 2:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: ListView(
                      children: <Widget>[],
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
