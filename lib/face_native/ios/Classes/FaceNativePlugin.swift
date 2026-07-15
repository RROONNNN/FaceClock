import Flutter
import UIKit

public class FaceNativePlugin: NSObject, FlutterPlugin {
  private let imageVectorUseCase: ImageVectorUseCase = ImageVectorUseCase.shared
    private let imagesVectorDB: ImagesVectorDB = ImagesVectorDB.shared
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "face_native", binaryMessenger: registrar.messenger())
    let instance = FaceNativePlugin()
    ObjectBoxStore.initialize(tenantKey: "test")
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

     func getUIImageFromPath(path: String) throws -> UIImage {
         guard let imageUrl = URL(string: path) else {
      print ("Error in getUIImageFromPath: Invalid image URL")
           throw FaceNetError.invalidImageUrl
         }
         if !FileManager.default.fileExists(atPath: imageUrl.path) {
             print("❌ File does not exist at path: \(imageUrl.path)")
          print("Error in getUIImageFromPath: File does not exist at path: \(imageUrl.path)")
             throw FaceNetError.invalidImageUrl
         }
         let image = UIImage(contentsOfFile: imageUrl.path)
         if image == nil {
          print("Error in getUIImageFromPath: Failed to create UIImage from data")
          throw FaceNetError.invalidImageUrl
         }
         return image!
        
    }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    case "initObjectBox":
      guard let args = call.arguments as? [String: Any],
            let tenantKey = args["tenantKey"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "TenantKey is required", details: nil))
        return
      }
      
     let isInitialized = ObjectBoxStore.initialize(tenantKey: tenantKey)
      if isInitialized {
        result(true)
      } else {
        result(FlutterError(code: "INIT_OBJECT_BOX_ERROR", message: "Failed to initialize ObjectBox with tenant key: \(tenantKey)", details: nil))
      }
      case "getFaceImageRecordByListEmpId" :
      guard let args = call.arguments as? [String: Any],
      let empIdList = args["empIdList"] as? [Int64] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "EmpId list is required", details: nil))
        return
      }
        do {
            let records = try imagesVectorDB.getFaceImageRecordByListEmpId(empIdList: empIdList)
            result(records.map { record in return
              [
                "empId": record.empId,
                "personName": record.personName,
                "faceEmbedding": record.faceEmbedding
              ]
            })
        }
        catch {
          result(FlutterError(code: "GET_FACE_IMAGE_RECORD_BY_LIST_EMP_ID_ERROR", message: error.localizedDescription, details: nil))
        }
    case "getCount" :
      do {
        let count = try imagesVectorDB.getCount()
        result(count)
      }
      catch {
        result(FlutterError(code: "GET_COUNT_ERROR", message: error.localizedDescription, details: nil))
      }
      case "addAllRecords" :
      guard let args = call.arguments as? [String: Any],
      let recordsMap = args["records"] as? [[String: Any]] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Records is required", details: nil))
        return
      }
      do {
          let filteredRecords = recordsMap.filter { record in
              (record["faceEmbedding"] as? [Float])?.isEmpty == false &&
              (record["empId"] as? Int64) != nil
          }

          let records = filteredRecords.map { record in
              FaceImageRecord(
                  empId: record["empId"] as! Int64,
                  personName: record["personName"] as? String ?? "",
                  faceEmbedding: record["faceEmbedding"] as! [Float]
              )
          }     
          try imagesVectorDB.addAllRecords(records: records)
        result(true)
      }
      catch {
          result(FlutterError(code: "ADD_ALL_RECORDS_ERROR", message: error.localizedDescription , details: nil))
      }
      case "getAllImages" :
      do {
     let records = try imagesVectorDB.getAllRecords()
    result(records.map { record in
      [
        "empId": record.empId,
        "personName": record.personName,
        "faceEmbedding": record.faceEmbedding
      ]
    })
      }
      catch {
        result(FlutterError(code: "GET_ALL_IMAGES_ERROR", message: error.localizedDescription, details: nil))
      }
      case "removeImages" :
      guard let args = call.arguments as? [String: Any],
      let empId = args["empId"] as? Int64 else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "EmpId is required", details: nil))
        return
      }
      do {
        try imagesVectorDB.removeFaceRecordsWithEmpId(empId: empId)
        result(true)
      }
      catch {
        result(FlutterError(code: "REMOVE_IMAGES_ERROR", message: error.localizedDescription, details: nil))
      }
      case "getImageIdsByEmpId" :
      guard let args = call.arguments as? [String: Any],
      let empId = args["empId"] as? Int64 else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "EmpId is required", details: nil))
        return
      }
      do {
        let ids = try imagesVectorDB.getImageIdsByEmpId(empId: empId)
        result(ids)
      }
      catch {
        result(FlutterError(code: "GET_IMAGE_IDS_BY_EMP_ID_ERROR", message: error.localizedDescription, details: nil))
      }
      case "removeImagesByIds" :
      guard let args = call.arguments as? [String: Any],
      let imageIds = args["imageIds"] as? [Int64] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "ImageIds is required", details: nil))
        return
      }
      do {
        try imagesVectorDB.removeFaceRecordsByIds(imageIds: imageIds)
        result(true)
      }
      catch {       
        result(FlutterError(code: "REMOVE_IMAGES_BY_IDS_ERROR", message: error.localizedDescription, details: nil))
      }
    case "testGetCroppedFace":
        let testString="abc"
        print(testString)
      guard let args = call.arguments as? [String: Any],
            let imageUri = args["imageUri"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "ImageUri is required", details: nil))
        return
      }
        print(imageUri)
      Task {
        guard let imageUrl = URL(string: imageUri) else {
          result(FlutterError(code: "INVALID_URL", message: "Invalid image URL", details: nil))
          return
        }
        let faceDetector = MediapipeFaceDetector.shared
        let croppedFaceResult = await faceDetector.getCroppedFace(imageUrl: imageUrl)
        switch croppedFaceResult {
        case .success(let croppedImage):
          print("croppedImage success")
          result(true)
        case .failure(let error):
          result(FlutterError(code: error.code.rawValue, message: error.localizedDescription, details: nil))
        }
      }
    case "testGetFaceEmbedding":
      guard let args = call.arguments as? [String: Any],
            let imageUri = args["imageUri"] as? String else {
        result(FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "ImageUri is required",
          details: nil
        ))
        return
      }
        print("imageUri in testGetFaceEmbedding  \(imageUri)")
      Task {
        do {
          guard let imageUrl = URL(string: imageUri) else {
            result(FlutterError(
              code: "INVALID_URL",
              message: "Invalid image URL",
              details: nil
            ))
            return
          }
          let faceNet = FaceNet.shared
            print("🔍 Starting getCroppedFace with URL: \(imageUrl)")
            // Load image from URL
            if !FileManager.default.fileExists(atPath: imageUrl.path) {
                print("❌ File does not exist at path: \(imageUrl.path)")
                result(
                  FlutterError(
                    code: "FILE_NOT_FOUND",
                    message: "File does not exist at path: \(imageUrl.path)",
                    details: nil
                  ))
                return
            }
            
            guard let image = UIImage.init(contentsOfFile: imageUrl.path) else {
                print("❌ Failed to create UIImage from data")
                result(
                  FlutterError(
                    code: "FAILED_TO_CREATE_UIImage",
                    message: "Failed to create UIImage from data",
                    details: nil
                  ))
                return
            }
          let embedding = try await faceNet.getFaceEmbedding(image: image)
          result(embedding)
        } catch {
          result(FlutterError(
            code: "FACE_EMBEDDING_ERROR",
            message: "Failed to get face embedding: \(error.localizedDescription)",
            details: nil
          ))
        }
      }
    case "addImage" :
      guard let args = call.arguments as? [String: Any],
            let empId = args["empId"] as? Int64,
            let personName = args["personName"] as? String,
            let imageUri = args["imageUri"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "EmpId, personName, and imageUri are required", details: nil))
        return
      }
      Task {
        do {
//          let image = try getUIImageFromPath(path: imageUri)
          let recognitionResult =  await imageVectorUseCase.addImage(empId: empId, personName: personName, imageUri: imageUri)
          switch recognitionResult {
          case .success(let id):
            result(id)
          case .failure(let error):
            result(FlutterError(code: "ADD_IMAGE_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
    case "recognizeFace" :
      guard let args = call.arguments as? [String: Any],
      let imageUrl = args["imageUrl"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "ImageUrl is required", details: nil))
        return
      }
      Task {
        do {
            let recognitionResult = await self.imageVectorUseCase.getNearestPersonName(imageUri: imageUrl)
          switch recognitionResult {
          case .success(let recognitionResult):
            print("recognitionResult in recognizeFace: \(recognitionResult.toMap())")
            result([
              "result": recognitionResult.toMap()
            ])
          case .failure(let error):
            result(FlutterError(code: "RECOGNIZE_FACE_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
      case "getAllImages" :
      Task {
        do {
          let records = await self.imageVectorUseCase.getAllRecords()
          switch records {
          case .success(let records):
          print("records in getAllImages: \(records.map { $0.toMap() })")
            result(records.map { $0.toMap() })
          case .failure(let error):
          result(FlutterError(code: "GET_ALL_RECORDS_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
