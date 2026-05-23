import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models.dart';
import 'services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  WakelockPlus.enable();
  runApp(const MyApp());
}

enum AppLanguage { turkish, english }

extension AppLanguageExtension on AppLanguage {
  String get code => this == AppLanguage.english ? 'en' : 'tr';
  String get label => this == AppLanguage.english ? 'English' : 'Türkçe';
}

class AppStrings {
  final AppLanguage language;

  AppStrings(this.language);

  static AppStrings of(BuildContext context) =>
      AppLanguageProvider.of(context).strings;

  String get channelNotFound =>
      language == AppLanguage.english ? 'No channel found' : 'Kanal bulunamadı';
  String get channelLoading => language == AppLanguage.english
      ? 'Loading channel...'
      : 'Kanal yükleniyor...';
  String invalidChannel(String name) => language == AppLanguage.english
      ? 'Invalid channel: $name'
      : 'Geçersiz kanal: $name';
  String get invalidYoutubeUrl => language == AppLanguage.english
      ? 'Invalid YouTube URL'
      : 'Geçersiz YouTube URLsi';
  String invalidYoutubeUrlWithValue(String url) =>
      language == AppLanguage.english
      ? 'Invalid YouTube URL: $url'
      : 'Geçersiz YouTube URLsi: $url';
  String get youtubeLoadError => language == AppLanguage.english
      ? 'Error loading YouTube'
      : 'YouTube yüklenirken hata oluştu';
  String get okMenu =>
      language == AppLanguage.english ? 'OK: Menu' : 'OK: Menü';
  String get rightOkSort =>
      language == AppLanguage.english ? 'Right OK: Sort' : 'Sağ OK: Sırala';
  String get rightOkSortLeftArrowAddYoutube => language == AppLanguage.english
      ? 'Right OK: Sort'
      : 'Sağ OK: Sırala';
  String get channels =>
      language == AppLanguage.english ? 'Channels' : 'Kanallar';
  String get selectChannelsToOrder => language == AppLanguage.english
      ? 'Select channels to order'
      : 'Sıralanacak kanalları seç';
  String selectedCount(int count) => language == AppLanguage.english
      ? 'Selected: $count'
      : 'Seçilenler: $count';
  String get rightOkSortLeftOkExit => language == AppLanguage.english
      ? 'Right OK: Sort, Left OK: Exit'
      : 'Sağ OK: Sırala, Sol OK: Çıkış';
  String get orderAllChannels => language == AppLanguage.english
      ? 'Order within all channels'
      : 'Tüm kanallar içinde sıralama';
  String get moveSelectedChannelsUpDown => language == AppLanguage.english
      ? 'Move selected channels up/down'
      : 'Seçili kanalları yukarı/aşağı hareket ettir';
  String get okSaveLeftOkBack => language == AppLanguage.english
      ? 'OK: Save | Left OK: Back'
      : 'OK: Kaydet | Sol OK: Geri';
  String get chooseLanguage =>
      language == AppLanguage.english ? 'Choose language' : 'Dil seçin';
  String get changeLanguage =>
      language == AppLanguage.english ? 'Change language' : 'Dili değiştir';
}

class AppLanguageProvider extends InheritedWidget {
  final AppLanguage language;
  final AppStrings strings;

  const AppLanguageProvider({
    super.key,
    required this.language,
    required this.strings,
    required super.child,
  });

  static AppLanguageProvider of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<AppLanguageProvider>();
    assert(provider != null, 'No AppLanguageProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(covariant AppLanguageProvider oldWidget) {
    return oldWidget.language != language;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppLanguage _language = AppLanguage.turkish;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('selectedLanguage');
    if (stored == AppLanguage.english.code) {
      _language = AppLanguage.english;
    } else if (stored == AppLanguage.turkish.code) {
      _language = AppLanguage.turkish;
    }
    setState(() {});

    if (stored == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLanguageSelectionDialog();
        }
      });
    }
  }

  Future<void> _setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language.code);
    setState(() {
      _language = language;
    });
  }

  void _showLanguageSelectionDialog() {
    final dialogContext = _navigatorKey.currentContext ?? context;
    showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) {
        return LanguageSelectionDialog(
          onSelected: (language) {
            _setLanguage(language);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Adamakıllı TV',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      builder: (context, child) {
        return AppLanguageProvider(
          language: _language,
          strings: AppStrings(_language),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}

class LanguageSelectionDialog extends StatefulWidget {
  final void Function(AppLanguage language) onSelected;

  const LanguageSelectionDialog({super.key, required this.onSelected});

  @override
  State<LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  int _selectedIndex = 0;
  final _options = AppLanguage.values;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      child: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1) % _options.length;
            });
            return KeyEventResult.handled;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            setState(() {
              _selectedIndex =
                  (_selectedIndex - 1 + _options.length) % _options.length;
            });
            return KeyEventResult.handled;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.select) ||
              event.isKeyPressed(LogicalKeyboardKey.enter)) {
            widget.onSelected(_options[_selectedIndex]);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dil seçin / Choose language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < _options.length; index++)
                GestureDetector(
                  onTap: () => widget.onSelected(_options[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: index == _selectedIndex
                          ? Colors.blue
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _options[index].label,
                      style: TextStyle(
                        color: index == _selectedIndex
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChannelService _channelService = ChannelService();
  late Future<List<Channel>> _channelsFuture;
  late FocusNode _focusNode;
  List<Channel> _channels = [];
  Channel? _currentChannel;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _channelsFuture = _channelService.loadChannels().then((channels) async {
      _channels = await _channelService.getOrderedChannels(channels);
      setState(() {
        if (_channels.isNotEmpty) {
          _currentChannel = _channels[0];
        }
      });
      return _channels;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isMenuKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
  }

  void _showChannelMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChannelMenuWidget(
        channels: _channels,
        initialChannel: _currentChannel,
        onChannelSelected: (channel) {
          setState(() {
            _currentChannel = channel;
          });
          Navigator.of(dialogContext).pop();
        },
        onOrderingMenuTap: () {
          Navigator.of(dialogContext).pop();
          _showChannelOrderingMenu();
        },
      ),
    );
  }

  void _showChannelOrderingMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChannelOrderingWidget(
        channels: _channels,
        channelService: _channelService,
        onOrderingSaved: (orderedChannels) {
          setState(() {
            _channels = orderedChannels;
            if (_currentChannel != null &&
                !_channels.contains(_currentChannel)) {
              _currentChannel = _channels.isNotEmpty ? _channels[0] : null;
            }
          });
        },
        onOrderingComplete: (orderedChannels) {
          setState(() {
            _channels = orderedChannels;
            if (_currentChannel != null &&
                !_channels.contains(_currentChannel)) {
              _currentChannel = _channels.isNotEmpty ? _channels[0] : null;
            }
          });
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<Channel>>(
      future: _channelsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(body: Center(child: Text(strings.channelNotFound)));
        }

        return Scaffold(
          body: Focus(
            autofocus: true,
            focusNode: _focusNode,
            onKey: (node, event) {
              if (_isMenuKey(event.logicalKey)) {
                if (event is RawKeyUpEvent) {
                  _showChannelMenu();
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: _currentChannel == null
                ? Center(child: Text(strings.channelLoading))
                : _buildPlayerUI(_currentChannel!),
          ),
        );
      },
    );
  }

  Widget _buildPlayerUI(Channel channel) {
    if (channel.isYoutube) {
      return YoutubePlayerWidget(
        key: ValueKey(channel.youtube ?? channel.name),
        channel: channel,
      );
    } else if (channel.isM3u8) {
      return M3u8PlayerWidget(
        key: ValueKey(channel.url ?? channel.name),
        channel: channel,
      );
    }
    return Center(
      child: Text(AppStrings.of(context).invalidChannel(channel.name)),
    );
  }
}

// YouTube oynatıcısı (WebView ile)
class YoutubePlayerWidget extends StatefulWidget {
  final Channel channel;

  const YoutubePlayerWidget({super.key, required this.channel});

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  YoutubePlayerController? _controller;
  String _videoId = '';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initYoutubeController();
  }

  @override
  void didUpdateWidget(covariant YoutubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel.youtube != oldWidget.channel.youtube) {
      _initYoutubeController();
    }
  }

  void _initYoutubeController() {
    _controller?.close();
    _hasError = false;
    _errorMessage = null;

    _videoId = ChannelService.extractYoutubeVideoId(
      widget.channel.youtube ?? '',
    );

    if (_videoId.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = AppStrings.of(context).invalidYoutubeUrl;
      });
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        privacyEnhancedMode: true,
        playsInline: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId.isEmpty) {
      return Center(
        child: Text(
          AppStrings.of(
            context,
          ).invalidYoutubeUrlWithValue(widget.channel.youtube ?? ''),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            '${AppStrings.of(context).youtubeLoadError}\n${_errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_controller != null)
          Positioned.fill(
            child: SizedBox.expand(
              child: YoutubePlayer(
                controller: _controller!,
                aspectRatio: MediaQuery.of(context).size.aspectRatio,
              ),
            ),
          ),
        if (_controller == null)
          const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 20,
          left: 20,
          child: Text(
            widget.channel.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Opacity(
            opacity: 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context).okMenu,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  AppStrings.of(context).rightOkSort,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// M3u8 oynatıcısı
class M3u8PlayerWidget extends StatefulWidget {
  final Channel channel;

  const M3u8PlayerWidget({super.key, required this.channel});

  @override
  State<M3u8PlayerWidget> createState() => _M3u8PlayerWidgetState();
}

class _M3u8PlayerWidgetState extends State<M3u8PlayerWidget> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _controllerCreated = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant M3u8PlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel.url != oldWidget.channel.url) {
      _initializePlayer();
    }
  }

  void _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    if (_controllerCreated) {
      await _videoController.dispose();
      _controllerCreated = false;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.url ?? ''),
      );
      _controllerCreated = true;
      await _videoController.initialize();
      _videoController.play();
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Video yükleme hatası: $e');
    }
  }

  @override
  void dispose() {
    if (_controllerCreated) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            AppStrings.of(context).invalidChannel(widget.channel.name),
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }
}

// Kanal menüsü widget'ı
class ChannelMenuWidget extends StatefulWidget {
  final List<Channel> channels;
  final Function(Channel) onChannelSelected;
  final VoidCallback onOrderingMenuTap;
  final Channel? initialChannel;
  final void Function(Channel)? onChannelAdded;
  final void Function(Channel)? onChannelRemoved;

  const ChannelMenuWidget({
    super.key,
    required this.channels,
    required this.onChannelSelected,
    required this.onOrderingMenuTap,
    this.initialChannel,
    this.onChannelAdded,
    this.onChannelRemoved,
  });

  @override
  State<ChannelMenuWidget> createState() => _ChannelMenuWidgetState();
}

class _ChannelMenuWidgetState extends State<ChannelMenuWidget> {
  int _selectedIndex = 0;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  static const double _itemExtent = 56.0;
  late List<Channel> _localChannels;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _scrollController = ScrollController();

    _localChannels = List.from(widget.channels);

    // If an initial channel is provided, set the selected index accordingly
    if (widget.initialChannel != null) {
      final idx = widget.channels.indexWhere(
        (c) => c.name == widget.initialChannel!.name,
      );
      if (idx != -1) {
        _selectedIndex = idx;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSelected(),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: 400,
            child: Focus(
              focusNode: _focusNode,
              onKey: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  if (event is RawKeyUpEvent && _localChannels.isNotEmpty) {
                    widget.onChannelSelected(_localChannels[_selectedIndex]);
                  }
                  return KeyEventResult.handled;
                }

                if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                  setState(() {
                    _selectedIndex =
                        (_selectedIndex + 1) % _localChannels.length;
                  });
                  _scrollToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                  setState(() {
                    _selectedIndex =
                        (_selectedIndex - 1 + _localChannels.length) %
                        _localChannels.length;
                  });
                  _scrollToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                  widget.onOrderingMenuTap();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        strings.channels,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemExtent: _itemExtent,
                        shrinkWrap: false,
                        itemCount: _localChannels.length,
                        itemBuilder: (context, index) {
                          final channel = _localChannels[index];
                          final isSelected = index == _selectedIndex;
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    channel.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    channel.quality.isNotEmpty
                                        ? channel.quality
                                        : 'HD',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        strings.rightOkSortLeftArrowAddYoutube,
                        style: TextStyle(color: Colors.yellow, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final target =
        _selectedIndex * _itemExtent -
        (MediaQuery.of(context).size.height / 2) +
        (_itemExtent / 2);
    final max = _scrollController.position.maxScrollExtent;
    final offset = target.clamp(0.0, max);
    _scrollController.animateTo(
      offset,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

}

// Kanal sıralama menüsü widget'ı
class ChannelOrderingWidget extends StatefulWidget {
  final List<Channel> channels;
  final ChannelService channelService;
  final Function(List<Channel>) onOrderingSaved;
  final Function(List<Channel>) onOrderingComplete;

  const ChannelOrderingWidget({
    super.key,
    required this.channels,
    required this.channelService,
    required this.onOrderingSaved,
    required this.onOrderingComplete,
  });

  @override
  State<ChannelOrderingWidget> createState() => _ChannelOrderingWidgetState();
}

enum OrderingStep { selection, ordering }

class _ChannelOrderingWidgetState extends State<ChannelOrderingWidget> {
  late List<Channel> _channelsCopy;
  late List<bool> _selected;
  OrderingStep _step = OrderingStep.selection;
  int _selectedIndex = 0;
  late FocusNode _focusNode;
  late ScrollController _selectScrollController;
  late ScrollController _orderScrollController;
  static const double _itemExtent = 56.0;

  @override
  void initState() {
    super.initState();
    _channelsCopy = List.from(widget.channels);
    _selected = List.filled(widget.channels.length, false);
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _selectScrollController = ScrollController();
    _orderScrollController = ScrollController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _selectScrollController.dispose();
    _orderScrollController.dispose();
    super.dispose();
  }

  List<Channel> get _selectedChannels {
    return [
      for (int i = 0; i < _channelsCopy.length; i++)
        if (_selected[i]) _channelsCopy[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_step == OrderingStep.selection) {
      return _buildSelectionStep();
    } else {
      return _buildOrderingStep();
    }
  }

  Widget _buildSelectionStep() {
    final strings = AppStrings.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 40),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: 380,
            child: Focus(
              focusNode: _focusNode,
              onKey: (node, event) {
                if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                  setState(() {
                    _selectedIndex =
                        (_selectedIndex + 1) % _channelsCopy.length;
                  });
                  _scrollSelectionToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                  setState(() {
                    _selectedIndex =
                        (_selectedIndex - 1 + _channelsCopy.length) %
                        _channelsCopy.length;
                  });
                  _scrollSelectionToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.select) ||
                    event.isKeyPressed(LogicalKeyboardKey.enter)) {
                  setState(() {
                    _selected[_selectedIndex] = !_selected[_selectedIndex];
                  });
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                  if (_selectedChannels.isNotEmpty) {
                    setState(() {
                      _step = OrderingStep.ordering;
                      _selectedIndex = _selected.indexWhere((v) => v);
                      if (_selectedIndex == -1) _selectedIndex = 0;
                    });
                    _focusNode.requestFocus();
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollOrderToSelected(),
                    );
                  }
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                  Navigator.pop(context);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        strings.selectChannelsToOrder,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _selectScrollController,
                        itemExtent: _itemExtent,
                        shrinkWrap: false,
                        itemCount: _channelsCopy.length,
                        itemBuilder: (context, index) {
                          final channel = _channelsCopy[index];
                          final isFocused = index == _selectedIndex;
                          final isChecked = _selected[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? Colors.blue.withOpacity(0.6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    isChecked ? '✓ ' : '  ',
                                    style: TextStyle(
                                      color: isChecked
                                          ? Colors.grey[300]
                                          : Colors.transparent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      channel.name,
                                      style: TextStyle(
                                        color: isFocused
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 16,
                                        fontWeight: isFocused
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text(
                            strings.selectedCount(_selectedChannels.length),
                            style: TextStyle(color: Colors.yellow),
                          ),
                          SizedBox(height: 5),
                          Text(
                            strings.rightOkSortLeftOkExit,
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderingStep() {
    final strings = AppStrings.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 40),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: 380,
            child: Focus(
              focusNode: _focusNode,
              onKey: (node, event) {
                if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                  if (_selected[_selectedIndex]) {
                    _moveSelectedChannels(1);
                  } else {
                    setState(() {
                      _selectedIndex =
                          (_selectedIndex + 1) % _channelsCopy.length;
                    });
                  }
                  _scrollOrderToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                  if (_selected[_selectedIndex]) {
                    _moveSelectedChannels(-1);
                  } else {
                    setState(() {
                      _selectedIndex =
                          (_selectedIndex - 1 + _channelsCopy.length) %
                          _channelsCopy.length;
                    });
                  }
                  _scrollOrderToSelected();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.select) ||
                    event.isKeyPressed(LogicalKeyboardKey.enter)) {
                  _saveOrdering();
                  return KeyEventResult.handled;
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                  setState(() {
                    _step = OrderingStep.selection;
                    _selectedIndex = _selected.indexWhere((v) => v);
                    if (_selectedIndex == -1) _selectedIndex = 0;
                  });
                  _focusNode.requestFocus();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollSelectionToSelected(),
                  );
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        strings.orderAllChannels,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _orderScrollController,
                        itemExtent: _itemExtent,
                        shrinkWrap: false,
                        itemCount: _channelsCopy.length,
                        itemBuilder: (context, index) {
                          final channel = _channelsCopy[index];
                          final isSelected = _selected[index];
                          final isFocused = index == _selectedIndex;
                          return Container(
                            color: isFocused
                                ? Colors.blueAccent
                                : Colors.transparent,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text(
                                        '✓',
                                        style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${index + 1}. ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      channel.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text(
                            strings.moveSelectedChannelsUpDown,
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            strings.okSaveLeftOkBack,
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollSelectionToSelected() {
    if (!_selectScrollController.hasClients) return;
    final target =
        _selectedIndex * _itemExtent -
        (MediaQuery.of(context).size.height / 2) +
        (_itemExtent / 2);
    final max = _selectScrollController.position.maxScrollExtent;
    final offset = target.clamp(0.0, max);
    _selectScrollController.animateTo(
      offset,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  void _scrollOrderToSelected() {
    if (!_orderScrollController.hasClients) return;
    final target =
        _selectedIndex * _itemExtent -
        (MediaQuery.of(context).size.height / 2) +
        (_itemExtent / 2);
    final max = _orderScrollController.position.maxScrollExtent;
    final offset = target.clamp(0.0, max);
    _orderScrollController.animateTo(
      offset,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  void _moveSelectedChannels(int direction) {
    if (direction == 0) return;
    final selectedIndices = [
      for (int i = 0; i < _channelsCopy.length; i++)
        if (_selected[i]) i,
    ];
    if (selectedIndices.isEmpty) return;

    if (direction < 0) {
      if (selectedIndices.first == 0) return;
      for (final index in selectedIndices) {
        final current = _channelsCopy[index];
        _channelsCopy[index] = _channelsCopy[index - 1];
        _channelsCopy[index - 1] = current;
        final currentSelected = _selected[index];
        _selected[index] = _selected[index - 1];
        _selected[index - 1] = currentSelected;
      }
      setState(() {
        _selectedIndex = selectedIndices.first - 1;
      });
    } else {
      if (selectedIndices.last == _channelsCopy.length - 1) return;
      for (int i = selectedIndices.length - 1; i >= 0; i--) {
        final index = selectedIndices[i];
        final current = _channelsCopy[index];
        _channelsCopy[index] = _channelsCopy[index + 1];
        _channelsCopy[index + 1] = current;
        final currentSelected = _selected[index];
        _selected[index] = _selected[index + 1];
        _selected[index + 1] = currentSelected;
      }
      setState(() {
        _selectedIndex = selectedIndices.last + 1;
      });
    }
  }

  void _saveOrdering() async {
    final orderedNames = [for (var channel in _channelsCopy) channel.name];
    await widget.channelService.saveChannelOrder(orderedNames);
    final orderedChannels = <Channel>[];
    for (final name in orderedNames) {
      try {
        final channel = widget.channels.firstWhere((ch) => ch.name == name);
        orderedChannels.add(channel);
      } catch (e) {
        // Kanal bulunamadıysa atla
      }
    }
    if (mounted) {
      widget.onOrderingSaved(orderedChannels);
      setState(() {
        _step = OrderingStep.selection;
        _selected = List.filled(_channelsCopy.length, false);
        _selectedIndex = 0;
      });
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollSelectionToSelected(),
      );
    }
  }
}
