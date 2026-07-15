class ImageVectorUseCase {
  // MARK: - Singleton
  static let shared = ImageVectorUseCase()
  
  private let imagesVectorDB: ImagesVectorDB
  private let faceNet: FaceNet
  private let faceSpoofDetector: FaceSpoofDetector
  private let mediapipeFaceDetector: MediapipeFaceDetector

  private init() {
    self.imagesVectorDB = ImagesVectorDB.shared
    self.faceNet = FaceNet.shared
    self.faceSpoofDetector = FaceSpoofDetector.shared
    self.mediapipeFaceDetector = MediapipeFaceDetector.shared
}
func addImage(empId:Int64, personName:String, imageUri:String) async -> Result<Int64, Error> {
  do {
   guard let imageUrl = URL(string: imageUri) else {
     print("Invalid image URL")
     return Result.failure(AppException(code: .faceDetectorFailure))
   }
      let faceDetectionResult =  await mediapipeFaceDetector.getCroppedFace(imageUrl: imageUrl)
          let image = try faceDetectionResult.get()
      let embedding = try await faceNet.getFaceEmbedding(image:image)
     let id = try imagesVectorDB.addFaceImageRecord(record:  FaceImageRecord(empId: empId, personName: personName, faceEmbedding: embedding))
       let idInt64 = Int64(id)
      print("idInt64 result: \(idInt64)")
     return Result.success(idInt64)
  }
  catch let error {
   print("Error in addImage: \(error.localizedDescription)")
   return Result.failure(AppException(code: .faceDetectorFailure))
  }
}
    
func getNearestPersonName( imageUri: String) async -> Result<FaceImageRecord, Error> {
 do {
     guard let imageUrl = URL(string: imageUri) else {
       print("Invalid image URL")
       return Result.failure(AppException(code: .faceDetectorFailure))
     }
     let faceDetectionResult =  await mediapipeFaceDetector.getCroppedFace(imageUrl: imageUrl)
         let image = try faceDetectionResult.get()
     UIUtilities.saveBitmap(image, name: "getNearest_after_normalize.png")
    let embedding = try await faceNet.getFaceEmbedding(image: image)
    let recognitionResult = try  imagesVectorDB.getNearestEmbeddingPersonName(embedding: embedding)
    print("recognitionResult: \(recognitionResult?.personName ?? "")")
    return Result.success(recognitionResult ?? FaceImageRecord(empId: -1, personName: "Not_recognized", faceEmbedding: []))
 }
 catch let error {
   print("Error in getNearestPersonName: \(error.localizedDescription)")
   return Result.failure(AppException(code: .faceDetectorFailure))
 }
}
    
func getAllRecords() async -> Result<[FaceImageRecord], Error> {
 do {
   let records = try imagesVectorDB.getAllRecords()
   return Result.success(records)
 }
 catch let error {
   print("Error in getAllRecords: \(error)")
   return Result.failure(AppException(code: .faceDetectorFailure))
 }
}

func getImageIdsByEmpId(empId:Int64) async -> Result<[Int64], Error> {
  do {
   let ids = try imagesVectorDB.getImageIdsByEmpId(empId: empId)
   return Result.success(ids)
  }
  catch let error {
   print("Error in getImageIdsByEmpId: \(error.localizedDescription)")
   return Result.failure(AppException(code: .faceDetectorFailure))
  }
}

}
