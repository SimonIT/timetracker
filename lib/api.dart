import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

String authCompany;
String authUsername;
String authPassword;
String authToken;
String authRealtimeToken;

String userName;
String tenantName;

String baseUrl;
//String api_domain = ".odacer.com:3000";  // DEV
String apiDomain = ".papierkram.de"; // LIVE
String apiPath = "/api/v1/";

const Map<String, String> headers = {
  'Accept': '*/*',
  'Content-Type': 'application/x-www-form-urlencoded',
};

saveSettingsCheckToken(String company, String username, String password) async {
  String tokenUrl = 'https://' + company + apiDomain + apiPath;
  http.Response result = await http.post(
    tokenUrl + "auth",
    body: "email:$username&password:$password",
    headers: headers,
  );
  Map jsonResult = jsonDecode(result.body);
  if ((jsonResult["token"] as String).isNotEmpty) {
    writeCredsToLocalStore(company, username, jsonResult["token"] as String);
    authenticate();
  } else {}
}

authenticate() async {
  if (await loadCredentials()) {
    http.Response result = await http.post(
      baseUrl + "auth",
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

  if (credentials["company"].isEmpty || credentials["token"].isEmpty) {
    return false;
  } else {
    authCompany = credentials['company'];
    authUsername = credentials['username'];
    authToken = credentials['token'];
    baseUrl = "https://" + authCompany + apiDomain + apiPath;
    return true;
  }
}

loadCustomers() async {
  Map<String, String> authHeader = {'authToken': authToken};
  authHeader.addAll(headers);
  http.Response result = await http.get(
    baseUrl + "contact/companies.json",
    headers: authHeader,
  );
  if (result.statusCode == 200) {
    Map projects = jsonDecode(result.body);
    print(projects);
  }
}

loadProjects() async {
  Map<String, String> authHeader = {'authToken': authToken};
  authHeader.addAll(headers);
  http.Response result = await http.get(
    baseUrl + "projects.json",
    headers: authHeader,
  );
  if (result.statusCode == 200) {
    Map projects = jsonDecode(result.body);
    print(projects);
  }
}

loadTasks() async {
  Map<String, String> authHeader = {'authToken': authToken};
  authHeader.addAll(headers);
  http.Response result = await http.get(
    baseUrl + "tracker/tasks.json",
    headers: authHeader,
  );
  if (result.statusCode == 200) {
    Map projects = jsonDecode(result.body);
    print(projects);
  }
}

writeCredsToLocalStore(String company, String username, String token) {
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
