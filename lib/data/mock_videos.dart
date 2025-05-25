class MockVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String description;

  MockVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.description,
  });
}

final List<MockVideo> mockVideos = [
  MockVideo(
    id: 'dQw4w9WgXcQ',
    title: 'Sample Video 1',
    thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    description: 'This is a sample video description 1',
  ),
  MockVideo(
    id: 'dQw4w9WgXcQ',
    title: 'Sample Video 2',
    thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    description: 'This is a sample video description 2',
  ),
  MockVideo(
    id: 'dQw4w9WgXcQ',
    title: 'Sample Video 3',
    thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    description: 'This is a sample video description 3',
  ),
]; 