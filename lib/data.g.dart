// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return Project()
    ..budget_money = json['budget_money'] as String
    ..budget_time = json['budget_time'] as String
    ..budget_time_unit = json['budget_time_unit'] as String
    ..budget_type = json['budget_type'] as String
    ..color = json['color'] as String
    ..created_at = json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String)
    ..customer_default = json['customer_default'] as bool
    ..customer_id = json['customer_id'] as int
    ..description = json['description'] as String
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..progress = json['progress'] as String
    ..record_state = json['record_state'] as String
    ..updated_at = json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String)
    ..customer = json['customer'] == null ? null : Company.fromJson(json['customer'] as Map<String, dynamic>);
}

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'budget_money': instance.budget_money,
      'budget_time': instance.budget_time,
      'budget_time_unit': instance.budget_time_unit,
      'budget_type': instance.budget_type,
      'color': instance.color,
      'created_at': instance.created_at?.toIso8601String(),
      'customer_default': instance.customer_default,
      'customer_id': instance.customer_id,
      'description': instance.description,
      'id': instance.id,
      'name': instance.name,
      'progress': instance.progress,
      'record_state': instance.record_state,
      'updated_at': instance.updated_at?.toIso8601String(),
      'customer': instance.customer
    };

Company _$CompanyFromJson(Map<String, dynamic> json) {
  return Company()
    ..bank_account_no = json['bank_account_no'] as String
    ..bank_bic = json['bank_bic'] as String
    ..bank_blz = json['bank_blz'] as String
    ..bank_iban = json['bank_iban'] as String
    ..bank_institute = json['bank_institute'] as String
    ..bank_sepa_mandate_accepted = json['bank_sepa_mandate_accepted'] as bool
    ..bank_sepa_mandate_reference = json['bank_sepa_mandate_reference'] as String
    ..color = json['color'] as String
    ..contact_type = json['contact_type'] as String
    ..created_at = json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String)
    ..customer_no = json['customer_no'] as String
    ..delivery_method = json['delivery_method'] as String
    ..email = json['email'] as String
    ..fax = json['fax'] as String
    ..flagged = json['flagged'] as bool
    ..id = json['id'] as int
    ..inbound_address = json['inbound_address'] as String
    ..logo_content_type = json['logo_content_type'] as String
    ..logo_file_name = json['logo_file_name'] as String
    ..logo_file_size = json['logo_file_size'] as int
    ..logo_updated_at = json['logo_updated_at'] == null ? null : DateTime.parse(json['logo_updated_at'] as String)
    ..name = json['name'] as String
    ..notes = json['notes'] as String
    ..phone = json['phone'] as String
    ..physical_city = json['physical_city'] as String
    ..physical_country = json['physical_country'] as String
    ..physical_street = json['physical_street'] as String
    ..physical_zip = json['physical_zip'] as String
    ..postal_city = json['postal_city'] as String
    ..postal_country = json['postal_country'] as String
    ..postal_street = json['postal_street'] as String
    ..postal_zip = json['postal_zip'] as String
    ..record_state = json['record_state'] as String
    ..supplier_no = json['supplier_no'] as String
    ..twitter = json['twitter'] as String
    ..updated_at = json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String)
    ..ust_idnr = json['ust_idnr'] as String
    ..website = json['website'] as String;
}

Map<String, dynamic> _$CompanyToJson(Company instance) => <String, dynamic>{
      'bank_account_no': instance.bank_account_no,
      'bank_bic': instance.bank_bic,
      'bank_blz': instance.bank_blz,
      'bank_iban': instance.bank_iban,
      'bank_institute': instance.bank_institute,
      'bank_sepa_mandate_accepted': instance.bank_sepa_mandate_accepted,
      'bank_sepa_mandate_reference': instance.bank_sepa_mandate_reference,
      'color': instance.color,
      'contact_type': instance.contact_type,
      'created_at': instance.created_at?.toIso8601String(),
      'customer_no': instance.customer_no,
      'delivery_method': instance.delivery_method,
      'email': instance.email,
      'fax': instance.fax,
      'flagged': instance.flagged,
      'id': instance.id,
      'inbound_address': instance.inbound_address,
      'logo_content_type': instance.logo_content_type,
      'logo_file_name': instance.logo_file_name,
      'logo_file_size': instance.logo_file_size,
      'logo_updated_at': instance.logo_updated_at?.toIso8601String(),
      'name': instance.name,
      'notes': instance.notes,
      'phone': instance.phone,
      'physical_city': instance.physical_city,
      'physical_country': instance.physical_country,
      'physical_street': instance.physical_street,
      'physical_zip': instance.physical_zip,
      'postal_city': instance.postal_city,
      'postal_country': instance.postal_country,
      'postal_street': instance.postal_street,
      'postal_zip': instance.postal_zip,
      'record_state': instance.record_state,
      'supplier_no': instance.supplier_no,
      'twitter': instance.twitter,
      'updated_at': instance.updated_at?.toIso8601String(),
      'ust_idnr': instance.ust_idnr,
      'website': instance.website
    };

Task _$TaskFromJson(Map<String, dynamic> json) {
  return Task()
    ..created_at = json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String)
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..project_id = json['project_id'] as int
    ..proposition_id = json['proposition_id'] as int
    ..record_state = json['record_state'] as String
    ..updated_at = json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String)
    ..user_id = json['user_id'] as int;
}

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'created_at': instance.created_at?.toIso8601String(),
      'id': instance.id,
      'name': instance.name,
      'project_id': instance.project_id,
      'proposition_id': instance.proposition_id,
      'record_state': instance.record_state,
      'updated_at': instance.updated_at?.toIso8601String(),
      'user_id': instance.user_id
    };
