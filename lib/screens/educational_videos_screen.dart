import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class EducationalVideosScreen extends StatefulWidget {
  const EducationalVideosScreen({super.key});

  @override
  State<EducationalVideosScreen> createState() => _EducationalVideosScreenState();
}

class _EducationalVideosScreenState extends State<EducationalVideosScreen> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'First Aid',
      'icon': FontAwesomeIcons.heartPulse,
      'videos': [
        {
          'title': 'Basic CPR Training',
          'youtubeId': 'ea1RJUOiNfQ', // First video link
          'duration': '15:30',
          'views': '1.2M',
        },
        {
          'title': 'Build Your 1st Aid Kit',
          'youtubeId': '8assGpZvwG4', // Second video link
          'duration': '12:45',
          'views': '850K',
        },
      ],
    },
    {
      'name': 'Health Education',
      'icon': FontAwesomeIcons.bookMedical,
      'videos': [
        {
          'title': 'Improving Your Health',
          'youtubeId': 'EymMLXah2CA', // Third video link
          'duration': '10:20',
          'views': '500K',
        },
        {
          'title': 'Improve Your Diet',
          'youtubeId': 'pkzunP1s6cY', // Fourth video link
          'duration': '18:15',
          'views': '300K',
        },
      ],
    },
    {
      'name': 'Emergency Care',
      'icon': FontAwesomeIcons.truckMedical,
      'videos': [
        {
          'title': 'Emergency Response Training',
          'youtubeId': 'td0AJjUWIpc', // Fifth video link
          'duration': '20:00',
          'views': '750K',
        },
        {
          'title': 'Handling Medical Emergencies',
          'youtubeId': '8TYTQlavbvs', // Sixth video link (shorts)
          'duration': '25:30',
          'views': '600K',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Educational Videos',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Education Videos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 16),
            const Text(
              'Learn about health, wellness, and medical procedures through our educational videos.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = _categories[categoryIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          category['icon'],
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: category['videos'].length,
                      itemBuilder: (context, videoIndex) {
                        final video = category['videos'][videoIndex];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(video['title']),
                                    ),
                                    body: YoutubePlayerScaffold(
                                      controller: YoutubePlayerController(
                                        params: const YoutubePlayerParams(
                                          showControls: true,
                                          showFullscreenButton: true,
                                        ),
                                      )..loadVideoById(videoId: video['youtubeId']),
                                      builder: (context, player) => Column(
                                        children: [
                                          player,
                                          const SizedBox(height: 16),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              video['title'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: YoutubePlayer(
                                    controller: YoutubePlayerController(
                                      params: const YoutubePlayerParams(
                                        showControls: false,
                                        showFullscreenButton: false,
                                        mute: true,
                                      ),
                                    )..loadVideoById(videoId: video['youtubeId']),
                                    aspectRatio: 16 / 9,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            video['duration'],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            video['views'],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 