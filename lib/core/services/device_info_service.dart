import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// A service to gather and provide device-specific information across different platforms
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  static DeviceInfoService get instance => _instance;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceData;

  DeviceInfoService._internal();

  /// Initializes the service by gathering device and package information
  Future<void> initialize() async {
    await Future.wait([
      _getDeviceInfo(),
      _getPackageInfo(),
    ]);
  }

  /// Gets the application package information
  Future<void> _getPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Gets device-specific information based on the platform
  Future<void> _getDeviceInfo() async {
    try {
      if (kIsWeb) {
        _deviceData = _readWebBrowserInfo(await _deviceInfo.webBrowserInfo);
      } else {
        if (Platform.isAndroid) {
          _deviceData = _readAndroidBuildData(await _deviceInfo.androidInfo);
        } else if (Platform.isIOS) {
          _deviceData = _readIosDeviceInfo(await _deviceInfo.iosInfo);
        } else if (Platform.isLinux) {
          _deviceData = _readLinuxDeviceInfo(await _deviceInfo.linuxInfo);
        } else if (Platform.isMacOS) {
          _deviceData = _readMacOsDeviceInfo(await _deviceInfo.macOsInfo);
        } else if (Platform.isWindows) {
          _deviceData = _readWindowsDeviceInfo(await _deviceInfo.windowsInfo);
        }
      }
    } catch (e) {
      _deviceData = {
        'Error': 'Failed to get device info: $e',
      };
    }
  }

  /// Extracts relevant information from Android devices
  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      'brand': build.brand,
      'device': build.device,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.id,
      'systemFeatures': build.systemFeatures,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'bootloader': build.bootloader,
      'host': build.host,
      'tags': build.tags,
      'type': build.type,
    };
  }

  /// Extracts relevant information from iOS devices
  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return {
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname': data.utsname.sysname,
      'utsname.nodename': data.utsname.nodename,
      'utsname.release': data.utsname.release,
      'utsname.version': data.utsname.version,
      'utsname.machine': data.utsname.machine,
    };
  }

  /// Extracts relevant information from web browsers
  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return {
      'browserName': data.browserName.name,
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
    };
  }

  /// Extracts relevant information from Linux systems
  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return {
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }

  /// Extracts relevant information from macOS systems
  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return {
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease,
      'activeCPUs': data.activeCPUs,
      'memorySize': data.memorySize,
      'cpuFrequency': data.cpuFrequency,
      'systemGUID': data.systemGUID,
    };
  }

  /// Extracts relevant information from Windows systems
  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return {
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'buildNumber': data.buildNumber,
      'platformId': data.platformId,
      'csdVersion': data.csdVersion,
      'servicePackMajor': data.servicePackMajor,
      'servicePackMinor': data.servicePackMinor,
      'suitMask': data.suitMask,
      'productType': data.productType,
      'reserved': data.reserved,
      'buildLab': data.buildLab,
      'buildLabEx': data.buildLabEx,
      'digitalProductId': data.digitalProductId,
      'displayVersion': data.displayVersion,
      'editionId': data.editionId,
      'installDate': data.installDate,
      'productId': data.productId,
      'productName': data.productName,
      'registeredOwner': data.registeredOwner,
      'releaseId': data.releaseId,
      'deviceId': data.deviceId,
    };
  }

  /// Gets the unique device identifier
  String? getDeviceId() {
    if (_deviceData == null) return null;

    if (kIsWeb) {
      return _deviceData!['userAgent'];
    } else if (Platform.isAndroid) {
      return _deviceData!['androidId'];
    } else if (Platform.isIOS) {
      return _deviceData!['identifierForVendor'];
    } else if (Platform.isLinux) {
      return _deviceData!['machineId'];
    } else if (Platform.isMacOS) {
      return _deviceData!['systemGUID'];
    } else if (Platform.isWindows) {
      return _deviceData!['deviceId'];
    }
    return null;
  }

  /// Gets the device model name
  String? getDeviceModel() {
    if (_deviceData == null) return null;

    if (kIsWeb) {
      return '${_deviceData!['browserName']} Browser';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _deviceData!['model'];
    } else if (Platform.isLinux || Platform.isMacOS) {
      return _deviceData!['name'];
    } else if (Platform.isWindows) {
      return _deviceData!['productName'];
    }
    return null;
  }

  /// Gets the operating system version
  String? getOsVersion() {
    if (_deviceData == null) return null;

    if (kIsWeb) {
      return _deviceData!['appVersion'];
    } else if (Platform.isAndroid) {
      return _deviceData!['version.release'];
    } else if (Platform.isIOS) {
      return _deviceData!['systemVersion'];
    } else if (Platform.isLinux) {
      return _deviceData!['version'];
    } else if (Platform.isMacOS) {
      return _deviceData!['osRelease'];
    } else if (Platform.isWindows) {
      return '${_deviceData!['majorVersion']}.${_deviceData!['minorVersion']} (${_deviceData!['buildNumber']})';
    }
    return null;
  }

  /// Gets the application version
  String? getAppVersion() {
    return _packageInfo?.version;
  }

  /// Gets the application build number
  String? getAppBuildNumber() {
    return _packageInfo?.buildNumber;
  }

  /// Gets the application package name
  String? getPackageName() {
    return _packageInfo?.packageName;
  }

  /// Gets all device information as a map
  Map<String, dynamic>? getAllDeviceInfo() {
    return _deviceData;
  }

  /// Gets device type (physical/emulator)
  bool? isPhysicalDevice() {
    if (_deviceData == null) return null;

    if (Platform.isAndroid || Platform.isIOS) {
      return _deviceData!['isPhysicalDevice'];
    }
    return null;
  }

  /// Checks if the device meets minimum requirements
  bool meetsMinimumRequirements() {
    if (_deviceData == null) return false;

    if (Platform.isAndroid) {
      // Require Android 6.0 (API 23) or higher
      return (_deviceData!['version.sdkInt'] as int) >= 23;
    } else if (Platform.isIOS) {
      // Require iOS 11 or higher
      final version = _deviceData!['systemVersion'] as String;
      final major = int.tryParse(version.split('.').first) ?? 0;
      return major >= 11;
    }
    return true; // Assume other platforms meet requirements
  }

  /// Gets system memory in megabytes
  int? getSystemMemory() {
    if (_deviceData == null) return null;

    if (kIsWeb) {
      return _deviceData!['deviceMemory'] as int?;
    } else if (Platform.isWindows) {
      return _deviceData!['systemMemoryInMegabytes'] as int?;
    } else if (Platform.isMacOS) {
      final memorySize = _deviceData!['memorySize'] as int?;
      return memorySize == null ? null : memorySize ~/ (1024 * 1024);
    }
    return null;
  }
}
