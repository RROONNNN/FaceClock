package com.example.face_native.data

import io.objectbox.annotation.Entity
 import io.objectbox.annotation.Uid
import io.objectbox.annotation.HnswIndex
import io.objectbox.annotation.Id
import io.objectbox.annotation.Index
import io.objectbox.annotation.VectorDistanceType

@Entity
data class FaceImageRecord(
    // primary-key of `FaceImageRecord`
    @Id var recordID: Long = 0,
    // empId references the PersonRecord primary key
    @Index var empId: Long = 0,
    var personName: String = "",
    // the FaceNet-512 model provides a 512-dimensional embedding
    // the FaceNet model provides a 128-dimensional embedding
    @HnswIndex(
        dimensions = 128,
        distanceType = VectorDistanceType.COSINE,
        indexingSearchCount=400,
    ) var faceEmbedding: FloatArray = floatArrayOf(),
)


data class RecognitionMetrics(
    val timeFaceDetection: Long,
    val timeVectorSearch: Long,
    val timeFaceEmbedding: Long,
    val timeFaceSpoofDetection: Long,
)
