class Channel {
  final String name;
  final String? url;
  final String quality;
  final String? youtube;
  final bool isCustom;

  Channel({
    required this.name,
    this.url,
    required this.quality,
    this.youtube,
    this.isCustom = false,
  });

  bool get isYoutube => youtube != null && youtube!.isNotEmpty;
  bool get isM3u8 => url != null && url!.isNotEmpty;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json['name'] as String,
      url: json['url'] as String?,
      quality: json['quality'] as String? ?? '',
      youtube: json['youtube'] as String?,
      isCustom: json['custom'] == true || json['custom'] == 'true' ||
          json['isCustom'] == true || json['isCustom'] == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'quality': quality,
    'youtube': youtube,
    'custom': isCustom,
  };
}
