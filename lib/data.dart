import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable()
class Project {
  String budget_money;
  String budget_time;
  String budget_time_unit;
  String budget_type;
  String color;
  DateTime created_at;
  bool customer_default;
  int customer_id;
  String description;
  int id;
  String name;
  String progress;
  String record_state;
  DateTime updated_at;
  Company customer;

  Project();

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable()
class Company {
  String bank_account_no;
  String bank_bic;
  String bank_blz;
  String bank_iban;
  String bank_institute;
  bool bank_sepa_mandate_accepted;
  String bank_sepa_mandate_reference;
  String color;
  String contact_type;
  DateTime created_at;
  String customer_no;
  String delivery_method;
  String email;
  String fax;
  bool flagged;
  int id;
  String inbound_address;
  String logo_content_type;
  String logo_file_name;
  int logo_file_size;
  DateTime logo_updated_at;
  String name;
  String notes;
  String phone;
  String physical_city;
  String physical_country;
  String physical_street;
  String physical_zip;
  String postal_city;
  String postal_country;
  String postal_street;
  String postal_zip;
  String record_state;
  String supplier_no;
  String twitter;
  DateTime updated_at;
  String ust_idnr;
  String website;

  Company();

  factory Company.fromJson(Map<String, dynamic> json) => _$CompanyFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}

@JsonSerializable()
class Task {
  DateTime created_at;
  int id;
  String name;
  int project_id;
  int proposition_id;
  String record_state;
  DateTime updated_at;
  int user_id;

  Task();

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

@JsonSerializable()
class TrackerState {
  String uuid;
  String status;
  String task_name;
  String started_at;
  String stopped_at;
  String ended_at;
  String paused_duration;
  String entry_date;
  String comment;
  String manual_time_change;
  StateProject project;
  List<Entry> recent_entries;
  int tracked_today;
  int tracked_week;
  String realtime_channel;

  TrackerState();

  factory TrackerState.fromJson(Map<String, dynamic> json) => _$TrackerStateFromJson(json);

  Map<String, dynamic> toJson() => _$TrackerStateToJson(this);
}

@JsonSerializable()
class StateProject {
  String id;
  String name;
  String customer;

  StateProject();

  factory StateProject.fromJson(Map<String, dynamic> json) => _$StateProjectFromJson(json);

  Map<String, dynamic> toJson() => _$StateProjectToJson(this);
}

@JsonSerializable()
class Entry {
  int id;
  int task_id;
  String task_name;
  int project_id;
  String project_name;
  int customer_id;
  String customer_name;
  DateTime ended_at;
  int timestamp;
  int duration;
  int task_duration;

  Entry();

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryToJson(this);
}
