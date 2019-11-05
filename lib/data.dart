import 'package:html_unescape/html_unescape_small.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:timetracker/helpers.dart';

part 'data.g.dart';

HtmlUnescape _unescape = HtmlUnescape();

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
  String memento_content_type;
  String memento_file_name;
  int memento_file_size;
  DateTime memento_updated_at;
  String name;
  String progress;
  String record_state;
  DateTime updated_at;
  Company customer;
  List<Task> tasks;
  List<User> users;

  Project();

  String get title => "${_unescape.convert(customer.name)}: $name";

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

  setStatus(bool state) {
    if (state) {
      this.status = "running";
    } else {
      this.status = "stopped";
    }
  }

  bool getStatus() {
    return this.status == "running";
  }

  void setStartedAt(DateTime startedAt) {
    this.started_at = startedAt.millisecondsSinceEpoch.toString();
  }

  DateTime getStartedAt() {
    int startedMillis = int.parse(this.started_at);
    return startedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(startedMillis) : DateTime.now();
  }

  DateTime getStoppedAt() {
    int stoppedMillis = int.parse(this.stopped_at);
    return stoppedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(stoppedMillis) : DateTime.now();
  }

  void setStoppedAt(DateTime stoppedAt) {
    this.stopped_at = stoppedAt.millisecondsSinceEpoch.toString();
    setEndedAt(stoppedAt);
  }

  void setEndedAt(DateTime endedAt) {
    this.ended_at = endedAt.millisecondsSinceEpoch.toString();
  }

  DateTime getEndedAt() {
    int endedMillis = int.parse(this.ended_at);
    return endedMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(endedMillis) : DateTime.now();
  }

  void setManualTimeChange(bool manualTimeChange) {
    this.manual_time_change = manualTimeChange.toString();
  }

  bool getManualTimeChange() {
    return this.manual_time_change.toLowerCase() == "true";
  }

  void setPausedDuration(Duration pausedDuration) {
    this.paused_duration = pausedDuration.inMilliseconds.toString();
  }

  Duration getPausedDuration() {
    return this.paused_duration != null && this.paused_duration != "null"
        ? Duration(milliseconds: int.parse(this.paused_duration))
        : const Duration();
  }

  void setToEntry(Entry entry) {
    if (this.project == null) this.project = StateProject();
    this.project.id = entry.id.toString();
    this.project.name = entry.project_name;
    this.project.customer = entry.customer_name;
    this.task_name = entry.task_name;
  }

  void setProject(Project project) {
    if (this.project == null) this.project = StateProject();
    this.project.id = project.id.toString();
    this.project.name = project.name;
    this.project.customer = project.customer.name;
  }

  List<Entry> getTodaysEntries() {
    return this.recent_entries.where((Entry e) => onSameDay(DateTime.now(), e.getTimeStamp())).toList();
  }

  List<Entry> getPreviousEntries() {
    return this.recent_entries.where((Entry e) => !onSameDay(DateTime.now(), e.getTimeStamp())).toList();
  }

  Duration getTrackedToday() {
    return Duration(seconds: this.tracked_today);
  }

  void empty() {
    this.project = null;
    this.task_name = "";
    this.comment = "";
    this.started_at = "0";
    this.stopped_at = "0";
    this.ended_at = "0";
    this.entry_date = "heute";
    this.paused_duration = "0";
    this.manual_time_change = "false";
    this.status = "stopped";
  }

  bool hasStartedTime() {
    return this.started_at != "0";
  }

  bool hasStoppedTime() {
    return this.stopped_at != "0";
  }

  factory TrackerState.fromJson(Map<String, dynamic> json) => _$TrackerStateFromJson(json);

  Map<String, dynamic> toJson() => _$TrackerStateToJson(this);
}

@JsonSerializable()
class StateProject {
  String id;
  String name;
  String customer;

  StateProject();

  String get title => "${_unescape.convert(customer)}: $name";

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
  DateTime ended_at; // Do Not Use, wrong timezone
  int timestamp;
  int duration;
  int task_duration; // I think this is for all

  Entry();

  DateTime get started_at => getTimeStamp().subtract(getDuration());

  String get title => "${_unescape.convert(customer_name)}: $project_name";

  DateTime getTimeStamp() {
    return DateTime.fromMillisecondsSinceEpoch(this.timestamp * 1000);
  }

  Duration getDuration() {
    return Duration(seconds: duration);
  }

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryToJson(this);
}

@JsonSerializable()
class User {
  String first_name;
  int id;
  String last_name;
  String role;
  String full_name;
  String role_f;

  User();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
