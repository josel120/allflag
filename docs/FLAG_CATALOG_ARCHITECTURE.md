# Generic Flag Catalog Foundation — v0.8.0+10

AllFlag's purpose is to turn your phone into the flag you want to show right now.
The only production catalog remains the same 195 countries. No future category,
organization ID, artwork or category picker is shipped by this release.

## Domain and provider boundary

- `FlagCategory` is an open, validated namespace, not a closed enum. Category
  tokens use lowercase ASCII letters, digits, underscores and hyphens, starting
  with a letter. `country` is the sole production category.
- `FlagId` combines category and a case-sensitive stable value. Values use ASCII
  letters, digits, periods, underscores and hyphens, starting with a letter or
  digit. Serialization is exactly `category:value`. Equality and hashing include
  both components; `tryParse` returns null for malformed input. Valid syntax does
  not imply membership in the installed catalog.
- `FlagItem` contains identity, asset path, immutable localized names and search
  aliases. It has no ISO code or country metadata. Image dimensions are the
  proportion source; thumbnails and fullscreen use `BoxFit.contain` on the
  unchanged artwork. No duplicate or guessed ratio metadata is needed.
- `FlagCatalog.loadFlags()` is the asynchronous application boundary.
  `CountryFlagCatalog` adapts the existing `CountryRepository`, assigning
  `country:VE` to source ISO `VE` and supplying existing English/Spanish names
  and ISO search aliases. Country-specific and historical metadata remain in
  `Country` / `Flag` behind that adapter.
- Home selection, search, Favorites, Recent and Quick Flag use `FlagItem` and
  `FlagId`. `FlagScreen` receives a `FlagItem`; it never consults a country,
  ISO code or repository. The orientation/lifecycle controller is unchanged.
- Search and sorting use active-language names with the previous normalization
  and Spanish alphabetical ordering. The visible country vocabulary is retained
  because countries remain the only production catalog.

To add a catalog later, implement `FlagCatalog` (or compose providers at the
composition root) and supply unique IDs, names, aliases and artwork. The generic
feature implementations and preferences format need no category switches.
Any future category navigation/copy is a separate product change.

## Persistence and migration

The historical SharedPreferences key `allflag.country_preferences.v1` is retained
intentionally. Its name is a storage location, not the new schema version.
The single JSON snapshot now includes `schemaVersion: 2`:

```json
{"schemaVersion":2,"favorites":["country:VE","country:PE"],"recent":["country:PE","country:VE"],"quickFlag":"country:VE","theme":"dark","language":"spanish"}
```

On load, an absent schema version (all released v0.7 snapshots) or version 1
enables the legacy adapter: uppercase two-letter ISO strings map to `country:XX`.
Already namespaced IDs are accepted as well, allowing mixed legacy snapshots.
Other malformed values are ignored. Version 2 accepts only namespaced IDs.

Home loads the catalog first and supplies its available ID set to the store.
Stale IDs are removed **before** deduplication and the five-item Recent limit.
Favorites retain insertion order; Recent retains its existing MRU order; Quick
Flag stays zero or one available ID. Theme and language are decoded with the
same defaults and values as before. Previous releases did not persist the normal
selection: it continues to be session state, with no new auto-selection behavior.

Migration writes the full snapshot once, without prompting. Canonical version 2
snapshots are compared before writing and are not rewritten on subsequent loads.
The key is never deleted first. A failed write propagates to the existing load
error/retry UI, leaving migration retryable; it does not silently substitute empty
preferences. Malformed JSON or wrong-shaped roots safely yield default choices.
Unknown schema versions fail loading without overwriting potentially newer data.
The store's optional `availableIds` supports catalog-independent round trips;
production always supplies it to reject stale references.

This is a forward migration. Downgrading to v0.7 is not supported because v0.7
does not understand namespaced IDs.

## Validation

Existing country, localization, theme, Favorites, Recent, Quick Flag and Flag Mode
regressions exercise the new application boundary. `generic_catalog_test.dart`
adds ID validation, all-195 adapter coverage, ordered/mixed migration, stale
filtering before the MRU cap, restart idempotence, failed-write retry, future-schema
protection, generic MRU persistence and an end-to-end synthetic non-country item.
The synthetic category is test-only and reuses existing artwork.

Run `flutter analyze` and `flutter test`. Physical device orientation, immersive
system bars and screen-awake QA still follow `FLAG_MODE.md` and `QUICK_FLAG.md`.
