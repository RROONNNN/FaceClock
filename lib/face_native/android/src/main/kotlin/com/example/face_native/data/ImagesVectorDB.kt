package com.example.face_native.data

import android.util.Log
import org.koin.core.annotation.Single
import com.example.face_native.data.FaceImageRecord

@Single
class ImagesVectorDB {
    private val imagesBox get() = ObjectBoxStore.store.boxFor(FaceImageRecord::class.java)

    fun addFaceImageRecord(record: FaceImageRecord): Long {
        val id= imagesBox.put(record)
        return id;
    }
    
    // get all records where faceEmbedding is not null
    fun getAllRecords(): List<FaceImageRecord> {
        return imagesBox
            .query(FaceImageRecord_.faceEmbedding.notNull())
            .build()
            .find()
    }

    fun getNearestEmbeddingPersonName(
        embedding: FloatArray,
        thresholdScore: Float = 0.1f,
    ): FaceImageRecord? {
        // Get nearest neighbors and filter by threshold
        // Lower score = closer distance = better match
        val results = imagesBox
            .query(FaceImageRecord_.faceEmbedding.nearestNeighbors(embedding, 150))
            .build()
            .findWithScores()
            .onEach { println("Score: ${it.score}") }
            .filter { it.score <= thresholdScore } // Keep only good matches
        
        // Return the record with the LOWEST score (closest match)
        val bestMatch = results.minByOrNull { it.score }
        if (bestMatch != null) {
            Log.d("ImagesVectorDB", "Best match score: ${bestMatch.score}")
        } else {
            Log.d("ImagesVectorDB", "No match found below threshold: $thresholdScore")
        }
        return bestMatch?.get()
    }

    fun removeFaceRecordsWithEmpId(empId: Long) {
        imagesBox.removeByIds(
            imagesBox
                .query(FaceImageRecord_.empId.equal(empId))
                .build()
                .findIds()
                .toList(),
        )
    }
    fun getFaceImageRecordByListEmpId(empIdList: List<Long>): List<FaceImageRecord> {
        return imagesBox
            .query(FaceImageRecord_.empId.oneOf(empIdList.toLongArray()))
            .build()
            .find()
    }
    fun getImageIdsByEmpId(empId: Long): List<Long> {
        return imagesBox
            .query(FaceImageRecord_.empId.equal(empId))
            .build()
            .findIds()
            .toList()
    }
    fun removeFaceRecordsByIds(imageIds: List<Long>) {
        imagesBox.removeByIds(imageIds)
    }
    // clear all records
    fun clearAllRecords() {
        imagesBox.removeAll()
    }

    // get the count of all records
    fun getCount(): Long {
        return imagesBox.count()
    }
    // get the size (in bytes) of the database
    fun getDatabaseSizeInBytes(): Long {
        return try {
            val boxStore = imagesBox.store
            boxStore.dbSize
        } catch (e: Exception) {
            0L // Return 0 if unable to get size
        }
    }
}
