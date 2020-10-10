import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mask Detection',
      home: MyHomePage(),
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isLoading = false;
  File fileImage;
  final listOutputs = [];

  // Di override untuk init model
  @override
  void initState(){
    isLoading = true;
    loadModel().then((value){
      setState(() => isLoading = false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Flutter Mask Detection'
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            fileImage == null ? Container() : Image.file(fileImage),
            SizedBox(height: 16),
            listOutputs.isNotEmpty ? Text('${listOutputs[0]['label']}'.replaceAll(RegExp(r'[0-9]'), ''),
              style: TextStyle(
                fontSize: 20,
                background: Paint()..color = Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : Text('Upload your image'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Button untuk mengambil gambar dari Camera
          FloatingActionButton(
            child: Icon(Icons.camera),
            tooltip: 'Take Picture From Camera',
            onPressed: () => pickImage(ImageSource.camera),
          ),
          SizedBox(height: 16),
          // Button untuk mengambil gambar dari Gallery
          FloatingActionButton(
            child: Icon(Icons.image),
            tooltip: 'Take Picture From Gallery',
            onPressed: () => pickImage(ImageSource.gallery),
          )
        ],
      ),
    );
  }

  // Fungsi untuk meng-load model
  Future loadModel() async{
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  // Fungsi yang digunakan untuk mengambil gambar
  void pickImage(ImageSource imageSource) async {
    var image = await ImagePicker().getImage(source: imageSource);
    if (image == null)
      return null;
    setState(() {
      isLoading = true;
      fileImage = File(image.path);
    });
    processImage(fileImage);
  }

  // Fungsi untuk proses Gambar ke model
  void processImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    // Seteleah Gambar terdeteksi listoutput dibersihkan
    setState(() {
      isLoading = false;
      listOutputs.clear();
      listOutputs.addAll(output);
      debugPrint('outputs: $listOutputs');
    });
  }
}
