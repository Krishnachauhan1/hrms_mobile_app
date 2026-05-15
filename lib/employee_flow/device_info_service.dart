import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return {
          "deviceType": "android",
          "brand": androidInfo.brand,
          "model": androidInfo.model,
          "manufacturer": androidInfo.manufacturer,
          "androidVersion": androidInfo.version.release,
          "sdkInt": androidInfo.version.sdkInt,
          "deviceId": androidInfo.id,
          "isPhysicalDevice": androidInfo.isPhysicalDevice,
        };
      }

      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;

        return {
          "deviceType": "ios",
          "name": iosInfo.name,
          "model": iosInfo.model,
          "systemVersion": iosInfo.systemVersion,
          "identifierForVendor": iosInfo.identifierForVendor,
          "isPhysicalDevice": iosInfo.isPhysicalDevice,
        };
      }

      return {};
    } catch (e) {
      return {"error": e.toString()};
    }
  }
}
