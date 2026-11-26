# Keep Kotlinx Serialization models for V2 Content JSON
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.mathmvp.riazi_yar.content.**$$serializer { *; }
-keepclassmembers class com.mathmvp.riazi_yar.content.** { *** Companion; }
-keepclasseswithmembers class com.mathmvp.riazi_yar.content.** { kotlinx.serialization.KSerializer serializer(...); }
