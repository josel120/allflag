# AllFlag R8 rules. Flutter's Gradle plugin adds the engine/plugin rules.
# MainActivity is referenced from the manifest (kept by AAPT); this makes the
# intent explicit because it hosts the com.allflag.allflag/flag_mode channel,
# which is resolved by string name, not reflection.
-keep class com.allflag.allflag.MainActivity { *; }

# google_mobile_ads -> play-services-ads -> WorkManager (Room). Room creates
# <Database>_Impl by reflection; R8 full mode removed its no-arg constructor and
# every release launch crashed in androidx.startup.InitializationProvider:
# "Failed to create an instance of androidx.work.impl.WorkDatabase" (1.0.0+12).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
