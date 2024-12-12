import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:device_apps/device_apps.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<AppUsageInfo> _infos = [];
  final Map<String, ApplicationWithIcon> _appIcons = {};

  @override
  void initState() {
    super.initState();
    getUsageStats();
  }

  Future<void> getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 1));
      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);
      setState(() => _infos = infoList);

      for (var info in infoList) {
        Application? app = await DeviceApps.getApp(info.packageName, true);
        if (app is ApplicationWithIcon) {
          setState(() {
            _appIcons[info.packageName] = app;
          });
        } else {
          // Try to get the app icon from the list of installed apps
          List<Application> installedApps =
              await DeviceApps.getInstalledApplications(
            onlyAppsWithLaunchIntent: true,
            includeSystemApps: true,
            includeAppIcons: true,
          );

          for (var installedApp in installedApps) {
            if (installedApp is ApplicationWithIcon &&
                installedApp.packageName == info.packageName) {
              setState(() {
                _appIcons[info.packageName] = installedApp;
              });
              break;
            }
          }
        }
      }
    } on AppUsageException catch (exception) {
      print(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Usage Example'),
          backgroundColor: Colors.green,
        ),
        body: ListView.builder(
          itemCount: _infos.length,
          itemBuilder: (context, index) {
            var info = _infos[index];
            var appIcon = _appIcons[info.packageName];
            return ListTile(
              leading: appIcon != null ? Image.memory(appIcon.icon) : null,
              title: Text(info.appName),
              subtitle: Text('Start: ${info.startDate}\nEnd: ${info.endDate}'),
              trailing: Text(info.usage.toString()),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: getUsageStats,
          child: const Icon(Icons.file_download),
        ),
      ),
    );
  }
}
