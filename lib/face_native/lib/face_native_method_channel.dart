import 'dart:io';
import 'dart:math';
import 'package:exif/exif.dart';
import 'package:face_native/models/face_image_record.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'face_native_platform_interface.dart';

/// An implementation of [FaceNativePlatform] that uses method channels.
class MethodChannelFaceNative extends FaceNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final platform = const MethodChannel('face_native');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await platform.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> testGetCroppedFace(String imageUri) async {
    try {
      final bool result = await platform
          .invokeMethod('testGetCroppedFace', {'imageUri': imageUri});
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in testGetCroppedFace: ${e.message}');
      throw FaceDetectionException(
          'Failed to test get cropped face: ${e.message}');
    }
  }

  @override
  Future<List<FaceImageRecord>> getFaceImageRecordByListEmpId(
      List<int> empIdList) async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
          'getFaceImageRecordByListEmpId', {'empIdList': empIdList});
      return result.map((e) => FaceImageRecord.fromMap(e)).toList();
    } on PlatformException catch (e) {
      throw FaceDetectionException(
          'Failed to get face image record by list emp id: ${e.message}');
    }
  }

  @override
  Future<bool> initObjectBox(
    String tenantKey,
  ) async {
    try {
      final bool result = await platform
          .invokeMethod('initObjectBox', {'tenantKey': tenantKey});
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in initObjectBox: ${e.message}');
      throw FaceDetectionException('Failed to init object box: ${e.message}');
    }
  }

  @override

  /// Add a new person with specified name and number of images
  Future<int> addPerson(String name, int numImages, int empId) async {
    try {
      final int personId = await platform.invokeMethod('addPerson', {
        'name': name,
        'numImages': numImages,
        'empId': empId,
      });
      return personId;
    } on PlatformException catch (e) {
      debugPrint('Error in addPerson: ${e.message}');
      throw FaceDetectionException('Failed to add person: ${e.message}');
    }
  }

  @override
  Future<int> getCount() async {
    try {
      final int count = await platform.invokeMethod('getCount');
      return count;
    } on PlatformException catch (e) {
      debugPrint('Error in getCount: ${e.message}');
      throw FaceDetectionException('Failed to get count: ${e.message}');
    }
  }

  @override
  Future<bool> clearAllImages() async {
    try {
      final bool result = await platform.invokeMethod('clearAllImages');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in clearAllImages: ${e.message}');
      throw FaceDetectionException('Failed to clear all images: ${e.message}');
    }
  }

  @override

  /// Get the database size in bytes
  Future<int> getDatabaseSizeInBytes() async {
    try {
      final int sizeInBytes =
          await platform.invokeMethod('getDatabaseSizeInBytes');
      return sizeInBytes;
    } on PlatformException catch (e) {
      debugPrint('Error in getDatabaseSizeInBytes: ${e.message}');
      throw FaceDetectionException('Failed to get database size: ${e.message}');
    }
  }

  /// Format bytes into human-readable format (B, KB, MB, GB, TB)
  String formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const List<String> units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 2)} ${units[unitIndex]}';
  }

  @override

  /// Get formatted database size as a string
  Future<String> getDatabaseSizeFormatted() async {
    try {
      final int sizeInBytes = await getDatabaseSizeInBytes();
      return formatBytes(sizeInBytes);
    } catch (e) {
      debugPrint('Error in getDatabaseSizeFormatted: $e');
      throw FaceDetectionException('Failed to get formatted database size: $e');
    }
  }

  @override
  Future<List<FaceImageRecord>> getAllImages() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getAllImages');
      debugPrint('result in getAllImages: $result');
      return result.map((e) => FaceImageRecord.fromMap(e)).toList();
    } on PlatformException catch (e) {
      debugPrint('Error in getAllImages: ${e.message}');
      throw FaceDetectionException('Failed to get all images: ${e.message}');
    }
  }

  Future<Uint8List> _prepareImageForModel(Uint8List bytes) async {
    try {
      final exifData = await readExifFromBytes(bytes);
      int rotateAngle = 0;
      if (exifData.containsKey('Image Orientation')) {
        final orientation = exifData['Image Orientation']!.printable;
        if (orientation.contains('90'))
          rotateAngle = 90;
        else if (orientation.contains('180'))
          rotateAngle = 180;
        else if (orientation.contains('270')) rotateAngle = 270;
      }

      img.Image? src = img.decodeImage(bytes);
      if (src == null) throw Exception('Không thể decode ảnh');

      img.Image dst =
          rotateAngle != 0 ? img.copyRotate(src, angle: rotateAngle) : src;
      //   final dst = src;
      final tempDir = await getTemporaryDirectory();
      final randomString = Random().nextInt(1000000).toString();
      final fileName = 'anhxoay${randomString}.jpg';
      final filePath = p.join(tempDir.path, fileName);
      final file = File(filePath);
      final rotatedBytes = img.encodeJpg(dst);
      await file.writeAsBytes(rotatedBytes);
      return rotatedBytes;
    } catch (e) {
      debugPrint('Error in _prepareImageForModel: $e');
      rethrow;
    }
  }

  @override

  /// Add an image for a specific person
  Future<int> addImage({
    required int empId,
    required String personName,
    required String? pin,
    required String imageUri,
  }) async {
    try {
      // final XFile xfile = XFile(imageUri);
      // final processedImageUri = await _prepareImageForModel(xfile);
      final int result = await platform.invokeMethod('addImage', {
        'empId': empId,
        'personName': personName,
        'pin': pin,
        'imageUri': imageUri,
      });
      debugPrint('result in addImage: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint(
          'Error in addImage: code=${e.code}, message=${e.message}, details=${e.details}');

      // throw FaceDetectionException('Failed to add image: ${e.message}');
      return -1;
    }
  }

  @override
  Future<bool> addAllRecords(List<FaceImageRecord> records) async {
    try {
      final List<dynamic> recordsList = records.map((e) => e.toMap()).toList();
      final bool result = await platform
          .invokeMethod('addAllRecords', {'records': recordsList});
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in addAllRecords: $e');
      throw FaceDetectionException('Failed to add all records: ${e.message}');
    }
  }

  @override

  /// Recognize faces in the provided image bytes
  Future<FaceRecognitionResponse> recognizeFace({
    Uint8List? imageBytes,
    String? imagePath,
  }) async {
    try {
      late final Map<dynamic, dynamic> result;
      if (imageBytes != null) {
        await _prepareImageForModel(imageBytes);
        result = await platform.invokeMethod(
          'recognizeFace',
          {'imageBytes': imageBytes},
        );
      } else {
        result = await platform.invokeMethod(
          'recognizeFace',
          {'imageUrl': imagePath},
        );
      }
      debugPrint('result: $result');
      // // remove all 'personName' is 'Not_recognized'
      // result['results'] = result['results']
      //     .where((result) => result['personName'] != 'Not_recognized')
      //     .toList();

      return FaceRecognitionResponse.fromMap(result);
    } on PlatformException catch (e) {
      debugPrint('Error in recognizeFace: ${e.message}');

      throw FaceDetectionException('Failed to recognize face: ${e.message}');
    }
  }

  @override

  /// Remove all images for a specific person
  Future<bool> removeImages(int empId) async {
    try {
      final bool result = await platform.invokeMethod('removeImages', {
        'empId': empId,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in removeImages: ${e.message}');
      throw FaceDetectionException('Failed to remove images: ${e.message}');
    }
  }

  @override
  Future<List<int>> getImageIdsByEmpId(int empId) async {
    try {
      final raw = await platform.invokeMethod<List<Object?>>(
        'getImageIdsByEmpId',
        {'empId': empId},
      );
      return raw?.map((e) => (e as num).toInt()).toList() ?? <int>[];
    } on PlatformException catch (e) {
      debugPrint('Error in getImageIdsByEmpId: ${e.message}');
      throw FaceDetectionException(
          'Failed to get image ids by emp id: ${e.message}');
    }
  }

  @override
  Future<bool> removeImagesByIds(List<int> imageIds) async {
    try {
      final bool result = await platform
          .invokeMethod('removeImagesByIds', {'imageIds': imageIds});
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error in removeImagesByIds: ${e.message}');
      throw FaceDetectionException(
          'Failed to remove images by ids: ${e.message}');
    }
  }

  @override
  Future<List<double>> testGetFaceEmbedding(String imageUri) async {
    try {
      final List<dynamic> result = await platform
          .invokeMethod('testGetFaceEmbedding', {'imageUri': imageUri});
      return result.map((e) => (e as num).toDouble()).toList();
    } on PlatformException catch (e) {
      debugPrint('Error in testGetFaceEmbedding: ${e.message}');
      throw FaceDetectionException(
          'Failed to get face embedding: ${e.message}');
    }
  }
}

/// Custom exception for face detection service errors
class FaceDetectionException implements Exception {
  final String message;

  const FaceDetectionException(this.message);

  @override
  String toString() => 'FaceDetectionException: $message';
}

/// Response model for face recognition
class FaceRecognitionResponse {
  final RecognitionResult result;
  final RecognitionMetrics? metrics;

  const FaceRecognitionResponse({
    required this.result,
    this.metrics,
  });

  factory FaceRecognitionResponse.fromMap(Map<dynamic, dynamic> map) {
    final Map<dynamic, dynamic> resultData = map['result'] ?? {};
    final RecognitionResult result = RecognitionResult.fromMap(resultData);

    final Map<dynamic, dynamic>? metricsData = map['metrics'];
    final RecognitionMetrics? metrics =
        metricsData != null ? RecognitionMetrics.fromMap(metricsData) : null;

    return FaceRecognitionResponse(
      result: result,
      metrics: metrics,
    );
  }
}

/// Individual recognition result for a detected face
class RecognitionResult {
  final String personName;
  final String pin;
  final int employeeId;
  final BoundingBox boundingBox;
  final SpoofResult? spoofResult;

  const RecognitionResult({
    required this.personName,
    required this.pin,
    required this.employeeId,
    required this.boundingBox,
    this.spoofResult,
  });

  factory RecognitionResult.fromMap(Map<dynamic, dynamic> map) {
    final Map<dynamic, dynamic>? boundingBoxData = map['boundingBox'];
    final Map<dynamic, dynamic>? spoofData = map['spoofResult'];

    return RecognitionResult(
      personName: map['personName'] ?? '',
      pin: map['pin'] ?? '',
      employeeId: map['employeeId'] ?? 0,
      boundingBox: boundingBoxData != null
          ? BoundingBox.fromMap(boundingBoxData)
          : const BoundingBox(left: 0, top: 0, right: 0, bottom: 0),
      spoofResult: spoofData != null ? SpoofResult.fromMap(spoofData) : null,
    );
  }
}

/// Bounding box coordinates for detected face
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory BoundingBox.fromMap(Map<dynamic, dynamic> map) {
    return BoundingBox(
      left: (map['left'] ?? 0).toDouble(),
      top: (map['top'] ?? 0).toDouble(),
      right: (map['right'] ?? 0).toDouble(),
      bottom: (map['bottom'] ?? 0).toDouble(),
    );
  }

  /// Get width of the bounding box
  double get width => right - left;

  /// Get height of the bounding box
  double get height => bottom - top;
}

/// Spoof detection result
class SpoofResult {
  final bool isSpoof;
  final double score;
  final int timeMillis;

  const SpoofResult({
    required this.isSpoof,
    required this.score,
    required this.timeMillis,
  });

  factory SpoofResult.fromMap(Map<dynamic, dynamic> map) {
    return SpoofResult(
      isSpoof: map['isSpoof'] ?? false,
      score: (map['score'] ?? 0).toDouble(),
      timeMillis: map['timeMillis'] ?? 0,
    );
  }
}

/// Performance metrics for face recognition
class RecognitionMetrics {
  final int timeFaceDetection;
  final int timeFaceEmbedding;
  final int timeVectorSearch;
  final int timeFaceSpoofDetection;

  const RecognitionMetrics({
    required this.timeFaceDetection,
    required this.timeFaceEmbedding,
    required this.timeVectorSearch,
    required this.timeFaceSpoofDetection,
  });

  factory RecognitionMetrics.fromMap(Map<dynamic, dynamic> map) {
    return RecognitionMetrics(
      timeFaceDetection: map['timeFaceDetection'] ?? 0,
      timeFaceEmbedding: map['timeFaceEmbedding'] ?? 0,
      timeVectorSearch: map['timeVectorSearch'] ?? 0,
      timeFaceSpoofDetection: map['timeFaceSpoofDetection'] ?? 0,
    );
  }

  /// Get total processing time
  int get totalTime =>
      timeFaceDetection +
      timeFaceEmbedding +
      timeVectorSearch +
      timeFaceSpoofDetection;
}
