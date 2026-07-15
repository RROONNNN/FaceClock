# Keep annotations and javax.lang.model types used by AutoValue/Javapoet in processors
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**

# AutoValue shaded Javapoet in some processors
-dontwarn autovalue.shaded.com.squareup.javapoet$**
-keep class autovalue.shaded.com.squareup.javapoet$** { *; }

# Keep ObjectBox classes used reflectively
-keep class io.objectbox.** { *; }
-dontwarn io.objectbox.**

# Keep Mediapipe tasks classes
-keep class com.google.mediapipe.tasks.** { *; }
-dontwarn com.google.mediapipe.tasks.**

# Keep Google Edge LiteRT
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**