import ObjectBox
import Foundation

class ImagesVectorDB {
    // MARK: - Singleton
    static let shared = ImagesVectorDB()
    
    private init() {}
    
private func getImagesBox() throws -> Box<FaceImageRecord> {
        do {
            return try ObjectBoxStore.store.box(for: FaceImageRecord.self)
        } catch {
            print("❌ Error getting ImagesBox:")
                   print("➡️ Type: \(type(of: error))")
                   print("➡️ Description: \(error.localizedDescription)")
                   print("➡️ Full error: \(error)")
                   throw error
        }
    }
    
    func addFaceImageRecord(record: FaceImageRecord) throws -> Id {
        let box = try getImagesBox()    
        let entityId = try box.put(record)
        return entityId.value
    }
    
    func addAllRecords(records: [FaceImageRecord]) throws {
        let box = try getImagesBox()
        _ = try box.put(records)
    }
    
    // Get all records where faceEmbedding is not empty
    func getAllRecords() throws -> [FaceImageRecord] {
        let box = try getImagesBox()
        return try box.all()
    }
    

    func getNearestEmbeddingPersonName(
        embedding: [Float],
        thresholdScore: Float = 0.1
    ) throws -> FaceImageRecord? {
        let box = try getImagesBox()
  
        let query = try box.query {
            FaceImageRecord.faceEmbedding.nearestNeighbors(
                queryVector: embedding,
                maxCount: 10
            )
        }
        .build()
        let results = try query.findWithScores()
        print("📊 Nearest neighbor search returned \(results.count) results")
        for (index, result) in results.prefix(5).enumerated() {
            print("  \(index + 1). Score: \(String(format: "%.4f", result.score)) - \(result.object.personName) (EmpID: \(result.object.empId))")
        }
        
        let bestMatch = results
            .filter { $0.score <= Double(thresholdScore) }
            .min(by: { $0.score < $1.score })
        
        if let match = bestMatch {
            print("✅ Best match: \(match.object.personName) with score \(String(format: "%.4f", match.score))")
        } else {
            print("❌ No match found below threshold \(thresholdScore)")
        }
        
        return bestMatch?.object
    }
    
    func removeFaceRecordsWithEmpId(empId: Int64) throws {
       do {
         let box = try getImagesBox()
        let query = try box.query {
            FaceImageRecord.empId == (empId)
        }
            .build()
        let ids = try query.findIds()
        for id in ids {
            try box.remove(id)
        }
       }
       catch {
        print("Error: removeFaceRecordsWithEmpId failed !!")
        print("Error: \(error.localizedDescription)")
        throw error
       }
    }
    
    func getFaceImageRecordByListEmpId(empIdList: [Int64]) throws -> [FaceImageRecord] {
        let box = try getImagesBox()
        let allRecords = try box.all()
        return allRecords.filter { empIdList.contains($0.empId) }
    }
    
    func getImageIdsByEmpId(empId: Int64) throws -> [Int64] {
        let box = try getImagesBox()
        let allRecords = try box.all()
        return allRecords.filter { $0.empId == empId }.map { Int64($0.id.value) }
    }
    
    func removeFaceRecordsByIds(imageIds: [Int64]) throws {
        let box = try getImagesBox()
        let ids = imageIds.map { Id($0) }
        try box.remove(ids)
    }
    
    // Clear all records
    func clearAllRecords() throws {
        let box = try getImagesBox()
        try box.removeAll()
    }
    
    // Get the count of all records
    func getCount() throws -> Int64 {
        let box = try getImagesBox()
        return Int64(try box.count())
    }
    
}

