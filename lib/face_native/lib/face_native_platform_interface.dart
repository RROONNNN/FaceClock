import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:face_native/models/face_image_record.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'face_native_method_channel.dart';

abstract class FaceNativePlatform extends PlatformInterface {
  /// Constructs a FaceNativePlatform.
  FaceNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static FaceNativePlatform _instance = MethodChannelFaceNative();

  /// The default instance of [FaceNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelFaceNative].
  static FaceNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FaceNativePlatform] when
  /// they register themselves.
  static set instance(FaceNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> initObjectBox(String tenantKey) {
    return _instance.initObjectBox(tenantKey);
  }

  Future<List<FaceImageRecord>> getAllImages() {
    return _instance.getAllImages();
  }

  Future<int> getCount() {
    return _instance.getCount();
  }

  // Extended API to match MethodChannel implementation
  Future<List<FaceImageRecord>> getFaceImageRecordByListEmpId(
    List<int> empIdList,
  ) {
    return _instance.getFaceImageRecordByListEmpId(empIdList);
  }

  Future<bool> testGetCroppedFace(String imageUri) {
    return _instance.testGetCroppedFace(imageUri);
  }

  Future<bool> clearAllImages() {
    return _instance.clearAllImages();
  }

  Future<int> getDatabaseSizeInBytes() {
    return _instance.getDatabaseSizeInBytes();
  }

  Future<String> getDatabaseSizeFormatted() {
    return _instance.getDatabaseSizeFormatted();
  }

  Future<int> addPerson(String name, int numImages, int empId) {
    return _instance.addPerson(name, numImages, empId);
  }

  Future<int> addImage({
    required int empId,
    required String personName,
    required String? pin,
    required String imageUri,
  }) {
    return _instance.addImage(
      empId: empId,
      personName: personName,
      pin: pin,
      imageUri: imageUri,
    );
  }

  Future<bool> addAllRecords(List<FaceImageRecord> records) {
    return _instance.addAllRecords(records);
  }

  Future<FaceRecognitionResponse> recognizeFace({
    Uint8List? imageBytes,
    String? imagePath,
  }) {
    assert(imageBytes != null || imagePath != null,
        'Either imageBytes or imagePath must be provided');
    assert(!(imageBytes != null && imagePath != null),
        'Only one of imageBytes or imagePath should be provided');

    return _instance.recognizeFace(
      imageBytes: imageBytes,
      imagePath: imagePath,
    );
  }

  Future<bool> removeImages(int empId) {
    return _instance.removeImages(empId);
  }

  Future<List<int>> getImageIdsByEmpId(int empId) {
    return _instance.getImageIdsByEmpId(empId);
  }

  Future<bool> removeImagesByIds(List<int> imageIds) {
    return _instance.removeImagesByIds(imageIds);
  }

  Future<List<double>> testGetFaceEmbedding(String imageUri) {
    return _instance.testGetFaceEmbedding(imageUri);
  }

  Future<List<FaceImageRecord>> getNearestPersonName(String imageUri) {
    return _instance.getNearestPersonName(imageUri);
  }
}
