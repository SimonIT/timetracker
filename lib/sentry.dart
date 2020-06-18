import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

Future<Event> getSentryEnvironmentAttributes({String repository}) async {
  WidgetsFlutterBinding.ensureInitialized();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String release = packageInfo.version;
  if (repository != null) {
    release = "$repository@${packageInfo.version}";
  }

  Map<String, dynamic> extra;

  /// return Event with IOS extra information to send it to Sentry
  if (Platform.isIOS) {
    final IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
    extra = {
      'name': iosDeviceInfo.name,
      'model': iosDeviceInfo.model,
      'systemName': iosDeviceInfo.systemName,
      'systemVersion': iosDeviceInfo.systemVersion,
      'localizedModel': iosDeviceInfo.localizedModel,
      'utsname': iosDeviceInfo.utsname.sysname,
      'identifierForVendor': iosDeviceInfo.identifierForVendor,
      'isPhysicalDevice': iosDeviceInfo.isPhysicalDevice,
    };
  }

  /// return Event with Android extra information to send it to Sentry
  if (Platform.isAndroid) {
    final AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
    extra = {
      'type': androidDeviceInfo.type,
      'model': androidDeviceInfo.model,
      'device': androidDeviceInfo.device,
      'id': androidDeviceInfo.id,
      'androidId': androidDeviceInfo.androidId,
      'brand': androidDeviceInfo.brand,
      'display': androidDeviceInfo.display,
      'hardware': androidDeviceInfo.hardware,
      'manufacturer': androidDeviceInfo.manufacturer,
      'product': androidDeviceInfo.product,
      'version': androidDeviceInfo.version.release,
      'supported32BitAbis': androidDeviceInfo.supported32BitAbis,
      'supported64BitAbis': androidDeviceInfo.supported64BitAbis,
      'supportedAbis': androidDeviceInfo.supportedAbis,
      'isPhysicalDevice': androidDeviceInfo.isPhysicalDevice,
    };
  }

  /// Return standard Error in case of non-specifed paltform
  ///
  /// if there is no detected platform,
  /// just return a normal event with no extra information
  return Event(
    release: release,
    extra: extra,
  );
}
