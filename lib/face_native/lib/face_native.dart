import 'dart:typed_data';

import 'package:face_native/face_native_method_channel.dart';
import 'package:face_native/models/face_image_record.dart';

import 'face_native_platform_interface.dart';

class FaceNative {
  Future<String?> getPlatformVersion() {
    return FaceNativePlatform.instance.getPlatformVersion();
  }

  Future<bool> initObjectBox(String tenantKey) {
    return FaceNativePlatform.instance.initObjectBox(tenantKey);
  }

  Future<List<FaceImageRecord>> getAllImages() {
    return FaceNativePlatform.instance.getAllImages();
  }

  Future<bool> testGetCroppedFace(String imageUri) {
    return FaceNativePlatform.instance.testGetCroppedFace(imageUri);
  }

  Future<int> getCount() {
    return FaceNativePlatform.instance.getCount();
  }

  Future<List<FaceImageRecord>> getFaceImageRecordByListEmpId(
    List<int> empIdList,
  ) {
    return FaceNativePlatform.instance.getFaceImageRecordByListEmpId(empIdList);
  }

  Future<bool> clearAllImages() {
    return FaceNativePlatform.instance.clearAllImages();
  }

  Future<int> getDatabaseSizeInBytes() {
    return FaceNativePlatform.instance.getDatabaseSizeInBytes();
  }

  Future<String> getDatabaseSizeFormatted() {
    return FaceNativePlatform.instance.getDatabaseSizeFormatted();
  }

  Future<int> addPerson(String name, int numImages, int empId) {
    return FaceNativePlatform.instance.addPerson(name, numImages, empId);
  }

  Future<int> addImage({
    required int empId,
    required String personName,
    required String? pin,
    required String imageUri,
  }) {
    return FaceNativePlatform.instance.addImage(
      empId: empId,
      personName: personName,
      pin: pin,
      imageUri: imageUri,
    );
  }

  Future<bool> addAllRecords(List<FaceImageRecord> records) {
    return FaceNativePlatform.instance.addAllRecords(records);
  }

  Future<FaceRecognitionResponse> recognizeFace({
    Uint8List? imageBytes,
    String? imagePath,
  }) {
    assert(imageBytes != null || imagePath != null,
        'Either imageBytes or imagePath must be provided');
    assert(!(imageBytes != null && imagePath != null),
        'Only one of imageBytes or imagePath should be provided');

    return FaceNativePlatform.instance.recognizeFace(
      imageBytes: imageBytes,
      imagePath: imagePath,
    );
  }

  Future<bool> removeImages(int empId) {
    return FaceNativePlatform.instance.removeImages(empId);
  }

  Future<List<int>> getImageIdsByEmpId(int empId) {
    return FaceNativePlatform.instance.getImageIdsByEmpId(empId);
  }

  Future<bool> removeImagesByIds(List<int> imageIds) {
    return FaceNativePlatform.instance.removeImagesByIds(imageIds);
  }

  Future<List<double>> testGetFaceEmbedding(String imageUri) {
    return FaceNativePlatform.instance.testGetFaceEmbedding(imageUri);
  }

  Future<List<FaceImageRecord>> getNearestPersonName(String imageUri) {
    return FaceNativePlatform.instance.getNearestPersonName(imageUri);
  }
}
