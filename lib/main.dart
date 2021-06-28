
import 'dart:convert';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart' as scanner;
import 'package:share/share.dart';
// import 'package:image/image.dart' as Image;


//todo reduce apk size.

Color accentColor = Colors.yellow[800];
// final Color textColor = Colors.white;
final Color textColor = Colors.black;
final Color BGcolor = Colors.black12;
final myController = new TextEditingController();
final GlobalKey globalKey = GlobalKey();
Directory AppDirectory;
String ScannedText = "None";
final snackBar = SnackBar(content: Text("copied to Clipboard"));


Future<Uint8List> _capture(GlobalKey globalKey) async {
  RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngbytes = byteData.buffer.asUint8List();
  var bs64 = base64Encode(pngbytes);
  // print(bs64);
  return pngbytes;
}

Future _getPermission(Permission permission) async {
  print(await permission.status);
  if (await permission.status.isGranted) {
    return;
  } else if (await permission.status.isPermanentlyDenied) {
  } else {
    await permission.request();
  }
}


Widget _buildPopupDialog(BuildContext context, String QRtext, String Path) {
  int max_length = 6;
  if (QRtext.length > max_length){
    QRtext = QRtext.substring(0,max_length)+"...";
  }
  return new AlertDialog(
    title: const Text(
      'QR code saved successfully',
    ),
    content: new Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "QR code for '$QRtext' saved at \n$Path",
        ),
      ],
    ),
    actions: <Widget>[
      new TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },

        child: const Text('Close'),
      ),
    ],
  );
}

Future<int> _getFileNumber() async {

  Directory directory = AppDirectory;
  File file;
  file = File(directory.path + "/NumberData.uul");
  if (!await file.exists()) {
    file = await File(directory.path + "/NumberData.uul").create(recursive: true);
    await file.writeAsString('0');
  }

  var text = await file.readAsString();
  int ans = int.parse(text.trim())+1;
  await file.writeAsString(ans.toString());
  return ans;
}


class MenuPage extends StatefulWidget {
  const MenuPage({Key key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class QRgeneratePage extends StatefulWidget {

  const QRgeneratePage({Key key}) : super(key: key);

  @override
  _QRgeneratePageState createState() => _QRgeneratePageState();
}

void main() => runApp(Home());

class Home extends StatelessWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (context) => MenuPage(),
          '/create': (context) => QRgeneratePage(),
          '/result':(context) => ScannedResultPage()
        }
    );
  }
}



class _MenuPageState extends State<MenuPage> {

  Future<void> ScanQRcode() async {
    try {
      var QRcodeText = await scanner.FlutterBarcodeScanner.scanBarcode(
          "#ffffff", "Cancel", true, scanner.ScanMode.QR);

      setState(() {
        ScannedText = QRcodeText;
      });
      print(ScannedText);
    }catch(e){
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BGcolor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Scan or Create QR code",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: accentColor,
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 200.0),
          Center(
            child: FloatingActionButton.extended(
              heroTag: "btn_scan",
              // onPressed: (){
              //   Navigator.pushNamed(context, '/result');
              // },
              onPressed: () async {
                await _getPermission(Permission.camera);
                await ScanQRcode();
                Navigator.pushNamed(context, '/result');
              },
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.all(Radius.circular(12.0))
              // ),
              backgroundColor: accentColor,
              icon: Icon(Icons.camera, color: textColor,),
              label: Text(
                "Scan QR code",
                style: TextStyle(
                    fontSize: 18.0,
                    color: textColor
                ),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          FloatingActionButton.extended(
            heroTag: "btn_create",
            onPressed: (){
              Navigator.pushNamed(context, '/create');
            },
            backgroundColor: accentColor,
            icon: Icon(Icons.qr_code_outlined, color: textColor,),
            label: Text(
              "Create QR code",
              style: TextStyle(
                  color: textColor,
                  fontSize: 18.0
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _QRgeneratePageState extends State<QRgeneratePage> {

  Future<void> _createAppDirectory() async {
    Directory directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      // print(directory);
      List<String> paths = directory.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/QRapp";
      directory = Directory(newPath);
      AppDirectory = directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }catch (e) {
      print(e);
    }

  }


  Future<String> storeImage(Uint8List pngBytes, String filename) async {
    Directory directory;

    directory = AppDirectory;
    File qr_file = File(directory.path + "/$filename");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    if (await directory.exists()) {
      try{
        await qr_file.writeAsBytes(pngBytes);
      }catch(e){
        print("Something happened on file write");
        print(e);
      }
    }
    return directory.path + "/$filename";

  }


  String _showStringInput(String text, int max_length) {

    if(text.length <= max_length){
      return text;
    }else{
      return text.substring(0,max_length) +"...";
    }
  }


  String fieldText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BGcolor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: accentColor,

        title: Text(
          "Generate QR code",
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
      ),

      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0,30.0,20.0,0.0),
            child: Column(

              children: [
                Container(
                  // padding: EdgeInsets.only(top: 10.0),
                  child: TextField(
                    cursorColor: accentColor,
                    cursorHeight: 22.0,
                    // controller: myController,
                    style: TextStyle(
                        fontSize: 20.0,
                        height: 1,
                        color: accentColor
                    ),
                    decoration: InputDecoration(
                      labelText: "Text",
                      enabledBorder: OutlineInputBorder(
                          borderSide: new BorderSide(
                            color: accentColor,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(60.0))
                      ),
                      labelStyle: TextStyle(
                        color: accentColor,
                      ),
                      hintText: "Enter your Text",
                      focusColor: accentColor,
                      filled: false,
                      fillColor: Colors.transparent,
                      prefixIcon: Icon(
                        Icons.qr_code_outlined,
                        color: accentColor,
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: new BorderSide(
                            color: accentColor,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(60.0))
                      ),
                    ),

                    onChanged: (String text) {
                      print("The text now : $text");
                      setState(() {
                        fieldText = text;
                      });
                    },
                  ),
                ),

                SizedBox(height: 30.0),

                Column(
                  children: [
                    RepaintBoundary(
                      key: globalKey,
                      child: Container(
                        height: 250.0,
                        width: 250.0,
                        child: QrImage(
                          data: (fieldText == ""?"QR Code":fieldText),
                          version: QrVersions.auto,
                          size: 320,
                          gapless: true,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8.0, 3.0, 8.0, 6.0),
                      height: 30.0,
                      width: 200.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(0),
                            bottom: Radius.circular(40.0)
                        ),
                        color: Colors.grey[850],
                      ),
                      child: Text(
                        _showStringInput((fieldText == ""?"QR Code":fieldText), 15),
                        style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ],
                ),



                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 30.0),
                      child: FloatingActionButton.extended(
                        onPressed: () async {

                          await _getPermission(Permission.storage);
                          final pngBytes = await _capture(globalKey);
                          await _createAppDirectory();
                          var filePath = await storeImage(pngBytes, "_share.png");
                          print("filePath - $filePath");
                          await Share.shareFiles([filePath]);
                          var dir = File(filePath);
                          await dir.delete();
                        },
                        heroTag: "btn_share",
                        backgroundColor: accentColor,
                        icon: Icon(
                          Icons.share_rounded,
                          color: textColor,
                        ),
                        label: Text(
                          "Share",
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    // SizedBox(width: 40.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 30.0),
                      child: FloatingActionButton.extended(
                        onPressed: () async {
                          await _getPermission(Permission.storage);
                          final pngBytes = await _capture(globalKey);
                          await _createAppDirectory();
                          int fileNumber = await _getFileNumber();
                          var filePath = await storeImage(pngBytes, "QRimage$fileNumber.png");
                          print(filePath);
                          print("Done");
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                _buildPopupDialog(context, fieldText,  filePath),
                          );
                        },
                        heroTag: "btn_save",
                        backgroundColor: accentColor,
                        icon: Icon(
                          Icons.save_alt_rounded,
                          color: textColor,
                        ),
                        label: Text(
                          "Save",
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScannedResultPage extends StatelessWidget {
  const ScannedResultPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BGcolor,
      appBar:AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Scan Complete",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: accentColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0,30.0,20.0,0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  child: Text(
                    ScannedText,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                height: 300.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: Colors.grey[350],
                ),
              ),

              SizedBox(height: 30.0,),

              FloatingActionButton.extended(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ScannedText)).then((value) =>
                      ScaffoldMessenger.of(context).showSnackBar(snackBar));
                },
                label: Text(
                  "Copy Text",
                  style:TextStyle(
                    color: textColor,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: Icon(Icons.copy, color: textColor),
                backgroundColor: accentColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
