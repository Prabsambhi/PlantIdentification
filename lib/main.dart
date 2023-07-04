import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';

void main() {
  runApp(PlantDetectionApp());
}

class PlantDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Detection',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PlantDetectionPage(),
    );
  }
}

class PlantDetectionPage extends StatefulWidget {
  @override
  _PlantDetectionPageState createState() => _PlantDetectionPageState();
}

class _PlantDetectionPageState extends State<PlantDetectionPage> {
  final ImagePicker _imagePicker = ImagePicker();
  String _plantName = '';
  double _confidence = 0.0;
  List<String> _commonNames = [];
  String _description = '';
  bool _isLoading = false;

  Future<void> _identifyPlant() async {
    setState(() {
      _isLoading = true;
      _plantName = '';
      _confidence = 0.0;
      _commonNames.clear();
      _description = '';
    });

    final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    final imageBytes = await pickedImage.readAsBytes();

    final apiUrl = Uri.parse('https://api.plant.id/v2/identify');
    final headers = {
      'Content-Type': 'application/json',
      'Api-Key': '2KY2Y1gpQPoSidDPUD2cozPBW2xpMSVwxSMEmfMhj9fAxdS7Mk',
    };
    final request = {
      'images': [base64Encode(imageBytes)],
      'organs': ['flower', 'leaf'],
      'organs_details': ['flower', 'leaf'],
    };

    final response =
        await http.post(apiUrl, headers: headers, body: jsonEncode(request));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _plantName = data['suggestions'][0]['plant_name'];
        _confidence = data['suggestions'][0]['probability'];
        _commonNames =
            data['suggestions'][0]['plant_details']['common_names'] != null
                ? List<String>.from(
                    data['suggestions'][0]['plant_details']['common_names'])
                : [];
        _description =
            data['suggestions'][0]['plant_details']['wiki_description'] ?? '';
      });
    } else {
      // Handle API error
      print(response.statusCode);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _identifyPlant,
                child: Text('Select Image'),
              ),
            SizedBox(height: 16),
            if (_plantName.isNotEmpty)
              Text(
                'Plant: $_plantName',
                style: TextStyle(fontSize: 20),
              ),
            if (_confidence > 0.0)
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 16),
              ),
            if (_commonNames.isNotEmpty)
              Text(
                'Common Names: ${_commonNames.join(", ")}',
                style: TextStyle(fontSize: 16),
              ),
            if (_description.isNotEmpty)
              Text(
                'Description: $_description',
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
