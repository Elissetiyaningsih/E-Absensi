import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class AddDramaPage extends StatefulWidget {
  @override
  _AddDramaPageState createState() => _AddDramaPageState();
}

class _AddDramaPageState extends State<AddDramaPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _synopsisController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _castController = TextEditingController();
  final TextEditingController _extraController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveDrama() {
    String title = _titleController.text;
    String thumbnail = _thumbnailController.text;
    String rating = _ratingController.text;
    String country = _countryController.text;
    String synopsis = _synopsisController.text;
    String videoUrl = _videoUrlController.text;
    String genre = _genreController.text;
    String cast = _castController.text;
    String extra = _extraController.text;

    if (title.isEmpty || thumbnail.isEmpty || rating.isEmpty || synopsis.isEmpty || videoUrl.isEmpty || genre.isEmpty || cast.isEmpty || extra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields must be filled in!')),
      );
      return;
    }

    _firestore.collection('dramas').add({
      'title': title,
      'thumbnail': thumbnail,
      'rating': rating,
      'country': country,
      'synopsis': synopsis,
      'videoUrl': videoUrl,
      'genre': genre,
      'cast': cast,
      'extra': extra,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Drama'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Tittle')),
            TextField(controller: _thumbnailController, decoration: InputDecoration(labelText: 'Thumbnail URL')),
            TextField(controller: _ratingController, decoration: InputDecoration(labelText: 'Rating')),
            TextField(controller: _countryController, decoration: InputDecoration(labelText: 'Country')),
            TextField(controller: _synopsisController, decoration: InputDecoration(labelText: 'Synopsis')),
            TextField(controller: _videoUrlController, decoration: InputDecoration(labelText: 'Video URL')),
            TextField(controller: _genreController, decoration: InputDecoration(labelText: 'Genre')),
            TextField(controller: _castController, decoration: InputDecoration(labelText: ' Cast')),
            TextField(controller: _extraController, decoration: InputDecoration(labelText: '')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveDrama, child: Text('Save Drama')),
          ],
        ),
      ),
    );
  }
}


class FavoritesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorite Dramas')),
      body: StreamBuilder(
        stream: _firestore.collection('favorites').where('userId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorite drama yet'));
          }

          var favorites = snapshot.data!.docs;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              var drama = favorites[index].data();
              return ListTile(
                leading: Image.network(drama['thumbnail'], width: 50, height: 50, fit: BoxFit.cover),
                title: Text(drama['title']),
                subtitle: Text('Type: ${drama['genre']}'),
              );
            },
          );
        },
      ),
    );
  }
}
