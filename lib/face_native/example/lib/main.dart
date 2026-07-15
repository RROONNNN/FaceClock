import 'dart:async';
import 'dart:io';

import 'package:face_native/face_native.dart';
import 'package:face_native/models/face_image_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _faceNativePlugin = FaceNative();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _faceNativePlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Native Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FaceNativeTestPage(platformVersion: _platformVersion),
    );
  }
}

class FaceNativeTestPage extends StatefulWidget {
  final String platformVersion;

  const FaceNativeTestPage({
    super.key,
    required this.platformVersion,
  });

  @override
  State<FaceNativeTestPage> createState() => _FaceNativeTestPageState();
}

class _FaceNativeTestPageState extends State<FaceNativeTestPage> {
  final _faceNativePlugin = FaceNative();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _imageUri;
  String _result = '';
  bool _isLoading = false;

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUri = image.path;
          _result = 'Photo captured: ${image.path}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Failed to capture photo: $e';
      });
    }
  }

  Future<void> _testGetCroppedFace() async {
    if (_imageUri == null || _selectedImage == null) {
      setState(() {
        _result = 'Please take a photo first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Testing face detection...';
    });

    try {
      final bool success =
          await _faceNativePlugin.testGetCroppedFace(_imageUri!);

      setState(() {
        _isLoading = false;
        if (success) {
          _result = '''
✅ SUCCESS!

Face Detection Result:
- Status: Face detected and cropped successfully
- Image Path: $_imageUri
- Operation: testGetCroppedFace

The cropped face image has been saved to the app's documents directory.

📝 Details:
1. Image loaded successfully
2. Face detection completed
3. Exactly one face found
4. Face bounds validated
5. Face cropped and saved

💡 Check the app's documents directory or logs to see the saved cropped face image.
          ''';
        } else {
          _result = '''
⚠️ FAILED

Face Detection Result:
- Status: Failed
- Image Path: $_imageUri

Possible Reasons:
- No face detected in the image
- Multiple faces detected (only single face allowed)
- Face bounding box invalid
- Image quality issues

💡 Tips:
1. Make sure the image contains exactly one face
2. Ensure good lighting in the photo
3. Face should be clearly visible
4. Try a different image
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if ML Kit is properly initialized
2. Verify image file exists and is accessible
3. Ensure proper permissions are granted
4. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testGetFaceEmbedding() async {
    if (_imageUri == null || _selectedImage == null) {
      setState(() {
        _result = 'Please take a photo first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Getting face embedding...';
    });

    try {
      final List<double> embedding =
          await _faceNativePlugin.testGetFaceEmbedding(_imageUri!);

      setState(() {
        _isLoading = false;
        _result = '''
✅ SUCCESS!

Face Embedding Result:
- Status: Face embedding generated successfully
- Image Path: $_imageUri
- Operation: testGetFaceEmbedding
- Embedding Dimension: ${embedding.length}

📊 Embedding Vector (first 10 values):
${embedding.take(10).map((e) => e.toStringAsFixed(6)).join(', ')}...

📊 Embedding Statistics:
- Min Value: ${embedding.reduce((a, b) => a < b ? a : b).toStringAsFixed(6)}
- Max Value: ${embedding.reduce((a, b) => a > b ? a : b).toStringAsFixed(6)}
- Average: ${(embedding.reduce((a, b) => a + b) / embedding.length).toStringAsFixed(6)}

📝 Details:
1. Image loaded successfully
2. Face detected and processed
3. FaceNet model inference completed
4. Embedding vector generated (${embedding.length}D)

💡 This embedding can be used for face recognition by comparing it with other embeddings using cosine similarity or Euclidean distance.
        ''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if FaceNet model is properly loaded
2. Verify image file exists and is accessible
3. Ensure face is detected in the image
4. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testAddImage() async {
    if (_imageUri == null || _selectedImage == null) {
      setState(() {
        _result = 'Please take a photo first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Adding image to database...';
    });

    try {
      final int imageId = await _faceNativePlugin.addImage(
        empId: 12345,
        personName: 'Test User',
        pin: null,
        imageUri: _imageUri!,
      );

      setState(() {
        _isLoading = false;
        if (imageId > 0) {
          _result = '''
✅ SUCCESS!

Add Image Result:
- Status: Image added successfully
- Image Path: $_imageUri
- Operation: addImage
- Image ID: $imageId
- Employee ID: 12345
- Person Name: Test User

📝 Details:
1. Image loaded successfully
2. Face detected and cropped
3. Face embedding generated
4. Record saved to database

💡 This image can now be used for face recognition. Try the "Test Recognize Face" button to test recognition.
          ''';
        } else {
          _result = '''
⚠️ FAILED

Add Image Result:
- Status: Failed to add image
- Image Path: $_imageUri
- Returned ID: $imageId

Possible Reasons:
- No face detected in the image
- Multiple faces detected (only single face allowed)
- Face detection or embedding generation failed
- Database error

💡 Tips:
1. Make sure the image contains exactly one face
2. Ensure good lighting in the photo
3. Face should be clearly visible
4. Try a different image
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify image file exists and is accessible
3. Ensure face is detected in the image
4. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testRecognizeFace() async {
    if (_imageUri == null) {
      setState(() {
        _result = 'Please take a photo first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Recognizing face...';
    });

    try {
      final response =
          await _faceNativePlugin.recognizeFace(imagePath: _imageUri!);

      setState(() {
        _isLoading = false;
        if (response.result.personName != 'Not_recognized') {
          _result = '''
✅ SUCCESS!

Face Recognition Result:
- Status: Face(s) recognized
- Image Path: $_imageUri
- Operation: recognizeFace
- Matches Found: ${response.result.personName}

          ''';
        } else {
          _result = '''
⚠️ NO MATCH FOUND

Face Recognition Result:
- Status: No matching faces found
- Image Path: $_imageUri
- Matches Found: 0


Possible Reasons:
- No matching faces in the database
- Face quality too low
- Different lighting/angle from registered images
- Distance threshold too strict

💡 Tips:
1. Add this face to the database using "Test Add Image"
2. Ensure good lighting and clear face visibility
3. Try different angles or expressions
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database contains any registered faces
2. Verify image file exists and is accessible
3. Ensure face is detected in the image
4. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testGetAllImages() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting all images from database...';
    });

    try {
      final images = await _faceNativePlugin.getAllImages();

      setState(() {
        _isLoading = false;
        if (images.isNotEmpty) {
          final imagesList = images
              .asMap()
              .entries
              .map(
                (entry) => '''
  📷 Record ${entry.key + 1}:
     - Employee ID: ${entry.value.empId}
     - Name: ${entry.value.personName}
     - Embedding Size: ${entry.value.faceEmbedding.length}D
''',
              )
              .join('\n');

          _result = '''
✅ SUCCESS!

Get All Images Result:
- Status: Images retrieved successfully
- Operation: getAllImages
- Total Images: ${images.length}

📋 Stored Images:
$imagesList

📝 Details:
1. Database queried successfully
2. ${images.length} image record(s) found
3. Each record contains face embeddings
4. Ready for face recognition

💡 These images are used for face recognition matching. You can add more images using "Test Add Image" button.
          ''';
        } else {
          _result = '''
⚠️ NO IMAGES FOUND

Get All Images Result:
- Status: No images in database
- Operation: getAllImages
- Total Images: 0

Possible Reasons:
- Database is empty
- No images have been added yet

💡 Tips:
1. Use "Test Add Image" button to add faces to the database
2. Make sure the image contains exactly one face
3. Ensure good lighting in the photo
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify database file permissions
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testGetPlatformVersion() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting platform version...';
    });

    try {
      final version = await _faceNativePlugin.getPlatformVersion();

      setState(() {
        _isLoading = false;
        _result = '''
✅ SUCCESS!

Platform Version Result:
- Status: Retrieved successfully
- Operation: getPlatformVersion
- Platform: ${version ?? 'Unknown'}

📝 Details:
1. Native platform queried successfully
2. Version information retrieved
3. Plugin communication working

💡 This confirms the Flutter-Native bridge is working correctly.
        ''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if native plugin is properly registered
2. Verify platform channel setup
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testGetFaceImageRecordByListEmpId() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting face records by employee IDs...';
    });

    try {
      // Test with employee IDs 12345, 12346, 12347
      final List<int> empIdList = [12345, 12346, 12347];
      final records =
          await _faceNativePlugin.getFaceImageRecordByListEmpId(empIdList);

      setState(() {
        _isLoading = false;
        if (records.isNotEmpty) {
          final recordsList = records
              .asMap()
              .entries
              .map(
                (entry) => '''
  📷 Record ${entry.key + 1}:
     - Employee ID: ${entry.value.empId}
     - Name: ${entry.value.personName}
     - Embedding Size: ${entry.value.faceEmbedding.length}D
''',
              )
              .join('\n');

          _result = '''
✅ SUCCESS!

Get Face Records Result:
- Status: Records retrieved successfully
- Operation: getFaceImageRecordByListEmpId
- Employee IDs Searched: ${empIdList.join(', ')}
- Records Found: ${records.length}

📋 Found Records:
$recordsList

📝 Details:
1. Database queried with employee IDs
2. ${records.length} matching record(s) found
3. Each record contains face embeddings
4. Ready for face recognition

💡 This method is useful for batch retrieval of specific employee face records.
          ''';
        } else {
          _result = '''
⚠️ NO RECORDS FOUND

Get Face Records Result:
- Status: No matching records
- Operation: getFaceImageRecordByListEmpId
- Employee IDs Searched: ${empIdList.join(', ')}
- Records Found: 0

Possible Reasons:
- No records exist for these employee IDs
- Database is empty
- Employee IDs don't match any stored records

💡 Tips:
1. Use "Test Add Image" to add a face with Employee ID 12345
2. Then test this function again
3. Check "Get All Images" to see what's in the database
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify query parameters
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testAddAllRecords() async {
    setState(() {
      _isLoading = true;
      _result = 'Adding sample records to database...';
    });

    try {
      // Create sample records with dummy embeddings
      final sampleRecords = List.generate(3, (index) {
        return FaceImageRecord(
          empId: 10000 + index,
          personName: 'Sample User ${index + 1}',
          faceEmbedding: List.generate(128, (i) => (i + index).toDouble()),
        );
      });

      final success = await _faceNativePlugin.addAllRecords(sampleRecords);

      setState(() {
        _isLoading = false;
        if (success) {
          _result = '''
✅ SUCCESS!

Add All Records Result:
- Status: Records added successfully
- Operation: addAllRecords
- Records Added: ${sampleRecords.length}

📋 Added Records:
${sampleRecords.asMap().entries.map((e) => '''
  📷 Record ${e.key + 1}:
     - Employee ID: ${e.value.empId}
     - Name: ${e.value.personName}
     - Embedding Size: ${e.value.faceEmbedding.length}D
''').join('\n')}

📝 Details:
1. Batch insert operation completed
2. ${sampleRecords.length} records saved to database
3. Each record contains 128D face embeddings
4. Records ready for face recognition

💡 This method is useful for bulk import of face data. Use "Get All Images" to verify.
          ''';
        } else {
          _result = '''
⚠️ FAILED

Add All Records Result:
- Status: Failed to add records
- Operation: addAllRecords
- Records Attempted: ${sampleRecords.length}

Possible Reasons:
- Database write error
- Invalid record data
- Database not initialized

💡 Tips:
1. Check if database is properly initialized
2. Verify record data format
3. Check available storage space
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify record data format
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testRemoveImages() async {
    setState(() {
      _isLoading = true;
      _result = 'Removing images for employee ID 12345...';
    });

    try {
      const int empIdToRemove = 12345;
      final success = await _faceNativePlugin.removeImages(empIdToRemove);

      setState(() {
        _isLoading = false;
        if (success) {
          _result = '''
✅ SUCCESS!

Remove Images Result:
- Status: Images removed successfully
- Operation: removeImages
- Employee ID: $empIdToRemove

📝 Details:
1. Database query completed
2. All images for Employee ID $empIdToRemove deleted
3. Database updated successfully

💡 Use "Get All Images" to verify the records have been removed.
          ''';
        } else {
          _result = '''
⚠️ FAILED

Remove Images Result:
- Status: Failed to remove images
- Operation: removeImages
- Employee ID: $empIdToRemove

Possible Reasons:
- No images found for this employee ID
- Database error
- Employee ID doesn't exist

💡 Tips:
1. Check if images exist for this employee ID first
2. Use "Get All Images" to see available records
3. Try with a different employee ID
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify employee ID
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testGetImageIdsByEmpId() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting image IDs for employee ID 12345...';
    });

    try {
      const int empId = 12345;
      final imageIds = await _faceNativePlugin.getImageIdsByEmpId(empId);

      setState(() {
        _isLoading = false;
        if (imageIds.isNotEmpty) {
          _result = '''
✅ SUCCESS!

Get Image IDs Result:
- Status: Image IDs retrieved successfully
- Operation: getImageIdsByEmpId
- Employee ID: $empId
- Images Found: ${imageIds.length}

📋 Image IDs:
${imageIds.asMap().entries.map((e) => '  ${e.key + 1}. Image ID: ${e.value}').join('\n')}

📝 Details:
1. Database queried for employee ID $empId
2. ${imageIds.length} image(s) found
3. Each ID represents a stored face record

💡 Use these IDs with "Remove Images by IDs" to delete specific records.
          ''';
        } else {
          _result = '''
⚠️ NO IMAGES FOUND

Get Image IDs Result:
- Status: No images found
- Operation: getImageIdsByEmpId
- Employee ID: $empId
- Images Found: 0

Possible Reasons:
- No images stored for this employee ID
- Employee ID doesn't exist in database
- Database is empty

💡 Tips:
1. Use "Test Add Image" to add a face with Employee ID 12345
2. Use "Get All Images" to see what's in the database
3. Try with a different employee ID
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify employee ID
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  Future<void> _testRemoveImagesByIds() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting image IDs and removing them...';
    });

    try {
      // First get some image IDs to remove
      const int empId = 12345;
      final imageIds = await _faceNativePlugin.getImageIdsByEmpId(empId);

      if (imageIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _result = '''
⚠️ NO IMAGES TO REMOVE

Remove Images by IDs Result:
- Status: No images found to remove
- Operation: removeImagesByIds
- Employee ID Checked: $empId
- Images Found: 0

Possible Reasons:
- No images stored for employee ID $empId
- Database is empty

💡 Tips:
1. Use "Test Add Image" to add some faces first
2. Use "Get All Images" to see what's in the database
3. Try "Test Get Image IDs" to see available image IDs
          ''';
        });
        return;
      }

      // Remove the first image ID as a test
      final idsToRemove = [imageIds.first];
      final success = await _faceNativePlugin.removeImagesByIds(idsToRemove);

      setState(() {
        _isLoading = false;
        if (success) {
          _result = '''
✅ SUCCESS!

Remove Images by IDs Result:
- Status: Images removed successfully
- Operation: removeImagesByIds
- Employee ID: $empId
- Total Images Found: ${imageIds.length}
- Images Removed: ${idsToRemove.length}

📋 Removed Image IDs:
${idsToRemove.asMap().entries.map((e) => '  ${e.key + 1}. Image ID: ${e.value}').join('\n')}

📋 Remaining Image IDs:
${imageIds.skip(1).isEmpty ? '  (None - all removed)' : imageIds.skip(1).toList().asMap().entries.map((e) => '  ${e.key + 1}. Image ID: ${e.value}').join('\n')}

📝 Details:
1. Found ${imageIds.length} image(s) for employee ID $empId
2. Removed ${idsToRemove.length} image(s) by ID
3. Database updated successfully

💡 Use "Get All Images" to verify the records have been removed.
          ''';
        } else {
          _result = '''
⚠️ FAILED

Remove Images by IDs Result:
- Status: Failed to remove images
- Operation: removeImagesByIds
- Image IDs: ${idsToRemove.join(', ')}

Possible Reasons:
- Database error
- Image IDs don't exist anymore
- Permission issues

💡 Try again or check the app logs for details.
          ''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '''
❌ ERROR

Exception occurred:
$e

Troubleshooting:
1. Check if database is properly initialized
2. Verify image IDs exist
3. Check app logs for detailed error messages
        ''';
      });
    }
  }

  void _clearResult() {
    setState(() {
      _result = '';
      _selectedImage = null;
      _imageUri = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Native Plugin Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Platform version info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Running on: ${widget.platformVersion}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Camera section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Camera Capture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image preview
                    if (_selectedImage != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Take photo button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo with Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    if (_imageUri != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Captured: ${_imageUri!.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test actions section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Test button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testGetCroppedFace,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                          _isLoading ? 'Testing...' : 'Test Get Cropped Face'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test face embedding button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testGetFaceEmbedding,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.face),
                      label: Text(_isLoading
                          ? 'Processing...'
                          : 'Test Get Face Embedding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test add image button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testAddImage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(_isLoading ? 'Adding...' : 'Test Add Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test recognize face button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testRecognizeFace,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isLoading
                          ? 'Recognizing...'
                          : 'Test Recognize Face'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test get all images button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testGetAllImages,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(_isLoading ? 'Loading...' : 'Get All Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    const Divider(),
                    const Text(
                      'Additional Test Methods',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Test get platform version button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testGetPlatformVersion,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.info),
                      label: Text(
                          _isLoading ? 'Loading...' : 'Get Platform Version'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test get face records by emp id list button
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : _testGetFaceImageRecordByListEmpId,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.group),
                      label: Text(_isLoading
                          ? 'Loading...'
                          : 'Get Face Records by Emp IDs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test add all records button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testAddAllRecords,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.library_add),
                      label: Text(
                          _isLoading ? 'Adding...' : 'Add All Records (Batch)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test remove images button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testRemoveImages,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_forever),
                      label: Text(_isLoading
                          ? 'Removing...'
                          : 'Remove Images (EmpID 12345)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test get image IDs by emp id button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testGetImageIdsByEmpId,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.list_alt),
                      label: Text(_isLoading
                          ? 'Loading...'
                          : 'Get Image IDs (EmpID 12345)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test remove images by IDs button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testRemoveImagesByIds,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_sweep),
                      label: Text(
                          _isLoading ? 'Removing...' : 'Remove Images by IDs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clear button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _clearResult,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results section
            if (_result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _result = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear result',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          _result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap "Take Photo with Camera" to capture a photo\n'
                      '2. Take a photo with a clear face\n'
                      '3. Choose a test to run:\n\n'
                      '📸 Core Face Operations:\n'
                      '   • "Test Get Cropped Face" - Detects and crops face\n'
                      '   • "Test Get Face Embedding" - Generates 128D face vector\n'
                      '   • "Test Add Image" - Adds face to database (EmpID: 12345)\n'
                      '   • "Test Recognize Face" - Searches for match in database\n'
                      '   • "Get All Images" - Retrieves all stored faces from DB\n\n'
                      '⚙️ Additional Test Methods:\n'
                      '   • "Get Platform Version" - Tests Flutter-Native bridge\n'
                      '   • "Get Face Records by Emp IDs" - Batch retrieve by IDs (12345-12347)\n'
                      '   • "Add All Records (Batch)" - Bulk insert sample records (3 records)\n'
                      '   • "Remove Images (EmpID 12345)" - Delete all images for one employee\n'
                      '   • "Get Image IDs (EmpID 12345)" - List all image IDs for employee\n'
                      '   • "Remove Images by IDs" - Delete specific images by their IDs\n\n'
                      '4. View the results below\n\n'
                      '💡 Best Results:\n'
                      '• Ensure exactly one face in frame\n'
                      '• Use good lighting conditions\n'
                      '• Face should be clearly visible and centered\n'
                      '• Keep the camera steady when capturing\n\n'
                      '📝 Testing Workflow:\n'
                      '1. First use "Test Add Image" to register a face\n'
                      '2. Use "Get All Images" to see all stored faces\n'
                      '3. Then use "Test Recognize Face" to find matches\n'
                      '4. Test batch operations with "Add All Records"\n'
                      '5. Test deletion with "Remove Images" or "Remove Images by IDs"',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
