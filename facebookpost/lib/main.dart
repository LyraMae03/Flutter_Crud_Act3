import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Post App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController _subtextController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  List posts = [];

  final _logger = Logger('PostPage');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<void> _createPost() async {
    if (_imageBytes == null || _subtextController.text.isEmpty) {
      _logger.warning('Image or Subtext is missing');
      return;
    }

    final uri = Uri.parse('http://localhost:3000/api/posts');
    final request = http.MultipartRequest('POST', uri);

    final imageFile = http.MultipartFile.fromBytes(
      'image',
      _imageBytes!,
      filename: _imageName ?? 'upload.jpg',
    );

    request.files.add(imageFile);
    request.fields['subtext'] = _subtextController.text;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _getPosts();
        setState(() {
          _imageBytes = null;
          _imageName = null;
          _subtextController.clear();
        });
        _logger.info('Post created successfully');
      } else {
        _logger.severe('Failed to create post. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error during post creation: $e');
    }
  }

  Future<void> _getPosts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/posts'));

      if (response.statusCode == 200) {
        setState(() {
          posts = json.decode(response.body);
        });
      } else {
        _logger.severe('Failed to load posts. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facebook Post App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _subtextController,
              decoration: InputDecoration(labelText: 'Subtext'),
            ),
            SizedBox(height: 16),
            _imageBytes == null
                ? IconButton(icon: Icon(Icons.image), onPressed: _pickImage)
                : Image.memory(_imageBytes!),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _createPost, child: Text('Create Post')),
            SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['subtext'],
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            post['created_at'],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (post['image'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'http://localhost:3000/uploads/${post['image']}',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
