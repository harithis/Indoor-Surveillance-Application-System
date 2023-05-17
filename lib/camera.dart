import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:save_me_project/side_navbar.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:save_me_project/widget/blinkTimer.dart';
import 'package:save_me_project/widget/videoUtil.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Camera😀",
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.tealAccent),
      ),
      home: Home(
        channel: IOWebSocketChannel.connect('ws://YOUR IP ADDRESS'),
      ),
    );
  }
}

class Home extends StatefulWidget {
  final WebSocketChannel channel;
  const Home({super.key, required this.channel});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  bool isLandscape = false;
  bool isRecording = false;
  String timeString = formatDateTime(DateTime.now());

  var globalKey = GlobalKey();
  final controller = ScreenshotController();
  final DateTime now = DateTime.now();

  Timer? timer;
  final FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

  int frameNum = 0;

  void getTime(){
    final DateTime now = DateTime.now();
    setState(() {
      timeString = formatDateTime(now);
    });
  }
  

   Widget getFab() {
    return SpeedDial(
      overlayOpacity: 0.1,
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22),
      visible: isLandscape,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
            child: isRecording ? const Icon(Icons.stop) : const Icon(Icons.videocam),
            onTap: videoRecording)
      ],
    );
  }

   videoRecording() {
    isRecording = !isRecording;

    if (!isRecording && frameNum > 0) {
      frameNum = 0;
      makeVideoWithFFMpeg();
    }
  }

   Future<int> execute(String command) async {
    return await flutterFFmpeg.execute(command);
  }

  makeVideoWithFFMpeg() {
    String tempVideofileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
    execute(VideoUtil.generateEncodeVideoScript("mpeg4", tempVideofileName))
        .then((rc) {
      if (rc == 0) {
        print("Video complete");

        String outputPath = "${VideoUtil.appTempDir}/$tempVideofileName";
        saveVideo(outputPath);
      }
    });
  }

  saveVideo(String path) async {
    GallerySaver.saveVideo(path).then((result) {
      print("Video Save result : $result");

      Fluttertoast.showToast(
          msg: "Video Saved",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      VideoUtil.deleteTempDirectory();
    });
  }

  @override
  void initState() {
    super.initState();
    isLandscape = false;

    timeString = formatDateTime(DateTime.now());
    timer = Timer.periodic(const Duration(seconds: 1),(timer) => getTime());

    frameNum = 0;
    VideoUtil.workPath = 'images';
    VideoUtil.getAppTempDirectory();
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          var screenWidth = MediaQuery.of(context).size.width;
          var screenHeight = MediaQuery.of(context).size.height;

          if (orientation == Orientation.portrait) {
            isLandscape = false;
            newVideoSizeWidth =
                screenWidth > videoWidth ? videoWidth : screenWidth;
            newVideoSizeHeight = videoHeight * newVideoSizeWidth / videoWidth;
          } else {
            isLandscape = true;
            newVideoSizeHeight =
                screenHeight > videoHeight ? videoHeight : screenHeight;
            newVideoSizeWidth = videoWidth * newVideoSizeHeight / videoHeight;
          }

          return Container(
            color: Colors.black,
            child: StreamBuilder(
              stream: widget.channel.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  );
                } else {
                  if(isRecording){
                    VideoUtil.saveImageFileToDirectory(snapshot.data, 'image_$frameNum.jpg');
                    frameNum++;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          SizedBox(height: isLandscape ? 0 : 30),
                          Stack(
                            children: <Widget>[
                              RepaintBoundary(
                                key: globalKey,
                                child: GestureZoomBox(
                                  maxScale: 5.0,
                                  doubleTapScale: 2.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Image.memory(snapshot.data,
                                      gaplessPlayback: true,
                                      width: newVideoSizeWidth,
                                      height: newVideoSizeHeight),
                                ),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: isLandscape ? 0 : 30),
                                      const Text(
                                        'ESP32 CAM',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w300),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Live | $timeString',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300),
                                      ),
                                      const SizedBox(height: 16),
                                      isRecording? const BlinkingTimer():Container(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: Colors.black,
                              width: MediaQuery.of(context).size.width,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    IconButton(
                                        onPressed: () async {
                                          final image = await controller
                                              .captureFromWidget(Image.memory(
                                                  snapshot.data,
                                                  gaplessPlayback: true,
                                                  width: newVideoSizeWidth,
                                                  height: newVideoSizeHeight));
                                          // ignore: unnecessary_null_comparison
                                          if (image == null) return;

                                          await saveImage(image);
                                        },
                                        icon: const Icon(
                                          Icons.photo_camera,
                                          size: 24,
                                        )),
                                    IconButton(
                                        onPressed:
                                            videoRecording,
                                        icon: Icon(isRecording? Icons.stop: Icons.videocam,
                                            size: 24)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: getFab(),
    );
  }
}

Future<String> saveImage(Uint8List bytes) async {
  await [Permission.storage].request();

  final time = DateTime.now()
      .toIso8601String()
      .replaceAll('.', '-')
      .replaceAll(':', '-');
  final name = 'screenshot_$time';
  final result = await ImageGallerySaver.saveImage(bytes, name: name);

  Fluttertoast.showToast(
      msg: "ScreenShot Saved",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);

  return result['filePath'];
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('MM/dd hh:mm:ss aaa').format(dateTime);
}