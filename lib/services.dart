import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ChannelService {
  static const String _channelOrderKey = 'channel_order';

  Future<List<Channel>> loadChannels() async {
    try {
      return await _loadChannelsFromFile();
    } catch (e) {
      debugPrint('Kanal yükleme hatası: $e');
      return [];
    }
  }

  Future<List<Channel>> _loadChannelsFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/channels.txt');
    String content;
    if (await file.exists()) {
      content = await file.readAsString();
    } else {
      content = await rootBundle.loadString('channels.txt');
      try {
        await file.writeAsString(content);
      } catch (e) {
        debugPrint('Kanallar yerel dosyaya kopyalanamadı: $e');
      }
    }
    return parseChannels(content);
  }

  List<Channel> parseChannels(String content) {
    final List<Channel> channels = [];
    
    final lines = content.split('\n');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith("{'name'") || line.startsWith('{"name"')) {
        try {
          var jsonStr = line
              .replaceAll("'", '"')
              .replaceAll(',}', '}')
              .trim();

          if (jsonStr.endsWith(',')) {
            jsonStr = jsonStr.substring(0, jsonStr.length - 1);
          }

          final json = jsonDecode(jsonStr);
          final channel = Channel.fromJson(json);
          channels.add(channel);
        } catch (e) {
          debugPrint('Kanal parse hatası: $e, satır: $line');
        }
      }
    }
    
    return channels;
  }

  Future<List<Channel>> getOrderedChannels(List<Channel> allChannels) async {
    final prefs = await SharedPreferences.getInstance();
    final orderList = prefs.getStringList(_channelOrderKey);
    
    if (orderList == null || orderList.isEmpty) {
      return allChannels;
    }
    
    // Kaydedilen sırayla kanalları döndür, sonra yeni kanalları sona ekle
    final orderedChannels = <Channel>[];
    final remainingChannels = List<Channel>.from(allChannels);
    for (final name in orderList) {
      try {
        final channel = remainingChannels.firstWhere((ch) => ch.name == name);
        orderedChannels.add(channel);
        remainingChannels.remove(channel);
      } catch (e) {
        // Kanal artık listede yoksa onu atla
      }
    }
    orderedChannels.addAll(remainingChannels);
    return orderedChannels;
  }

  Future<void> saveChannelOrder(List<String> channelNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_channelOrderKey, channelNames);
  }

  Future<void> clearChannelOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_channelOrderKey);
  }

  static String extractYoutubeVideoId(String youtubeUrl) {
    try {
      final uri = Uri.parse(youtubeUrl);
      if (youtubeUrl.contains('youtube.com')) {
        return uri.queryParameters['v'] ?? '';
      } else if (youtubeUrl.contains('youtu.be')) {
        return youtubeUrl.split('/').last;
      }
    } catch (e) {
      debugPrint('YouTube video ID çıkarma hatası: $e');
    }
    return '';
  }
}
