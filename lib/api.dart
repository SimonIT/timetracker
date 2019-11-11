import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timetracker/data.dart';
import 'package:path/path.dart' as path;

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

const Map<String, String> headers = {
  'Accept': 'application/json',
  'Content-Type': 'application/x-www-form-urlencoded',
};
final DateFormat apiFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

Future<void> saveSettingsCheckToken(String company, String username, String password) async {
  http.Response result = await http.post(
    'https://${Uri.encodeComponent(company)}$apiDomain${apiPath}auth',
    body: {
      "email": Uri.encodeQueryComponent(username),
      "password": Uri.encodeQueryComponent(password),
    },
    headers: headers,
  );
  switch (result.statusCode) {
    case 200:
      Map jsonResult = jsonDecode(result.body);
      if ((jsonResult["token"] as String).isNotEmpty) {
        writeCredsToLocalStore(company, username, jsonResult["token"] as String);
        authenticate();
      } else {}
      break;
    case 302:
    case 401:
      throw Exception("Falsche Anmeldedaten");
    default:
      throw Exception(result.reasonPhrase);
  }
}

Future<void> authenticate() async {
  if (await loadCredentials()) {
    http.Response result = await http.post(
      "${baseUrl}auth",
      body: {"auth_token": authToken},
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
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.get(
      "${baseUrl}tracker/time_entries/timer_state.json?auth_token=$authToken",
    );
    if (result.statusCode == 200) {
      return TrackerState.fromJson(jsonDecode(result.body));
    } else {
      throw Exception(result.reasonPhrase);
    }
  } else {
    return null;
  }
}

Future<void> setTrackerState(TrackerState state) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    Map<String, String> body = {
      "auth_token": authToken,
      "timer_state[uuid]": state.uuid,
      "timer_state[status]": state.status,
      "timer_state[task_name]": Uri.encodeQueryComponent(state.task_name),
      "timer_state[started_at]": state.started_at,
      "timer_state[stopped_at]": state.stopped_at,
      "timer_state[ended_at]": state.ended_at,
      "timer_state[paused_duration]": state.paused_duration,
      "timer_state[entry_date]": state.entry_date,
      "timer_state[comment]": Uri.encodeQueryComponent(state.comment),
      "timer_state[manual_time_change]": state.manual_time_change,
    };
    if (state.project != null) {
      body.addAll({
        "timer_state[project][id]": state.project.id,
        "timer_state[project][name]": Uri.encodeQueryComponent(state.project.name),
        "timer_state[project][customer]": Uri.encodeQueryComponent(state.project.customer)
      });
    } else {
      body.addAll({
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
      throw Exception(result.reasonPhrase);
    }
  }
}

Future<void> postTrackedTime(TrackerState state) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.post(
      "${baseUrl}tracker/time_entries.json",
      headers: headers,
      body: {
        "auth_token": authToken,
        "tracker_time_entry[started_at]": Uri.encodeQueryComponent(apiFormat.format(state.getStartedAt())),
        "tracker_time_entry[ended_at]": Uri.encodeQueryComponent(apiFormat.format(state.getEndedAt())),
        "tracker_time_entry[comments]": Uri.encodeQueryComponent(state.comment),
        "tracker_time_entry[duration]":
            (state.getEndedAt().difference(state.getStartedAt()) - state.getPausedDuration()).inMinutes,
        "project_id": state.project.id,
        "task_name": Uri.encodeQueryComponent(state.task_name),
        "timer": "true",
      },
    );
    if (result.statusCode == 200) {
      Map<String, dynamic> apiResponse = jsonDecode(result.body);
      if (apiResponse["success"] != "true") throw Exception();
    } else {
      throw Exception(result.reasonPhrase);
    }
  }
}

Future<List<Company>> loadCustomers() async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.get(
      "${baseUrl}contact/companies.json?auth_token=$authToken",
    );
    if (result.statusCode == 200) {
      return (jsonDecode(result.body) as List)
          .map((e) => e == null ? null : Company.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(result.reasonPhrase);
    }
  } else {
    return null;
  }
}

Future<List<Project>> loadProjects({String searchPattern}) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    String url = "${baseUrl}projects.json?auth_token=$authToken";
    if (searchPattern != null) url = "$url&auto_complete=${Uri.encodeQueryComponent(searchPattern)}";
    http.Response result = await http.get(
      url,
    );
    if (result.statusCode == 200) {
      return (jsonDecode(result.body) as List)
          .map((e) => e == null ? null : Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(result.reasonPhrase);
    }
  } else {
    return null;
  }
}

Future<Project> loadProject(int id) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.get(
      "${baseUrl}projects/$id.json?auth_token=$authToken",
    );
    if (result.statusCode == 200) {
      return Project.fromJson(jsonDecode(result.body));
    } else {
      throw Exception(result.reasonPhrase);
    }
  } else {
    return null;
  }
}

Future<List<Task>> loadTasks() async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.get(
      "${baseUrl}tracker/tasks.json?auth_token=$authToken",
    );
    if (result.statusCode == 200) {
      return (jsonDecode(result.body) as List)
          .map((e) => e == null ? null : Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(result.reasonPhrase);
    }
  } else {
    return null;
  }
}

Future<void> uploadDocument(File document) async {
  http.MultipartRequest request = http.MultipartRequest("POST", Uri.parse("${baseUrl}documents"));
  request.fields["auth_token"] = authToken;
  request.files.add(
    http.MultipartFile(
      'document[data]',
      document.openRead(),
      await document.length(),
      filename: path.basename(document.path),
    ),
  );
  http.StreamedResponse result = await request.send();
  print("${result.statusCode}: ${result.reasonPhrase}");
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

  return {'username': username, 'token': password, 'company': company};
}

void deleteCredsFromLocalStore() {
  final FlutterSecureStorage storage = new FlutterSecureStorage();
  storage.deleteAll();
}
