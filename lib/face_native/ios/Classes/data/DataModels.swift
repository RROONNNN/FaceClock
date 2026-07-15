import ObjectBox

// objectbox: entity
class FaceImageRecord {
    // Primary key of FaceImageRecord
    var id: Id = 0
    
    // empId references the PersonRecord primary key
    // objectbox: index
    var empId: Int64 = 0
    
    var personName: String = ""
    
    // The FaceNet model provides a 128-dimensional embedding
    // objectbox:hnswIndex: dimensions=128, distanceType=cosine, indexingSearchCount=400
    var faceEmbedding: [Float] = []
    
    required init() {} // Required by ObjectBox
    
    convenience init(id: Id = 0, empId: Int64, personName: String, faceEmbedding: [Float]) {
        self.init()
        self.id = id
        self.empId = empId
        self.personName = personName
        self.faceEmbedding = faceEmbedding
    }
    
    func toMap() -> [String: Any] {
        return [
            "employeeId": empId,
            "personName": personName,
            "faceEmbedding": faceEmbedding
        ]
    }
}

// Recognition metrics structure (not an entity)
struct RecognitionMetrics {
    let timeFaceDetection: Int64
    let timeVectorSearch: Int64
    let timeFaceEmbedding: Int64
    let timeFaceSpoofDetection: Int64
}
