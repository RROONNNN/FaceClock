import 'dart:typed_data';

import 'package:face_native/models/face_image_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face_native/face_native.dart';
import 'package:face_native/face_native_platform_interface.dart';
import 'package:face_native/face_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFaceNativePlatform with MockPlatformInterfaceMixin implements FaceNativePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> addAllRecords(List<FaceImageRecord> records) {
    // TODO: implement addAllRecords
    throw UnimplementedError();
  }

  @override
  Future<int> addImage(
      {required int empId,
      required String personName,
      required String? pin,
      required String imageUri}) {
    // TODO: implement addImage
    throw UnimplementedError();
  }

  @override
  Future<int> addPerson(String name, int numImages, int empId) {
    // TODO: implement addPerson
    throw UnimplementedError();
  }

  @override
  Future<bool> clearAllImages() {
    // TODO: implement clearAllImages
    throw UnimplementedError();
  }

  @override
  Future<List<FaceImageRecord>> getAllImages() {
    // TODO: implement getAllImages
    throw UnimplementedError();
  }

  @override
  Future<int> getCount() {
    // TODO: implement getCount
    throw UnimplementedError();
  }

  @override
  Future<String> getDatabaseSizeFormatted() {
    // TODO: implement getDatabaseSizeFormatted
    throw UnimplementedError();
  }

  @override
  Future<int> getDatabaseSizeInBytes() {
    // TODO: implement getDatabaseSizeInBytes
    throw UnimplementedError();
  }

  @override
  Future<List<FaceImageRecord>> getFaceImageRecordByListEmpId(List<int> empIdList) {
    // TODO: implement getFaceImageRecordByListEmpId
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getImageIdsByEmpId(int empId) {
    // TODO: implement getImageIdsByEmpId
    throw UnimplementedError();
  }

  @override
  Future<List<FaceImageRecord>> getNearestPersonName(String imageUri) {
    // TODO: implement getNearestPersonName
    throw UnimplementedError();
  }

  @override
  Future<bool> initObjectBox(String tenantKey) {
    // TODO: implement initObjectBox
    throw UnimplementedError();
  }

  @override
  Future<FaceRecognitionResponse> recognizeFace({Uint8List? imageBytes, String? imagePath}) {
    // TODO: implement recognizeFace
    throw UnimplementedError();
  }

  @override
  Future<bool> removeImages(int empId) {
    // TODO: implement removeImages
    throw UnimplementedError();
  }

  @override
  Future<bool> removeImagesByIds(List<int> imageIds) {
    // TODO: implement removeImagesByIds
    throw UnimplementedError();
  }

  @override
  Future<bool> testGetCroppedFace(String imageUri) {
    // TODO: implement testGetCroppedFace
    throw UnimplementedError();
  }

  @override
  Future<List<double>> testGetFaceEmbedding(String imageUri) {
    // TODO: implement testGetFaceEmbedding
    throw UnimplementedError();
  }
}

void main() {
  final FaceNativePlatform initialPlatform = FaceNativePlatform.instance;

  test('$MethodChannelFaceNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFaceNative>());
  });

  test('getPlatformVersion', () async {
    FaceNative faceNativePlugin = FaceNative();
    MockFaceNativePlatform fakePlatform = MockFaceNativePlatform();
    FaceNativePlatform.instance = fakePlatform;

    expect(await faceNativePlugin.getPlatformVersion(), '42');
  });
}
