import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/posts'));

      if (response.statusCode == 200) {
        setState(() {
          posts = jsonDecode(response.body);
        });
      } else {
        print('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final imageUrl = post['image'] != null
              ? '${ApiConfig.baseUrl}/uploads/${post['image']}'
              : null;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text("Lyra Mae Borling", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("July 1 2024"),
                  trailing: Icon(Icons.more_horiz),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['subtext'] ?? ''),
                      SizedBox(height: 4),
                      if ((post['subtext'] ?? '').contains('#'))
                        Text(
                          _extractHashtag(post['subtext']),
                          style: TextStyle(color: Colors.blue),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                if (imageUrl != null)
                  Image.network(imageUrl, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.thumb_up, color: Colors.purple, size: 20),
                        SizedBox(width: 5),
                        Text("777"),
                      ]),
                      Text("111 Comments · 50 Shares"),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _postAction(Icons.thumb_up_alt_outlined, 'Like'),
                      _postAction(Icons.comment_outlined, 'Comment'),
                      _postAction(Icons.share_outlined, 'Share'),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _postAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  String _extractHashtag(String text) {
    final regex = RegExp(r"#\w+");
    final match = regex.firstMatch(text);
    return match != null ? match.group(0)! : '';
  }
}
