import 'dart:async';
import 'dart:io';

import 'package:app_review/app_review.dart';
import 'package:duration/duration.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetracker/api.dart' as api;
import 'package:timetracker/data.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helpers.dart';

const Color green = Color.fromRGBO(91, 182, 91, 1);
const Color red = Color.fromRGBO(218, 78, 73, 1);
const Color deactivatedGray = Color.fromRGBO(209, 208, 203, 1);
const BorderSide inputBorder = BorderSide(
  color: CupertinoColors.lightBackgroundGray,
  width: 0.0,
);
const BoxDecoration rowDecorationBreak = BoxDecoration(
  border: Border(
    bottom: BorderSide(
      color: CupertinoColors.lightBackgroundGray,
      width: 0.5,
    ),
  ),
);
const BoxDecoration rowDecorationNewDay = BoxDecoration(
  border: Border(
    bottom: BorderSide(
      color: CupertinoColors.lightBackgroundGray,
      width: 2,
    ),
  ),
);
const BoxDecoration rowHeading = const BoxDecoration(
  border: const Border(
    bottom: const BorderSide(
      width: 3,
      color: CupertinoColors.lightBackgroundGray,
    ),
  ),
);
const String setTrackerError =
    "Ein Fehler ist beim Setzen des Status vom TimeTracker aufgetreten";
final DateFormat hoursSeconds = DateFormat("HH:mm");
final DateFormat dayMonthYear = DateFormat("dd.MM.yyyy");
final DateFormat dayMonth = DateFormat("dd.MM.");
final RegExp iapAppNameFilter = RegExp(r'( \(.+?\))$', caseSensitive: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    // For play billing library 2.0 on Android, it is mandatory to call
    // [enablePendingPurchases](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.Builder.html#enablependingpurchases)
    // as part of initializing the app.
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  }
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://c9029712547649df9379dd4f6df680bd@o407859.ingest.sentry.io/5281403';
    },
    appRunner: () => runApp(App()),
  );
}

class App extends StatelessWidget {
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
      home: CredentialsPage(),
    );
  }
}

class TimeTracker extends StatefulWidget {
  final TrackerState state;

  TimeTracker({@required this.state});

  @override
  _TimeTrackerState createState() => _TimeTrackerState(state: state);
}

class _TimeTrackerState extends State<TimeTracker> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  TrackerState state;

  CupertinoTabController _tabController = CupertinoTabController();
  TextEditingController _project = TextEditingController();
  TextEditingController _task = TextEditingController();
  TextEditingController _comment = TextEditingController();
  CupertinoSuggestionsBoxController _projectSuggestion =
      CupertinoSuggestionsBoxController();
  FocusNode _projectFocus = FocusNode();
  FocusNode _taskFocus = FocusNode();
  FocusNode _commentFocus = FocusNode();

  Timer _t;
  bool highlightBreaks = false;
  bool taskSuggestions = false;
  SharedPreferences prefs;
  List<ProductDetails> products;

  _TimeTrackerState({@required this.state}) {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      this.prefs = prefs;
      this.highlightBreaks = prefs.getBool("highlightBreaks") ?? false;
      this.taskSuggestions = prefs.getBool("taskSuggestions") ?? false;
      int appLaunches = prefs.getInt("appLaunches") ?? 0;
      if (appLaunches > 4) {
        Future.delayed(
          const Duration(seconds: 10),
          () => showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: const Text("Dir gefällt der TimeTracker?"),
              content: const Text("Dann zeig es mir!"),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text("Ich lasse eine Bewertung da ⭐"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Rate");
                    AppReview.writeReview;
                  },
                ),
                CupertinoDialogAction(
                  child: const Text("Ich kaufe dir etwas 🛒"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Buy");
                    _tabController.index = 3;
                  },
                ),
                CupertinoDialogAction(
                  child: const Text("Alles erledigt 🎉"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Cancel");
                    prefs.setInt("appLaunches", -1);
                  },
                ),
              ],
            ),
          ),
        );
      } else if (appLaunches > -1) {
        prefs.setInt("appLaunches", ++appLaunches);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    updateInputs();
    _inAppPurchase.isAvailable().then((bool available) {
      if (available)
        _inAppPurchase.queryProductDetails({
          'developer_limonade_once',
          'developer_buns_weekly',
          'developer_cinema_monthly',
        }).then((ProductDetailsResponse response) =>
            setState(() => this.products = response.productDetails));
    });
    this._t = Timer.periodic(
      const Duration(minutes: 5),
      (Timer timer) => _refresh(context),
    );
  }

  @override
  void dispose() {
    this._t.cancel();
    super.dispose();
  }

  Future<void> _refresh(BuildContext context) async {
    try {
      await api.authenticate();
      api.loadTrackerState().then((TrackerState state) {
        this.state = state;
        updateInputs();
      });
    } catch (e) {
      Navigator.of(context, rootNavigator: true)
          .pushReplacement(CupertinoPageRoute(
        builder: (BuildContext context) => CredentialsPage(),
      ))
          .whenComplete(() {
        state = null;
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title:
                const Text("Ein Fehler ist beim Authentifizieren aufgetreten"),
            content: Text(e.message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                isDestructiveAction: true,
                child: const Text("Schließen"),
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop("Cancel"),
              )
            ],
          ),
        );
      });
    }
  }

  void updateInputs() => setState(() {
        _project.text =
            state.project is StateProject ? state.project.title : "";
        _task.text = state.task_name;
        _comment.text = state.comment;
      });

  Future<dynamic> catchError(Future<dynamic> future, {String title}) {
    return future.catchError((Object e) {
      Sentry.captureException(
        e,
        stackTrace: e is Error ? e.stackTrace : null,
      );
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(title ?? "Ein Fehler ist aufgetreten"),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              isDestructiveAction: true,
              child: const Text("Schließen"),
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop("Cancel"),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.timer),
            label: 'Tracken',
          ),
          const BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.pen),
            label: 'Zeiterfassung',
          ),
          const BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.clock),
            label: 'Buchungen',
          ),
          const BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            label: 'Zugangsdaten',
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
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width / 2,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(state.task_name),
                                Text(
                                  state.project?.title ?? "",
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
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
                          style: DefaultTextStyle.of(context).style.copyWith(
                                color: CupertinoTheme.of(context)
                                    .primaryContrastingColor,
                              ),
                        ),
                        hideOnEmpty: true,
                        noItemsFoundBuilder: (BuildContext context) =>
                            Container(),
                        keepSuggestionsOnLoading: true,
                        suggestionsBoxVerticalOffset: 0,
                        itemBuilder: (BuildContext context, Project itemData) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              itemData.title,
                              style: TextStyle(
                                color: CupertinoTheme.of(context)
                                    .primaryContrastingColor,
                              ),
                            ),
                          );
                        },
                        onSuggestionSelected: (Project suggestion) {
                          state.setProject(suggestion);
                          catchError(
                            api.setTrackerState(state),
                            title: setTrackerError,
                          );
                          updateInputs();
                          FocusScope.of(context).requestFocus(_taskFocus);
                        },
                        suggestionsCallback: (String pattern) async {
                          List<Project> p =
                              await api.loadProjects(searchPattern: pattern);
                          if (p.length == 1) {
                            state.setProject(p[0]);
                            catchError(
                              api.setTrackerState(state),
                              title: setTrackerError,
                            );
                            updateInputs();
                            FocusScope.of(context).requestFocus(_taskFocus);
                            return <Project>[];
                          }
                          return p;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CupertinoTypeAheadField(
                        textFieldConfiguration: CupertinoTextFieldConfiguration(
                          controller: _task,
                          focusNode: _taskFocus,
                          autofocus:
                              state.project != null && _task.text.isEmpty,
                          enabled: state.project != null,
                          placeholder: "Aufgabe",
                          autocorrect: false,
                          maxLines: 1,
                          onChanged: (String text) {
                            state.task_name = text;
                            catchError(
                              api.setTrackerState(state),
                              title: setTrackerError,
                            );
                          },
                          style: DefaultTextStyle.of(context).style.copyWith(
                                color: CupertinoTheme.of(context)
                                    .primaryContrastingColor,
                              ),
                        ),
                        hideOnEmpty: true,
                        noItemsFoundBuilder: (BuildContext context) =>
                            Container(),
                        onSuggestionSelected: (String suggestion) {
                          state.task_name = suggestion;
                          catchError(
                            api.setTrackerState(state),
                            title: setTrackerError,
                          );
                          updateInputs();
                        },
                        suggestionsCallback: (String pattern) async {
                          if (!taskSuggestions) return <String>[];
                          return (await api.loadTasks())
                              .where((Task t) =>
                                  state.project.id == t.project_id.toString())
                              .map((Task t) => t.name)
                              .toSet()
                              .where((String t) => t
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                        },
                        keepSuggestionsOnLoading: true,
                        suggestionsBoxVerticalOffset: 0,
                        itemBuilder: (BuildContext context, String task) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              task,
                              style: TextStyle(
                                  color: CupertinoTheme.of(context)
                                      .primaryContrastingColor),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CupertinoTextField(
                        controller: _comment,
                        focusNode: _commentFocus,
                        autofocus: state.project != null &&
                            _task.text.isNotEmpty &&
                            _comment.text.isEmpty,
                        placeholder: "Kommentar",
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        onChanged: (String text) {
                          state.comment = text;
                          catchError(
                            api.setTrackerState(state),
                            title: setTrackerError,
                          );
                        },
                        style: TextStyle(
                          color: CupertinoTheme.of(context)
                              .primaryContrastingColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: state.getStatus()
                              ? const [
                                  const BoxShadow(color: deactivatedGray),
                                ]
                              : const [],
                          border: const Border(
                            top: inputBorder,
                            bottom: inputBorder,
                            left: inputBorder,
                            right: inputBorder,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4.0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    color: CupertinoColors.white,
                                  ),
                                  GestureDetector(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(dayMonthYear
                                          .format(state.getStartedAt())),
                                    ),
                                    onTap: () {
                                      if (!state.getStatus()) {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode
                                                    .date,
                                                initialDateTime:
                                                    state.getStartedAt(),
                                                maximumDate: state.getEndedAt(),
                                                use24hFormat: true,
                                                onDateTimeChanged:
                                                    (DateTime newDateTime) {
                                                  setState(() {
                                                    state.setManualTimeChange(
                                                        true);
                                                    state.setPausedDuration(
                                                        const Duration());
                                                    state.setStartedAt(setDay(
                                                        state.getStartedAt(),
                                                        newDateTime));
                                                    state.setStoppedAt(setDay(
                                                        state.getStoppedAt(),
                                                        newDateTime));
                                                    catchError(
                                                      api.setTrackerState(
                                                          state),
                                                      title: setTrackerError,
                                                    );
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
                                    CupertinoIcons.time,
                                    color: CupertinoColors.white,
                                  ),
                                  GestureDetector(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(hoursSeconds
                                          .format(state.getStartedAt())),
                                    ),
                                    onTap: () {
                                      if (!state.getStatus()) {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode
                                                    .time,
                                                initialDateTime:
                                                    state.getStartedAt(),
                                                use24hFormat: true,
                                                onDateTimeChanged:
                                                    (DateTime newDateTime) {
                                                  setState(() {
                                                    state.setManualTimeChange(
                                                        true);
                                                    state.setPausedDuration(
                                                        const Duration());
                                                    state.setStartedAt(
                                                        newDateTime);
                                                    if (state
                                                        .getStartedAt()
                                                        .isAfter(state
                                                            .getStoppedAt()))
                                                      state.setStoppedAt(
                                                          state.getStartedAt());
                                                    else if (!state
                                                        .hasStoppedTime())
                                                      state.setStoppedAt(
                                                          DateTime.now());
                                                    catchError(
                                                      api.setTrackerState(
                                                          state),
                                                      title: setTrackerError,
                                                    );
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: const Text("bis"),
                                  ),
                                  GestureDetector(
                                    child: Text(hoursSeconds
                                        .format(state.getEndedAt())),
                                    onTap: () {
                                      if (!state.getStatus()) {
                                        showCupertinoModalPopup<void>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _buildBottomPicker(
                                              CupertinoDatePicker(
                                                mode: CupertinoDatePickerMode
                                                    .time,
                                                initialDateTime:
                                                    state.getEndedAt(),
                                                use24hFormat: true,
                                                onDateTimeChanged:
                                                    (DateTime newDateTime) {
                                                  setState(() {
                                                    state.setManualTimeChange(
                                                        true);
                                                    state.setPausedDuration(
                                                        const Duration());
                                                    state.setStoppedAt(
                                                        newDateTime);
                                                    if (state
                                                        .getStoppedAt()
                                                        .isBefore(state
                                                            .getStartedAt()))
                                                      state.setStartedAt(
                                                          state.getStoppedAt());
                                                    else if (!state
                                                        .hasStartedTime())
                                                      state.setStartedAt(
                                                          DateTime.now());
                                                    catchError(
                                                      api.setTrackerState(
                                                          state),
                                                      title: setTrackerError,
                                                    );
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
                          CupertinoSwitch(
                            value: !state.getUnbillable(),
                            onChanged: (bool newVal) {
                              setState(() {
                                state.setUnbillable(!newVal);
                                catchError(
                                  api.setTrackerState(state),
                                  title: setTrackerError,
                                );
                              });
                            },
                          ),
                          Text("Abrechenbar?"),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
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
                        disabledColor: deactivatedGray,
                        onPressed: state.getStatus()
                            ? null
                            : () async {
                                if (state.task_name.isNotEmpty) {
                                  try {
                                    await api.postTrackedTime(state);
                                  } catch (e) {
                                    await Sentry.captureException(
                                      e,
                                      stackTrace:
                                          e is Error ? e.stackTrace : null,
                                    );
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                        title: const Text(
                                          "Ein Fehler ist beim Buchen aufgetreten",
                                        ),
                                        content: Text(e.toString()),
                                        actions: [
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            isDestructiveAction: true,
                                            child: const Text("Schließen"),
                                            onPressed: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop("Cancel");
                                            },
                                          )
                                        ],
                                      ),
                                    );
                                  }
                                  state.empty();
                                  await catchError(
                                    api.setTrackerState(state),
                                    title: setTrackerError,
                                  );
                                  _refresh(context);
                                  FocusScope.of(context)
                                      .requestFocus(_projectFocus);
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
                          showDialogWithCondition(
                            context,
                            (state.hasStartedTime() ||
                                    state.hasStoppedTime()) &&
                                state.getStartedAt() != state.getStoppedAt(),
                            "Wollen Sie die erfassten Zeiten wirklich verwerfen?",
                            () {
                              state.empty();
                              catchError(
                                api.setTrackerState(state),
                                title: setTrackerError,
                              );
                              updateInputs();
                            },
                          );
                          FocusScope.of(context).requestFocus(_projectFocus);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          case 2:
            return CupertinoTabView(
              builder: (BuildContext context) {
                return EasyRefresh(
                  header: MaterialHeader(),
                  onRefresh: () => _refresh(context),
                  bottomBouncing: false,
                  child: CupertinoScrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      physics: const ClampingScrollPhysics(),
                      children: [
                        getRecentEntryTable(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoButton.filled(
                            child: Text(
                              "Dokument hochladen \n (Experimentell)",
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () {
                              FilePicker.platform
                                  .pickFiles()
                                  .then((FilePickerResult result) {
                                if (result != null) {
                                  File file = File(result.files.single.path);
                                  catchError(
                                    api
                                        .uploadDocument(file)
                                        .then((String link) {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            CupertinoAlertDialog(
                                          title: const Text(
                                              "Das Dokument wurde erfolgreich hochgeladen"),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text("Öffnen"),
                                              onPressed: () =>
                                                  OpenFile.open(file.path),
                                            ),
                                            CupertinoDialogAction(
                                              child: const Text(
                                                  "Öffne im Browser"),
                                              onPressed: () => launch(link),
                                            ),
                                            CupertinoDialogAction(
                                              isDestructiveAction: true,
                                              isDefaultAction: true,
                                              child: const Text("Schließen"),
                                              onPressed: () => Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop("Cancel"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    title:
                                        "Ein Fehler ist beim Hochladen aufgetreten",
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          case 3:
            return CupertinoTabView(
              builder: (BuildContext context) {
                List<Widget> cs = [
                  CSHeader('Ihre Papierkram.de Zugangsdaten'),
                  CSControl(
                    nameWidget: Text("Firmen ID"),
                    contentWidget: Text(
                      api.authCompany,
                      style: const TextStyle(
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                  CSControl(
                    nameWidget: Text("Nutzer"),
                    contentWidget: Text(
                      api.authUsername,
                      style: const TextStyle(
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                  CSSecret("API Schlüssel", api.authToken),
                  CSButton(CSButtonType.DESTRUCTIVE, "Abmelden", () {
                    Navigator.of(context, rootNavigator: true)
                        .pushReplacement(CupertinoPageRoute(
                      builder: (BuildContext context) => CredentialsPage(),
                    ))
                        .whenComplete(() {
                      state = null;
                      api.deleteCredsFromLocalStore();
                    });
                  }),
                  CSHeader("Einstellungen"),
                  CSControl(
                    nameWidget: Text("Pausen hervorheben"),
                    contentWidget: CupertinoSwitch(
                      onChanged: (bool changed) => setState(() {
                        highlightBreaks = changed;
                        prefs.setBool("highlightBreaks", changed);
                      }),
                      value: highlightBreaks,
                    ),
                  ),
                  CSControl(
                    nameWidget: Text("Aufgaben vorschlagen"),
                    contentWidget: CupertinoSwitch(
                      onChanged: (bool changed) => setState(() {
                        taskSuggestions = changed;
                        prefs.setBool("taskSuggestions", changed);
                      }),
                      value: taskSuggestions,
                    ),
                  ),
                ];

                if (products != null && products.isNotEmpty) {
                  cs.add(CSHeader("Kaufe mir ein ..."));
                  for (ProductDetails product in products) {
                    cs.add(CSControl(
                      nameWidget: Text(
                        product.title.replaceAll(
                          iapAppNameFilter,
                          "",
                        ),
                      ),
                      contentWidget: CupertinoButton(
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(product.price),
                            ),
                            Icon(CupertinoIcons.shopping_cart),
                          ],
                        ),
                        onPressed: () {
                          _inAppPurchase.buyConsumable(
                            purchaseParam:
                                PurchaseParam(productDetails: product),
                            autoConsume: true,
                          );
                        },
                      ),
                    ));
                  }
                }

                cs.addAll([
                  CSHeader("Weitere Infos"),
                  CSLink(
                    title: "Im Store Anzeigen",
                    onPressed: () => AppReview.storeListing,
                  ),
                  CSLink(
                    title: "Quelltext",
                    onPressed: () =>
                        launch("https://github.com/SimonIT/timetracker"),
                  ),
                  CSLink(
                    title: "Kontakt",
                    onPressed: () => launch("mailto:simonit.orig@gmail.com"),
                  ),
                  CSLink(
                    title: "Lizenzen",
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(
                        builder: (BuildContext context) => LicensePage(),
                      ),
                    ),
                  ),
                ]);

                return CupertinoSettings(items: cs);
              },
            );
          default:
            return const Text("Something went wrong");
        }
      },
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
              content: const Text(
                "Sollen die manuellen Änderungen zurückgesetzt werden?",
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    "OK",
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("OK");
                    state.setManualTimeChange(false);
                    state.started_at = "0";
                    state.stopped_at = "0";
                    state.ended_at = "0";
                    track(context);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    "Abbrechen",
                  ),
                  onPressed: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop("Cancel"),
                )
              ],
            ),
          );
        } else {
          state.setStatus(!state.getStatus());
          if (state.getStatus()) {
            if (!state.hasStartedTime()) {
              state.setStartedAt(DateTime.now());
            } else {
              state.setPausedDuration(state.getPausedDuration() +
                  DateTime.now().difference(state.getEndedAt()));
              state.stopped_at = "0";
              state.ended_at = "0";
            }
          } else {
            state.setStoppedAt(DateTime.now());
          }
          catchError(
            api.setTrackerState(state),
            title: setTrackerError,
          );
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

  Table getRecentEntryTable() {
    bool isLarge = MediaQuery.of(context).size.width > 479;
    bool isLarger = MediaQuery.of(context).size.width > 767;
    bool isLargest = MediaQuery.of(context).size.width > 991;

    List<TableRow> recentEntries = [
      TableRow(
        decoration: rowHeading,
        children: <TableCell>[
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "Heute",
                textScaleFactor: 1.5,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                prettyDuration(
                  state.getTrackedToday(),
                  abbreviated: true,
                ),
              ),
            ),
          ),
          if (isLarge) TableCell(child: Container()),
          if (isLarge) TableCell(child: Container()),
        ],
      ),
    ];

    void addRecentTaskRow(List<Entry> e) {
      for (int i = 0; i < e.length; i++) {
        BoxDecoration rowDecoration;

        if (highlightBreaks && i + 1 < e.length) {
          if (!onSameDay(e[i].getTimeStamp(), e[i + 1].started_at))
            rowDecoration = rowDecorationNewDay;
          else if (e[i].started_at.difference(e[i + 1].getTimeStamp()) >
              const Duration(minutes: 2)) rowDecoration = rowDecorationBreak;
        }

        recentEntries.add(TableRow(
          decoration: rowDecoration,
          children: <TableCell>[
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      e[i].title,
                      textScaleFactor: 0.75,
                      style: const TextStyle(
                        color: CupertinoColors.lightBackgroundGray,
                      ),
                    ),
                    Text(e[i].task_name),
                  ],
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  prettyDuration(
                    e[i].getDuration(),
                    abbreviated: true,
                  ),
                ),
              ),
            ),
            if (isLarge)
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(dayMonth.format(e[i].getTimeStamp())),
                ),
              ),
            if (isLarge)
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${hoursSeconds.format(e[i].started_at)} bis ${hoursSeconds.format(e[i].getTimeStamp())}",
                  ),
                ),
              ),
          ],
        ));
      }
    }

    addRecentTaskRow(state.getTodaysEntries());

    recentEntries.add(TableRow(
      decoration: rowHeading,
      children: <TableCell>[
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Frühere Einträge",
              textScaleFactor: 1.5,
            ),
          ),
        ),
        TableCell(child: Container()),
        if (isLarge) TableCell(child: Container()),
        if (isLarge) TableCell(child: Container()),
      ],
    ));

    addRecentTaskRow(state.getPreviousEntries());

    return Table(
      columnWidths: {
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(90),
        if (isLarge) 2: FixedColumnWidth(90),
        if (isLarge) 3: FixedColumnWidth(180),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
      children: recentEntries,
    );
  }
}

class CredentialsPage extends StatefulWidget {
  @override
  _CredentialsPageState createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  TextEditingController _company = TextEditingController();
  TextEditingController _user = TextEditingController();
  TextEditingController _password = TextEditingController();

  bool showPassword = false;
  bool showLoading = false;

  Future<void> authenticateAndLoadState() async {
    setState(() => showLoading = true);
    try {
      await api.authenticate();
      api.loadTrackerState().then((TrackerState state) {
        setState(() => showLoading = false);
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => TimeTracker(state: state),
          ),
        );
      });
    } catch (e) {
      setState(() => showLoading = false);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text("Ein Fehler ist beim Login aufgetreten"),
          content: Text(e.message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text("Erneut Versuchen"),
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop("Cancel");
                authenticateAndLoadState();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Schließen"),
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop("Cancel"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    api.loadCredentials().then((bool success) async {
      if (success) {
        _company.text = api.authCompany;
        _user.text = api.authUsername;
        authenticateAndLoadState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
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
                controller: _company,
                placeholder: "Firmen ID",
                autocorrect: false,
                maxLines: 1,
                style: TextStyle(
                  color: CupertinoTheme.of(context).primaryContrastingColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CupertinoTextField(
                controller: _user,
                placeholder: "Nutzer",
                autocorrect: false,
                maxLines: 1,
                style: TextStyle(
                  color: CupertinoTheme.of(context).primaryContrastingColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CupertinoTextField(
                controller: _password,
                placeholder: "Passwort",
                autocorrect: false,
                maxLines: 1,
                obscureText: !showPassword,
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) showPassword = false;
                  });
                },
                style: TextStyle(
                  color: CupertinoTheme.of(context).primaryContrastingColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AnimatedCrossFade(
                crossFadeState: _password.text.isNotEmpty
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 500),
                firstChild: Row(
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
                secondChild: const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CupertinoButton.filled(
                child: const Text("Speichern"),
                onPressed: () async {
                  if (_password.text.isNotEmpty) {
                    setState(() => showLoading = true);
                    try {
                      await api.saveSettingsCheckToken(
                        _company.text,
                        _user.text,
                        _password.text,
                      );
                      api.loadTrackerState().then((TrackerState state) {
                        setState(() => showLoading = false);
                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                            builder: (BuildContext context) =>
                                TimeTracker(state: state),
                          ),
                        );
                      });
                    } catch (e) {
                      setState(() => showLoading = false);
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                          title: const Text(
                            "Ein Fehler ist beim Login aufgetreten",
                          ),
                          content: Text(e.message),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              isDestructiveAction: true,
                              child: const Text("Schließen"),
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop("Cancel"),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            if (showLoading)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LicensePage extends StatelessWidget {
  final Future<List<LicenseEntry>> _licenses =
      LicenseRegistry.licenses.toList();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Lizenzen",
          style: TextStyle(
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
      ),
      child: FutureBuilder(
        future: _licenses,
        builder: (BuildContext context, AsyncSnapshot<List<LicenseEntry>> s) {
          if (s.hasData) {
            return CupertinoScrollbar(
              child: ListView.builder(
                itemCount: s.data.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  try {
                    List<LicenseParagraph> paragraphs =
                        s.data[index].paragraphs.toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: <Widget>[
                          Text(
                            s.data[index].packages.join(", "),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Column(
                            children: paragraphs
                                .map((p) => Padding(
                                      padding: EdgeInsets.only(
                                        left: 15.0 *
                                            (p.indent > 0 ? p.indent : 0),
                                      ),
                                      child: Text(
                                        p.text,
                                        textAlign: p.indent ==
                                                LicenseParagraph.centeredIndent
                                            ? TextAlign.center
                                            : null,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    Sentry.captureException(
                      e,
                      stackTrace: e is Error ? e.stackTrace : null,
                    );
                    return Container();
                  }
                },
              ),
            );
          } else {
            return const Center(child: CupertinoActivityIndicator());
          }
        },
      ),
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
        child: tracking
            ? Icon(CupertinoIcons.pause_solid)
            : Icon(CupertinoIcons.play_arrow_solid),
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
      widget.state.getEndedAt().difference(widget.state.getStartedAt()) -
      widget.state.getPausedDuration();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width / 2,
      ),
      child: Text(
        prettyDuration(
          duration,
          abbreviated: true,
          delimiter: ' ',
          spacer: '',
        ),
        textScaleFactor: 1.5,
      ),
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
