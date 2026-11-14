# AllFlag R8 rules. Flutter's Gradle plugin adds the engine/plugin rules.
# MainActivity is referenced from the manifest (kept by AAPT); this makes the
# intent explicit because it hosts the com.allflag.allflag/flag_mode channel,
# which is resolved by string name, not reflection.
-keep class com.allflag.allflag.MainActivity { *; }
