import '../domain/flag_id.dart';

import 'package:flutter/material.dart';

import '../domain/flag_item.dart';
import '../domain/flag_catalog.dart';
import '../domain/flag_preferences.dart';
import '../domain/flag_preferences_store.dart';
import 'flag_screen.dart';
import 'brand_header.dart';
import 'brand_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/flag_localization.dart';
import '../platform/flag_mode_platform.dart';
import 'flag_mode_controller.dart';

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
    if (mounted) widget.onThemeChanged?.call(_preferences.theme);
    if (mounted) widget.onLanguageChanged?.call(_preferences.language);
    return items;
  }

  void _setQuickFlag(FlagId? id) {
    setState(() => _preferences = _preferences.withQuickFlag(id));
    _persist();
  }

  Widget _quickMenu(FlagItem item) {
    final l10n = AppLocalizations.of(context);
    final current = _preferences.quickFlag == item.id;
    return PopupMenuButton<bool>(
      tooltip: l10n.countryActions(item.displayName(l10n.localeName)),
      onSelected: (_) => _setQuickFlag(current ? null : item.id),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: true,
          child: Semantics(
            label: current
                ? l10n.removeQuickFlag
                : l10n.setQuickFlagLabel(item.displayName(l10n.localeName)),
            excludeSemantics: true,
            child: Text(current ? l10n.removeQuickFlag : l10n.setQuickFlag),
          ),
        ),
      ],
    );
  }

  void _showQuickFlag(FlagItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = item;
      _quickPresentation = true;
      _preferences = _preferences.select(item.id);
    });
    _persist();
  }

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
    final l10n = AppLocalizations.of(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final fullscreen = (landscape || _quickPresentation) && _selected != null;
    if (_fullscreen != fullscreen) {
      _fullscreen = fullscreen;
      _schedulePlatformSync();
    }
    if (fullscreen) {
      return FlagScreen(
        item: _selected!,
        onExit: _quickPresentation
            ? () => setState(() {
                _quickPresentation = false;
                _selected = null;
              })
            : null,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<FlagItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.loadError),
                    TextButton(
                      onPressed: () => setState(() {
                        _items = _load();
                      }),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final quickItem = snapshot.data!
                .where((item) => item.id == _preferences.quickFlag)
                .firstOrNull;
            final query = normalizeSearch(_search.text);
            final items = localizedFlags(snapshot.data!, l10n, query: query);
            final rows = <({String section, FlagItem? item})>[];
            void section(String title, Iterable<FlagItem> values) {
              if (values.isEmpty) return;
              rows.add((section: title, item: null));
              rows.addAll(values.map((item) => (section: title, item: item)));
            }

            if (query.isEmpty) {
              section(
                'Favorites',
                items.where((item) => _preferences.favorites.contains(item.id)),
              );
              final byId = {for (final item in items) item.id: item};
              section(
                'Recent',
                _preferences.recent
                    .map((code) => byId[code])
                    .whereType<FlagItem>(),
              );
              section('All Countries', items);
            } else {
              rows.addAll(items.map((item) => (section: 'search', item: item)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(BrandTokens.pagePadding),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: rows.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandHeader(
                        theme: _preferences.theme,
                        language: _preferences.language,
                        onLanguageChanged: (language) {
                          setState(
                            () => _preferences = _preferences.withLanguage(
                              language,
                            ),
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
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.chooseCountry),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.searchCountries,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.clearSearch,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(_search.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (quickItem != null)
                        Card(
                          key: const ValueKey('quick-flag-card'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.quickFlag,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    _quickMenu(quickItem),
                                  ],
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Image.asset(
                                    quickItem.asset,
                                    width: 48,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                  title: Text(
                                    quickItem.displayName(l10n.localeName),
                                  ),
                                  subtitle: Text(l10n.readyToDisplay),
                                ),
                                Semantics(
                                  container: true,
                                  label: l10n.showFlagLabel(
                                    quickItem.displayName(l10n.localeName),
                                  ),
                                  button: true,
                                  excludeSemantics: true,
                                  onTap: () => _showQuickFlag(quickItem),
                                  child: FilledButton.icon(
                                    onPressed: () => _showQuickFlag(quickItem),
                                    icon: const Icon(Icons.fullscreen),
                                    label: Text(l10n.showFlag),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_saveFailed)
                        TextButton.icon(
                          onPressed: _persist,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.saveError),
                        ),
                      if (_selected != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.countrySelected(
                                  _selected!.displayName(l10n.localeName),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (items.isEmpty) const EmptySearch(),
                    ],
                  );
                }
                final row = rows[index - 1];
                final item = row.item;
                if (item == null) {
                  return Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            switch (row.section) {
                              'Favorites' => Icons.star_rounded,
                              'Recent' => Icons.history_rounded,
                              _ => Icons.public_rounded,
                            },
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(switch (row.section) {
                              'Favorites' => l10n.favorites,
                              'Recent' => l10n.recent,
                              _ => l10n.allCountries,
                            }, style: Theme.of(context).textTheme.titleSmall),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final favorite = _preferences.favorites.contains(item.id);
                final favoriteLabel = favorite
                    ? l10n.removeFavorite(item.displayName(l10n.localeName))
                    : l10n.addFavorite(item.displayName(l10n.localeName));
                void toggleFavorite() {
                  setState(
                    () => _preferences = _preferences.toggleFavorite(item.id),
                  );
                  _persist();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      key: ValueKey(
                        row.section == 'Favorites' || row.section == 'Recent'
                            ? '${row.section}-${item.id}'
                            : item.id.toString(),
                      ),
                      leading: Image.asset(
                        item.asset,
                        width: 48,
                        height: 32,
                        fit: BoxFit.contain,
                        cacheWidth:
                            (48 * MediaQuery.devicePixelRatioOf(context))
                                .ceil(),
                        excludeFromSemantics: true,
                      ),
                      title: Text(item.displayName(l10n.localeName)),
                      subtitle: _preferences.quickFlag == item.id
                          ? Text(l10n.quickFlag)
                          : null,
                      selected: _selected?.id == item.id,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _quickMenu(item),
                          if (_selected?.id == item.id)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              semanticLabel: l10n.selected,
                            ),
                          Semantics(
                            container: true,
                            excludeSemantics: true,
                            label: favoriteLabel,
                            button: true,
                            toggled: favorite,
                            onTap: toggleFavorite,
                            child: IconButton(
                              tooltip: favoriteLabel,
                              isSelected: favorite,
                              icon: const Icon(Icons.star_border),
                              selectedIcon: const Icon(Icons.star),
                              onPressed: toggleFavorite,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _selected = item;
                          _preferences = _preferences.select(item.id);
                        });
                        _persist();
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
