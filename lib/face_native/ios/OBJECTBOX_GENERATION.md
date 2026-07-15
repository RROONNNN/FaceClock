# ObjectBox Code Generation Guide

This guide explains how to generate ObjectBox entity code for the iOS plugin.

## Quick Start

### Option 1: Using the Script (Recommended)

```bash
cd /Users/apple/thuan/hrm/lib/face_native/ios
./generate_objectbox.sh
```

### Option 2: Manual Sourcery Command

```bash
cd /Users/apple/thuan/hrm/lib/face_native/ios

# Using ObjectBox's bundled Sourcery
/Users/apple/thuan/hrm/lib/face_native/example/ios/Pods/ObjectBox/Mac/OBXCodeGen.framework/Versions/A/Resources/Sourcery.app/Contents/MacOS/Sourcery \
  --sources ./Classes/data/DataModels.swift \
  --templates /Users/apple/thuan/hrm/lib/face_native/example/ios/Pods/ObjectBox/Mac/OBXCodeGen.framework/Versions/A/Resources/Sourcery.app/Contents/Resources/EntityInfo.stencil \
  --output ./Classes/data/
```

### Option 3: Using System Sourcery (if installed)

```bash
cd /Users/apple/thuan/hrm/lib/face_native/ios

sourcery \
  --sources ./Classes/data/DataModels.swift \
  --templates <path-to-objectbox-template>/EntityInfo.stencil \
  --output ./Classes/data/
```

## What Gets Generated

When you run Sourcery, it creates:

1. **EntityInfo.generated.swift** - Contains:

   - Entity metadata and bindings
   - Property definitions
   - Store convenience initializer
   - Serialization/deserialization code

2. **model.json** - ObjectBox model metadata
   - Entity IDs and property IDs
   - Schema version tracking
   - **IMPORTANT**: Keep this file in version control!

## When to Run Sourcery

Run the generator when you:

- ✅ Add new entity classes
- ✅ Add/remove properties from entities
- ✅ Change property types
- ✅ Add ObjectBox annotations

## Entity Annotations

In `DataModels.swift`, use comment annotations:

```swift
// objectbox: entity
class FaceImageRecord {
    var id: Id = 0

    // objectbox: index
    var empId: Int64 = 0

    var personName: String = ""

    // objectbox: hnswIndex dimensions:128 distanceType:cosine indexingSearchCount:400
    var faceEmbedding: [Float] = []
}
```

### Supported Annotations

- `// objectbox: entity` - Mark class as an entity
- `// objectbox: index` - Create a standard index
- `// objectbox: unique` - Enforce unique constraint
- `// objectbox: hnswIndex` - Vector similarity index (warning expected)

## Troubleshooting

### Warning: "unknown annotations hnswIndex dimensions"

**This is expected!** The standard ObjectBox template doesn't recognize HNSW parameters in annotations. The HNSW index is configured at runtime through the ObjectBox API.

### Error: "Sourcery not found"

Make sure you've run `pod install` in the example project:

```bash
cd /Users/apple/thuan/hrm/lib/face_native/example/ios
pod install
```

### Error: "model.json conflicts"

If you have git merge conflicts in `model.json`:

1. **DO NOT** manually edit the file
2. Follow [ObjectBox conflict resolution guide](https://docs.objectbox.io/advanced/meta-model-ids-and-uids#resolving-merge-conflicts)
3. Re-run Sourcery after resolving

## Build Integration

### Xcode Build Phase (Optional)

To auto-generate on build, add a Run Script Phase:

1. Open Xcode project
2. Select target → Build Phases
3. Add Run Script Phase:

```bash
#!/bin/bash
cd "${SRCROOT}/../../ios"
if [ -f "./generate_objectbox.sh" ]; then
    ./generate_objectbox.sh
fi
```

## Files Overview

```
ios/
├── Classes/data/
│   ├── DataModels.swift          # Entity definitions (edit this)
│   ├── EntityInfo.generated.swift # Generated code (DO NOT EDIT)
│   ├── ObjectBoxStore.swift       # Store initialization
│   └── ImagesVectorDB.swift       # Database operations
├── model.json                     # ObjectBox schema (version control!)
└── generate_objectbox.sh          # Generation script
```

## Additional Resources

- [ObjectBox Swift Docs](https://swift.objectbox.io/)
- [ObjectBox Annotations](https://swift.objectbox.io/entity-annotations)
- [Sourcery Documentation](https://github.com/krzysztofzablocki/Sourcery)
