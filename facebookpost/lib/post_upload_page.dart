import 'dart:convert';
import 'dart:html' as html show File, FileReader, FileUploadInputElement;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';

class PostUploadPage extends StatefulWidget {
  @override
  _PostUploadPageState createState() => _PostUploadPageState();
}

class _PostUploadPageState extends State<PostUploadPage> {
  final TextEditingController _captionController = TextEditingController();
  html.File? _selectedFile;
  String? _imagePreviewUrl;

  void _pickImage() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((e) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _selectedFile = file;
            _imagePreviewUrl = reader.result as String?;
          });
        });
      }
    });
  }

  Future<void> _uploadPost() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select an image first')));
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/posts/upload');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(_selectedFile!);

    reader.onLoadEnd.listen((event) async {
      final bytes = reader.result as List<int>;

      final request = http.MultipartRequest('POST', uri)
        ..fields['subtext'] = _captionController.text
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _selectedFile!.name,
          contentType: MediaType('image', _selectedFile!.type.split('/').last),
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post uploaded!')));
        setState(() {
          _selectedFile = null;
          _imagePreviewUrl = null;
          _captionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              decoration: InputDecoration(hintText: 'Enter a caption...'),
            ),
            SizedBox(height: 12),
            _imagePreviewUrl != null
                ? Image.network(_imagePreviewUrl!, height: 200)
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(child: Text('No image selected')),
                  ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo),
              label: Text('Select Image'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _uploadPost,
              child: Text('Upload Post'),
            ),
          ],
        ),
      ),
    );
  }
}
