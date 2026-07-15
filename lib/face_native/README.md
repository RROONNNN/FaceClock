# face_native

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

UTF-8 encoding problem with CocoaPods:
export LANG=en_US.UTF-8

cd /Users/apple/thuan/hrm/lib/face_native/ios && /Users/apple/thuan/hrm/lib/face_native/example/ios/Pods/ObjectBox/Mac/OBXCodeGen.framework/Versions/A/Resources/Sourcery.app/Contents/MacOS/Sourcery \
 --sources ./Classes/data/DataModels.swift \
 --templates /Users/apple/thuan/hrm/lib/face_native/example/ios/Pods/ObjectBox/Mac/OBXCodeGen.framework/Versions/A/Resources/Sourcery.app/Contents/Resources/EntityInfo.stencil \
 --output ./Classes/data/
