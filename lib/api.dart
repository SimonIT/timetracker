import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:time_tracker/data.dart';

String authCompany;
String authUsername;
String authPassword;
String authToken;
String authRealtimeToken;

String userName;
String tenantName;

String baseUrl;
//String apiDomain = ".odacer.com:3000";  // DEV
String apiDomain = ".papierkram.de"; // LIVE
String apiPath = "/api/v1/";

final Map<String, String> headers = {
  'Accept': '*/*',
  'Content-Type': 'application/x-www-form-urlencoded',
};
final DateFormat apiFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

Future<void> saveSettingsCheckToken(String company, String username, String password) async {
  http.Response result = await http.post(
    'https://$company$apiDomain${apiPath}auth',
    body: "email=$username&password=$password",
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
      body: "auth_token=$authToken",
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

  //credentials = {'username': 'wilhelm@blueend.com', 'company': 'blueend', 'token': '7jArBRKNZW7s3pxYMeAb'};

  if (credentials["company"] == null ||
      credentials["company"].isEmpty ||
      credentials["token"] == null ||
      credentials["token"].isEmpty) {
    return false;
  } else {
    authCompany = credentials['company'];
    authUsername = credentials['username'];
    authToken = credentials['token'];
    baseUrl = "https://$authCompany$apiDomain$apiPath";
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
      throw Exception();
    }
  } else {
    return null;
  }
}

Future<void> setTrackerState(TrackerState state) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    String body = "auth_token=$authToken"
        "&timer_state%5Buuid%5D=${state.uuid}"
        "&timer_state%5Bstatus%5D=${state.status}"
        "&timer_state%5Btask_name%5D=${Uri.encodeQueryComponent(state.task_name)}"
        "&timer_state%5Bstarted_at%5D=${state.started_at}"
        "&timer_state%5Bstopped_at%5D=${state.stopped_at}"
        "&timer_state%5Bended_at%5D=${state.stopped_at}"
        "&timer_state%5Bpaused_duration%5D=${state.paused_duration}"
        "&timer_state%5Bentry_date%5D=${state.entry_date}"
        "&timer_state%5Bcomment%5D=${Uri.encodeQueryComponent(state.comment)}"
        "&timer_state%5Bmanual_time_change%5D=${state.manual_time_change}";
    if (state.project != null) {
      body += "&timer_state%5Bproject%5D%5Bid%5D=${state.project.id}"
          "&timer_state%5Bproject%5D%5Bname%5D=${Uri.encodeQueryComponent(state.project.name)}"
          "&timer_state%5Bproject%5D%5Bcustomer%5D=${Uri.encodeQueryComponent(state.project.customer)}";
    } else {
      body += "&timer_state%5Bproject%5D=";
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
      throw Exception();
    }
  }
}

Future<void> postTrackedTime(TrackerState state) async {
  if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
    http.Response result = await http.post(
      "${baseUrl}tracker/time_entries.json",
      headers: headers,
      body: "auth_token=$authToken"
          "&tracker_time_entry%5Bstarted_at%5D=${Uri.encodeQueryComponent(apiFormat.format(state.getStartedAt()))}"
          "&tracker_time_entry%5Bended_at%5D=${Uri.encodeQueryComponent(apiFormat.format(state.getEndedAt()))}"
          "&tracker_time_entry%5Bcomments%5D=${Uri.encodeQueryComponent(state.comment)}"
          "&tracker_time_entry%5Bduration%5D=${(state.getEndedAt().difference(state.getStartedAt()) - state.getPausedDuration()).inMinutes}"
          "&project_id=${state.project.id}"
          "&task_name=${Uri.encodeQueryComponent(state.task_name)}"
          "&timer=true",
    );
    if (result.statusCode == 200) {
      Map<String, dynamic> apiResponse = jsonDecode(result.body);
      if (apiResponse["success"] != "true") throw Exception();
    } else {
      throw Exception();
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
      throw Exception();
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
      throw Exception();
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
      throw Exception();
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
      throw Exception();
    }
  } else {
    return null;
  }
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
