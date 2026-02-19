import 'package:flutter/material.dart';
import '../../features/subscriptions/data/service_model.dart';

class DefaultServices {
  static final List<ServiceModel> list = [
    ServiceModel(id: 'netflix', name: 'Netflix', colorValue: Colors.red.value, iconCodePoint: Icons.movie.codePoint),
    ServiceModel(id: 'youtube_premium', name: 'YouTube Premium', colorValue: Colors.red.value, iconCodePoint: Icons.play_circle_filled.codePoint),
    ServiceModel(id: 'amazon_prime', name: 'Amazon Prime Video', colorValue: Colors.blue.value, iconCodePoint: Icons.video_library.codePoint),
    ServiceModel(id: 'disney_plus', name: 'Disney+', colorValue: Colors.blueAccent.value, iconCodePoint: Icons.tv.codePoint),
    ServiceModel(id: 'hulu', name: 'Hulu', colorValue: Colors.green.value, iconCodePoint: Icons.live_tv.codePoint),
    ServiceModel(id: 'hbo_max', name: 'HBO Max', colorValue: Colors.purple.value, iconCodePoint: Icons.movie_filter.codePoint),
    ServiceModel(id: 'apple_tv', name: 'Apple TV+', colorValue: Colors.grey.value, iconCodePoint: Icons.apple.codePoint),
    ServiceModel(id: 'spotify', name: 'Spotify', colorValue: Colors.green.value, iconCodePoint: Icons.music_note.codePoint),
    ServiceModel(id: 'apple_music', name: 'Apple Music', colorValue: Colors.redAccent.value, iconCodePoint: Icons.music_note.codePoint),
    ServiceModel(id: 'google_one', name: 'Google One', colorValue: Colors.blue.value, iconCodePoint: Icons.cloud.codePoint),
    ServiceModel(id: 'dropbox', name: 'Dropbox', colorValue: Colors.blue.value, iconCodePoint: Icons.cloud_queue.codePoint),
    ServiceModel(id: 'slack', name: 'Slack', colorValue: Colors.purple.value, iconCodePoint: Icons.work.codePoint),
    ServiceModel(id: 'zoom', name: 'Zoom', colorValue: Colors.blue.value, iconCodePoint: Icons.video_call.codePoint),
    ServiceModel(id: 'chatgpt', name: 'ChatGPT Plus', colorValue: Colors.teal.value, iconCodePoint: Icons.smart_toy.codePoint),
    ServiceModel(id: 'github', name: 'GitHub Copilot', colorValue: Colors.black.value, iconCodePoint: Icons.code.codePoint),
  ];
}
