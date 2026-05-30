# Flutter Proguard Rules for Matn Muharriri

# Ignore missing optional script packages from Google ML Kit Text Recognition
# We only utilize the Latin OCR script engine, so these warnings are safely ignored.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.**
