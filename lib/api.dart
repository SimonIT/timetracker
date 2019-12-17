import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:timetracker/data.dart';

String authCompany;
String authUsername;
String authPassword;
String authToken;
String authRealtimeToken;

String userName;
String tenantName;

String baseUrl;
//const String apiDomain = ".odacer.com:3000";  // DEV
const String apiDomain = ".papierkram.de"; // LIVE
const String apiPath = "/api/v1/";

const Map<String, String> headers = <String, String>{
  'Accept': 'application/json',
  'Content-Type': 'application/x-www-form-urlencoded',
};
final DateFormat apiFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

BaseCacheManager m = MyCacheManager();

Future<void> saveSettingsCheckToken(String company, String username, String password) async {
  http.Response result = await http.post(
    'https://${Uri.encodeComponent(company)}$apiDomain${apiPath}auth',
    body: <String, String>{
      "email": username,
      "password": password,
    },
    headers: headers,
  );
  switch (result.statusCode) {
    case 200:
      Map jsonResult = jsonDecode(result.body);
      if ((jsonResult["token"] as String).isNotEmpty) {
        writeCredsToLocalStore(company, username, jsonResult["token"] as String);
        authenticate();
      } else {
        throw new Exception("Response does not contain a tocken \n\n $jsonResult");
      }
      break;
    case 302:
    case 401:
      throw Exception("Falsche Anmeldedaten");
    default:
      throw Exception("${result.statusCode}: ${result.reasonPhrase}\n\n${result.body}");
  }
}

Future<void> authenticate() async {
  if (await loadCredentials()) {
    http.Response result = await http.post(
      "${baseUrl}auth",
      body: <String, String>{"auth_token": authToken},
      headers: headers,
    );
    if (result.statusCode == 200) {
      Map jsonResult = jsonDecode(result.body);
      if ((jsonResult["token"] as String).isEmpty) {
        throw Exception("Sorry, aber ich konnte mich nicht verbinden. Bitte prüfe Deine Zugangsdaten... (1)");
      } else {
        authToken = jsonResult["token"] as String;
        userName = jsonResult["user_name"] as String;
        tenantName = jsonResult["tenant_name"] as String;
        authRealtimeToken = jsonResult["realtime_token"] as String;
      }
    } else {
      throw Exception("Sorry, aber ich konnte mich nicht verbinden. Bitte prüfe Deine Zugangsdaten... (2)");
    }
  }
}

Future<bool> loadCredentials() async {
  Map<String, String> credentials = await readCredsFromLocalStore();

  if (credentials["company"] == null ||
      credentials["company"].isEmpty ||
      credentials["token"] == null ||
      credentials["token"].isEmpty) {
    return false;
  } else {
    authCompany = credentials['company'];
    authUsername = credentials['username'];
    authToken = credentials['token'];
    baseUrl = "https://${Uri.encodeComponent(authCompany)}$apiDomain$apiPath";
    return true;
  }
}

Future<TrackerState> loadTrackerState() async {
  File tsf = (await m.downloadFile("${baseUrl}tracker/time_entries/timer_state.json?auth_token=$authToken")).file;
  return TrackerState.fromJson(jsonDecode(tsf.readAsStringSync()));
}

Future<void> setTrackerState(TrackerState state) async {
  Map<String, String> body = <String, String>{
    "auth_token": authToken,
    "timer_state[uuid]": state.uuid,
    "timer_state[status]": state.status,
    "timer_state[task_name]": state.task_name,
    "timer_state[started_at]": state.started_at,
    "timer_state[stopped_at]": state.stopped_at,
    "timer_state[ended_at]": state.ended_at,
    "timer_state[paused_duration]": state.paused_duration ?? "0",
    "timer_state[entry_date]": state.entry_date,
    "timer_state[comment]": state.comment,
    "timer_state[manual_time_change]": state.manual_time_change,
  };
  if (state.unbillable != null) {
    body.addAll({
      "timer_state[unbillable]": state.unbillable,
    });
  }
  if (state.project != null) {
    body.addAll(<String, String>{
      "timer_state[project][id]": state.project.id,
      "timer_state[project][name]": state.project.name,
      "timer_state[project][customer]": state.project.customer,
    });
  } else {
    body.addAll(const <String, String>{
      "timer_state[project]": "",
    });
  }

  http.Response result = await http.post(
    "${baseUrl}tracker/time_entries/timer_state.json",
    headers: headers,
    body: body,
  );
  if (result.statusCode == 202) {
    Map<String, dynamic> apiResponse = jsonDecode(result.body);
    if (apiResponse["success"] != "true") throw Exception();
  } else {
    throw Exception("${result.statusCode}: ${result.reasonPhrase}\n\n${result.body}");
  }
}

Future<void> postTrackedTime(TrackerState state) async {
  http.Response result = await http.post(
    "${baseUrl}tracker/time_entries.json",
    headers: headers,
    body: <String, String>{
      "auth_token": authToken,
      "tracker_time_entry[started_at]": apiFormat.format(state.getStartedAt()),
      "tracker_time_entry[ended_at]": apiFormat.format(state.getEndedAt()),
      "tracker_time_entry[comments]": state.comment,
      "tracker_time_entry[duration]":
          (state.getEndedAt().difference(state.getStartedAt()) - state.getPausedDuration()).inMinutes.toString(),
      "tracker_time_entry[unbillable]": state.unbillable,
      "project_id": state.project.id,
      "task_name": state.task_name,
      "timer": "true",
    },
  );
  if (result.statusCode == 200) {
    Map<String, dynamic> apiResponse = jsonDecode(result.body);
    if (apiResponse["success"] != "true") throw Exception();
  } else {
    throw Exception("${result.statusCode}: ${result.reasonPhrase}\n\n${result.body}");
  }
}

Future<List<Company>> loadCustomers() async {
  File cf = await m.getSingleFile("${baseUrl}contact/companies.json?auth_token=$authToken");
  return (jsonDecode(cf.readAsStringSync()) as List)
      .map((e) => e == null ? null : Company.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<Project>> loadProjects({String searchPattern}) async {
  String url = "${baseUrl}projects.json?auth_token=$authToken";
  if (searchPattern != null) url = "$url&auto_complete=${Uri.encodeQueryComponent(searchPattern)}";
  File pf = await m.getSingleFile(url);
  return (jsonDecode(pf.readAsStringSync()) as List)
      .map((e) => e == null ? null : Project.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<Project> loadProject(int id) async {
  File pf = await m.getSingleFile("${baseUrl}projects/$id.json?auth_token=$authToken");
  return Project.fromJson(jsonDecode(pf.readAsStringSync()));
}

Future<List<Task>> loadTasks() async {
  File tf = await m.getSingleFile("${baseUrl}tracker/tasks.json?auth_token=$authToken");
  return (jsonDecode(tf.readAsStringSync()) as List)
      .map((e) => e == null ? null : Task.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<String> uploadDocument(File document) async {
  http.MultipartRequest request = http.MultipartRequest("POST", Uri.parse("${baseUrl}documents"));
  request.fields["auth_token"] = authToken;
  request.headers.addAll(headers);
  request.files.add(
    http.MultipartFile(
      'document[data]',
      document.openRead(),
      await document.length(),
      filename: path.basename(document.path),
    ),
  );
  http.StreamedResponse result = await request.send();
  if (result.statusCode != 201) {
    throw Exception("${result.statusCode}: ${result.reasonPhrase}\n\n${await result.stream.bytesToString()}");
  }
  return result.headers["location"];
}

void writeCredsToLocalStore(String company, String username, String token) {
  final FlutterSecureStorage storage = new FlutterSecureStorage();

  storage.write(key: 'company', value: company);
  storage.write(key: 'username', value: username);
  storage.write(key: 'token', value: token);
}

Future<Map<String, String>> readCredsFromLocalStore() async {
  final FlutterSecureStorage storage = new FlutterSecureStorage();

  String company = await storage.read(key: 'company');
  String username = await storage.read(key: 'username');
  String password = await storage.read(key: 'token');

  return <String, String>{'username': username, 'token': password, 'company': company};
}

void deleteCredsFromLocalStore() {
  final FlutterSecureStorage storage = new FlutterSecureStorage();
  storage.deleteAll();
}

class MyCacheManager extends BaseCacheManager {
  static const key = "libTimeTrackerData";

  static MyCacheManager _instance;

  factory MyCacheManager() {
    if (_instance == null) {
      _instance = new MyCacheManager._();
    }
    return _instance;
  }

  MyCacheManager._() : super(key);

  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return path.join(directory.path, key);
  }

  @override
  Future<File> getSingleFile(String url, {Map<String, String> headers}) async {
    FileInfo cacheFile = await getFileFromCache(url);
    if (cacheFile != null) {
      if (cacheFile.validTill.isBefore(DateTime.now())) {
        webHelper.downloadFile(url, authHeaders: headers);
      }
      return cacheFile.file;
    }
    FileInfo download = await webHelper.downloadFile(url, authHeaders: headers);
    return download.file;
  }
}
