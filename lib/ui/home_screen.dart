import 'package:flutter/material.dart';

import '../domain/flag_id.dart';

import '../domain/flag_item.dart';
import '../domain/flag_catalog.dart';
import '../domain/flag_preferences.dart';
import '../domain/flag_preferences_store.dart';
import 'flag_screen.dart';
import 'brand_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/flag_localization.dart';
import '../platform/flag_mode_platform.dart';
import 'flag_mode_controller.dart';
import 'home/country_row.dart';
import 'home/home_intro.dart';
import 'home/home_rows.dart';
import 'home/home_states.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.preferencesStore,
    this.onThemeChanged,
    this.onLanguageChanged,
    this.flagModePlatform = const NativeFlagModePlatform(),
  });
  final FlagCatalog repository;
  final FlagPreferencesStore preferencesStore;
  final ValueChanged<ThemePreference>? onThemeChanged;
  final ValueChanged<LanguagePreference>? onLanguageChanged;
  final FlagModePlatform flagModePlatform;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<List<FlagItem>> _items;
  List<FlagItem>? _loaded;
  FlagSection? _selectedSection;
  final _search = TextEditingController();
  FlagItem? _selected;
  bool _quickPresentation = false;
  bool? _fullscreen;
  late final FlagModeController _flagMode;
  late AppLifecycleState _lifecycle;
  bool _platformSyncScheduled = false;
  FlagPreferences _preferences = FlagPreferences();
  Future<void> _saveQueue = Future.value();
  int _saveRevision = 0;
  bool _saveFailed = false;

  Future<List<FlagItem>> _load() async {
    final items = await widget.repository.loadFlags();
    final saved = await widget.preferencesStore.load(
      availableIds: items.map((item) => item.id).toSet(),
    );
    _preferences = saved.validFor(items.map((item) => item.id).toSet());
    if (!mounted) return items;
    // Theme System is a real choice that follows the OS live. Language System
    // is still resolved once: the language menu only offers concrete languages.
    final platform = WidgetsBinding.instance.platformDispatcher;
    if (_preferences.language == LanguagePreference.system) {
      _preferences = _preferences.withLanguage(
        platform.locales.firstOrNull?.languageCode == 'es'
            ? LanguagePreference.spanish
            : LanguagePreference.english,
      );
    }
    if (saved.language != _preferences.language) _persist();
    if (mounted) widget.onThemeChanged?.call(_preferences.theme);
    if (mounted) widget.onLanguageChanged?.call(_preferences.language);
    _loaded = items;
    return items;
  }

  void _setQuickFlag(FlagId? id) {
    setState(() => _preferences = _preferences.withQuickFlag(id));
    _persist();
  }

  void _showQuickFlag(FlagItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = item;
      _selectedSection = null;
      _quickPresentation = true;
      _preferences = _preferences.select(item.id);
    });
    _persist();
  }

  void _select(FlagItem item, FlagSection section) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = item;
      _selectedSection = section;
      _preferences = _preferences.select(item.id);
    });
    _persist();
  }

  void _toggleFavorite(FlagItem item) {
    setState(() => _preferences = _preferences.toggleFavorite(item.id));
    _persist();
  }

  void _toggleQuickFlag(FlagItem item) =>
      _setQuickFlag(_preferences.quickFlag == item.id ? null : item.id);

  void _persist() {
    final snapshot = _preferences;
    final store = widget.preferencesStore;
    final revision = ++_saveRevision;
    // Queue immutable snapshots in tap order; a failed write must not stop later writes.
    _saveQueue = _saveQueue.then((_) async {
      try {
        await store.save(snapshot);
        if (mounted && revision == _saveRevision) {
          setState(() => _saveFailed = false);
        }
      } catch (_) {
        if (mounted && revision == _saveRevision) {
          setState(() => _saveFailed = true);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _flagMode = FlagModeController(widget.flagModePlatform);
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _items = _load();
    WidgetsBinding.instance.addObserver(this);
  }

  void _schedulePlatformSync() {
    if (_platformSyncScheduled) return;
    _platformSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _platformSyncScheduled = false;
      if (!mounted) return;
      _flagMode.update(
        presenting: _fullscreen == true,
        lifecycle: _lifecycle,
        programmatic: _quickPresentation,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycle == state) return;
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      // Recompute orientation before re-entering: it may have changed off-screen.
      setState(() {});
      _schedulePlatformSync();
    } else {
      _flagMode.update(
        presenting: _fullscreen == true,
        lifecycle: state,
        programmatic: _quickPresentation,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    _flagMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final fullscreen = (landscape || _quickPresentation) && _selected != null;
    if (_fullscreen != fullscreen) {
      _fullscreen = fullscreen;
      _schedulePlatformSync();
    }
    final Widget view = fullscreen
        ? FlagScreen(
            key: const ValueKey('flag-view'),
            item: _selected!,
            onExit: _quickPresentation
                ? () => setState(() {
                    _quickPresentation = false;
                    _selected = null;
                  })
                : null,
          )
        : _listView(context);
    // List <-> flag is the one authored transition: a fade with a slight
    // settle-in scale for the flag. Instant with Remove animations.
    return AnimatedSwitcher(
      duration: AllFlagMotion.duration(context, AllFlagMotion.standard),
      reverseDuration: AllFlagMotion.duration(context, AllFlagMotion.quick),
      switchInCurve: AllFlagMotion.curve,
      switchOutCurve: AllFlagMotion.curve,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        if (child.key != const ValueKey('flag-view')) return fade;
        return ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: fade,
        );
      },
      child: view,
    );
  }

  Widget _listView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('list-view'),
      body: SafeArea(
        child: FutureBuilder<List<FlagItem>>(
          future: _items,
          initialData: _loaded,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return HomeLoadError(
                onRetry: () => setState(() {
                  _items = _load();
                }),
              );
            }
            if (!snapshot.hasData) return const HomeLoading();
            final quickItem = snapshot.data!
                .where((item) => item.id == _preferences.quickFlag)
                .firstOrNull;
            final query = normalizeSearch(_search.text);
            final items = localizedFlags(snapshot.data!, l10n, query: query);
            final rows = buildHomeRows(
              items,
              _preferences,
              searching: query.isNotEmpty,
            );
            return ListView.builder(
              padding: const EdgeInsets.all(BrandTokens.pagePadding),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: rows.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return HomeIntro(
                    preferences: _preferences,
                    search: _search,
                    onSearchChanged: () => setState(() {}),
                    onLanguageChanged: (language) {
                      setState(
                        () =>
                            _preferences = _preferences.withLanguage(language),
                      );
                      widget.onLanguageChanged?.call(language);
                      _persist();
                    },
                    onThemeChanged: (theme) {
                      setState(
                        () => _preferences = _preferences.withTheme(theme),
                      );
                      widget.onThemeChanged?.call(theme);
                      _persist();
                    },
                    quickItem: quickItem,
                    onShowQuickFlag: () => _showQuickFlag(quickItem!),
                    onToggleQuickFlag: () => _toggleQuickFlag(quickItem!),
                    saveFailed: _saveFailed,
                    onRetrySave: _persist,
                    selected: _selected,
                    noResults: items.isEmpty,
                  );
                }
                final row = rows[index - 1];
                final item = row.item;
                if (item == null) return SectionHeader(section: row.section);
                final selected = _selected?.id == item.id;
                return CountryRow(
                  item: item,
                  section: row.section,
                  favorite: _preferences.favorites.contains(item.id),
                  selected: selected,
                  announceSelection:
                      selected && _selectedSection == row.section,
                  isQuickFlag: _preferences.quickFlag == item.id,
                  onSelect: () => _select(item, row.section),
                  onToggleFavorite: () => _toggleFavorite(item),
                  onToggleQuickFlag: () => _toggleQuickFlag(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
