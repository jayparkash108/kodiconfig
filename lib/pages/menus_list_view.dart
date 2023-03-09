import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive_io.dart' as Archive;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:kodiconfig/uiHelper.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;

import '../models/menus_list_data.dart';
import '../app_theme.dart';
import '../../main.dart';

final message = ValueNotifier<String>('');
final progress = ValueNotifier<double>(0.0);

class MenusListView extends StatefulWidget {
  const MenusListView(
      {Key? key, this.mainScreenAnimationController, this.mainScreenAnimation})
      : super(key: key);

  final AnimationController? mainScreenAnimationController;
  final Animation<double>? mainScreenAnimation;

  @override
  _MenusListViewState createState() => _MenusListViewState();
}

class _MenusListViewState extends State<MenusListView>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  List<MenusListData> menusListData = MenusListData.tabIconsList;

  @override
  void initState() {
    animationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    super.initState();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.mainScreenAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.mainScreenAnimation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - widget.mainScreenAnimation!.value), 0.0),
            child: InkWell(
              onTap: () async {

                // createBackup();
                // print("/android/data/org.xbmc.kodi");
                // print(externalDir?.path);
                // _testZipFiles(
                //   includeBaseDirectory: true,
                //   sourcePath: kodiDir,
                //   destinationPath: kodiBackupDir
                // );
              },
              child: Container(
                height: 216,
                width: double.infinity,
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      top: 0, bottom: 0, right: 16, left: 16),
                  itemCount: menusListData.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    final int count =
                        menusListData.length > 10 ? 10 : menusListData.length;
                    final Animation<double> animation =
                        Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animationController!,
                                curve: Interval((1 / count) * index, 1.0,
                                    curve: Curves.fastOutSlowIn)));
                    animationController?.forward();

                    return InkWell(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(40),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
                      onTap: () {
                        if(index == 0) {
                          installAddon();
                        }
                        else if(index == 1) {
                          createBackup();
                        } else if(index == 2) {
                          restoreBackup();
                        }
                      },
                      child: MenusView(
                        menusListData: menusListData[index],
                        animation: animation,
                        animationController: animationController!,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void createBackup() async {
    uiHelper.showCustomLoadingDialog(
      context,
      text: "Creating Backup",
      backgroundColor: Colors.white,
      loaderSpin: SpinKitSpinningLines(color: HexColor("#5C5EDD"))
    );

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('d-MMMM-yyyy_h-mma').format(now);
    print(formattedDate);

    Future.delayed(Duration(seconds: 5), () async {

    final externalDir = await path_provider.getExternalStorageDirectory();
    final appDataDir = externalDir?.path.split("com.kodi.kodiconfig/files");
    final kodiDir = Directory(appDataDir![0] + "org.xbmc.kodi/");
    // print(kodiDir);
    final kodiBackupDir = Directory('${externalDir?.path}/backup');
    // print(kodiBackupDir);

    final zipLocation = kodiBackupDir.path + '/$formattedDate.zip';
    var encoder = Archive.ZipFileEncoder();
    encoder.zipDirectory(kodiDir, filename: zipLocation);
    // Manually create a zip of a directory and individual files.
    encoder.create(kodiBackupDir.path + 'logs/log.zip');
    encoder.close();

    final file = File(zipLocation);
    if(await file.exists()) {
      Navigator.pop(context);
      uiHelper.showAlertDialog(context, title: "Backup", body: "Backup created successfully!");
      print("created");
    } else {
      print("error");
    }
  });
  }

  void restoreBackup() async {
    double restoreProgress = 0.0;
    ZipEntry zipDetails;
    final externalDir = await path_provider.getExternalStorageDirectory();
    final appDataDir = externalDir?.path.split("com.kodi.kodiconfig/files");
    final kodiDir = Directory(appDataDir![0] + "org.xbmc.kodi/");
    final kodiBackupDir = Directory('${externalDir?.path}/backup');


    selectBackup(backupDirectory: kodiBackupDir).then((backupFilePath) async {
      if (backupFilePath != null) {
        // final zipLocation = kodiBackupDir.path + '/backup.zip';
        final zipFile = File(backupFilePath);
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AnimatedCloud();
            },
          );

          await ZipFile.extractToDirectory(
              zipFile: zipFile,
              destinationDir: kodiDir,
              onExtracting: (zipEntry, _progress) {
                var msg = zipEntry.name.split(".kodi/");
                // Update the message with the current progress
                String _message = msg[1];
                String _prog = (_progress).toStringAsFixed(0);
                message.value = _message;
                progress.value = double.parse(_prog);
                // ExtractionAlert alert = context.findAncestorWidgetOfExactType<ExtractionAlert>()!;
                // alert.callback;
                restoreProgress = _progress;
                zipDetails = zipEntry;
                print(restoreProgress);
                print(zipDetails);
                // print('progress: ${progress.toStringAsFixed(1)}%');
                // print('name: ${zipEntry.name}');
                // print('isDirectory: ${zipEntry.isDirectory}');
                // print(
                //     'modificationDate: ${zipEntry.modificationDate?.toLocal().toIso8601String()}');
                // print('uncompressedSize: ${zipEntry.uncompressedSize}');
                // print('compressedSize: ${zipEntry.compressedSize}');
                // print('compressionMethod: ${zipEntry.compressionMethod}');
                // print('crc: ${zipEntry.crc}');
                return ZipFileOperation.includeItem;
              });
        } catch (e) {
          print(e);
        }
      }
    });
  }
  // final backupName = backups[index].path.split("backup/");

  Future<String?> selectBackup({required Directory backupDirectory}) async {
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a backup file'),
          content: Container(
            width: double.maxFinite,
            child: FutureBuilder<List<FileSystemEntity>>(
              future: listFiles(backupDirectory: backupDirectory),
              builder: (BuildContext context,
                  AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<FileSystemEntity> sortedFiles = snapshot.data!
                      .where((file) => file is File)
                      .toList();
                  sortedFiles.sort((a, b) =>
                      b.statSync().modified.compareTo(a.statSync().modified));

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      FileSystemEntity file = sortedFiles[index];

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, file.path);
                        },
                        child: ListTile(
                          leading: Icon(Icons.archive),
                          title: Text(file.path.split('/').last),
                          subtitle: Text(dateFormatter.format(file.statSync().modified)),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<FileSystemEntity>> listFiles({required Directory backupDirectory}) async {
    List<FileSystemEntity> files = await backupDirectory.list().toList();
    return files;
  }

  Future<void> installAddon() async {
    final url = Uri.parse('http://127.0.0.1:8080/jsonrpc');
    final credentials = base64.encode(utf8.encode('kodi:123'));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $credentials',
    };

    // Send the addon installation request
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'Addons.Install',
        'params': {
          'addonurl': 'https://ezzer-mac.com/repo/repository.EzzerMacsWizard-1.1.6.zip', // Replace with the addon URL you want to install
          'enabled': true,
          'zip': true,
        },
        'id': 1,
      }),
    );

    if (response.statusCode == 200) {
      // Check the response to see if the addon was installed successfully
      final result = jsonDecode(response.body)['result'];
      print(response.body);
      if (result['status'] == 'ok') {
        print('Addon installed successfully!');
      } else {
        print('Error installing addon: ${result['status']}');
      }
    } else {
      print('Error sending addon installation request: ${response.statusCode}');
    }
  }

}


class ExtractionAlert extends StatefulWidget {
  final String message;
  ExtractionAlert({required this.message});

  @override
  _ExtractionAlertState createState() => _ExtractionAlertState();
}

class _ExtractionAlertState extends State<ExtractionAlert> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Container(
        width: size.width,
        height: size.height/2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white
          // gradient: LinearGradient(
          //   colors: [
          //     HexColor("#FF5287"),
          //     HexColor("#FE95B6")
          //   ]
          // ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, currentProgress, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Progress"),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: currentProgress / 100,
                              semanticsLabel: '%',
                              semanticsValue: "currentProgress",
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("$currentProgress %")
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.0),
              ValueListenableBuilder<String>(
                valueListenable: message,
                builder: (context, currentMessage, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      if(progress.value == 100)
                        Column(
                          children: [
                            Center(child: Text("Backup successfully restored!")),
                            SizedBox(height: 20,),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("OK")
                            )
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text(
                              "Current File",
                              style: TextStyle(
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(currentMessage),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class AnimatedCloud extends StatefulWidget {
  const AnimatedCloud({Key? key}) : super(key: key);

  @override
  _AnimatedCloudState createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<AnimatedCloud>
    with TickerProviderStateMixin {
  late final AnimationController _cloudController =
  AnimationController(vsync: this, duration: Duration(seconds: 5));

  @override
  void initState() {
    super.initState();
    _cloudController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4facfe),
              Color(0xFF00f2fe),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Restoring", style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold
                )),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2).animate(_cloudController),
                  child: Image.asset(
                    'assets/images/cloud.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                Text(
                  "Please wait..",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, currentProgress, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress",
                          style: TextStyle(
                              color: Colors.white
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: currentProgress / 100,
                                semanticsLabel: '%',
                                semanticsValue: "currentProgress",
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "$currentProgress %",
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            )
                          ],
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ValueListenableBuilder<String>(
                  valueListenable: message,
                  builder: (context, currentMessage, _) {
                    final msg = currentMessage.split(".kodi");
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        if(progress.value == 100)
                          Column(
                            children: [
                              Center(
                                child: Text(
                                  "Backup successfully restored!",
                                  style: TextStyle(
                                    color: Colors.white
                                  ),
                                ),
                              ),
                              SizedBox(height: 20,),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "OK",
                                    style: TextStyle(
                                      color: Colors.white
                                    ),
                                  )
                              )
                            ],
                          )
                        else
                          Column(
                            children: [
                              Text(
                                "Current File",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: 200,
                                child: Text(msg[0], style: TextStyle(color: Colors.white),)
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }
}

class ProgressWidget extends StatefulWidget {
  final double value;
  final Color color;

  const ProgressWidget({Key? key, required this.value, required this.color})
      : super(key: key);

  @override
  _ProgressWidgetState createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animationController.reset();
      _animation = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: 8,
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[300],
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: _animation.value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.color,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '${(_animation.value * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}


class MenusView extends StatelessWidget {
  const MenusView(
      {Key? key, this.menusListData, this.animationController, this.animation})
      : super(key: key);

  final MenusListData? menusListData;
  final AnimationController? animationController;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                100 * (1.0 - animation!.value), 0.0, 0.0),
            child: SizedBox(
              width: 130,
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 32, left: 8, right: 8, bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              color: HexColor(menusListData!.endColor)
                                  .withOpacity(0.6),
                              offset: const Offset(1.1, 4.0),
                              blurRadius: 8.0),
                        ],
                        gradient: LinearGradient(
                          colors: <HexColor>[
                            HexColor(menusListData!.startColor),
                            HexColor(menusListData!.endColor),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                          topLeft: Radius.circular(8.0),
                          topRight: Radius.circular(54.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 54, left: 16, right: 16, bottom: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              menusListData!.titleTxt,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontName,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.2,
                                color: AppTheme.white,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      menusListData!.description!.join('\n'),
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontName,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                        letterSpacing: 0.2,
                                        color: AppTheme.white,
                                      ),
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.nearlyWhite.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 8,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: FittedBox(child: Image.asset(menusListData!.imagePath)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
