import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/mock_videos.dart';

import '../constants/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education'),
      ),
      body: ListView.builder(
        itemCount: mockVideos.length,
        itemBuilder: (context, index) {
          final video = mockVideos[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Image.network(
                  video.thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                ListTile(
                  title: Text(video.title),
                  subtitle: Text(video.description),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 