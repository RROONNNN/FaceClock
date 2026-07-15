package com.example.face_native.domain


import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import android.net.Uri
import android.util.Log
import androidx.exifinterface.media.ExifInterface

import com.example.face_native.domain.embeddings.FaceNet
import com.example.face_native.domain.face_detection.FaceSpoofDetector
import com.example.face_native.domain.face_detection.MediapipeFaceDetector
import com.example.face_native.data.FaceImageRecord
import com.example.face_native.data.ImagesVectorDB
import com.example.face_native.data.RecognitionMetrics
import org.koin.core.annotation.Single
import kotlin.math.pow
import kotlin.math.sqrt
import kotlin.time.DurationUnit
import kotlin.time.measureTimedValue


@Single
class ImageVectorUseCase(
    private val mediapipeFaceDetector: MediapipeFaceDetector,
    private val faceSpoofDetector: FaceSpoofDetector,
    private val imagesVectorDB: ImagesVectorDB,
    private val faceNet: FaceNet,
) {
    data class FaceRecognitionResult(
        val empId: Long,
        val personName: String,
        val boundingBox: Rect,
        val spoofResult: FaceSpoofDetector.FaceSpoofResult? = null,
    )


    // Add the person's image to the database


    suspend fun addImage(
        empId: Long,
        personName: String,
        imageUri: Uri,

        ): Result<Long> {
        // Perform face-detection and get the cropped face as a Bitmap
        val faceDetectionResult = mediapipeFaceDetector.getCroppedFace(imageUri)
        if (faceDetectionResult.isSuccess) {
            // Get the embedding for the cropped face, and store it
            // in the database, along with `empId` and `personName`
            val embedding = faceNet.getFaceEmbedding(faceDetectionResult.getOrNull()!!)
            val id = imagesVectorDB.addFaceImageRecord(
                FaceImageRecord(
                    empId = empId,
                    personName = personName,
                    faceEmbedding = embedding,
                ),
            )
            return Result.success(id)
        } else {
            return Result.failure(
                faceDetectionResult.exceptionOrNull() ?: Exception("Unknown error in addImage")
            )
        }
    }

    fun getFaceImageRecordByListEmpId(empIdList: List<Long>): List<FaceImageRecord> {
        return imagesVectorDB.getFaceImageRecordByListEmpId(empIdList)
    }

    fun clearAllImages() {
        imagesVectorDB.clearAllRecords()
    }

    fun getCount(): Long {
        return imagesVectorDB.getCount()
    }

    fun getImageIdsByEmpId(empId: Long): List<Long> {
        return imagesVectorDB.getImageIdsByEmpId(empId)
    }

    fun getDatabaseSizeInBytes(): Long {
        return imagesVectorDB.getDatabaseSizeInBytes()
    }
    // From the given frame, return the name of the person by performing
    // face recognition

    private fun rotateBitmap(
        source: Bitmap,
        degrees: Float,
    ): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, false)
    }

    suspend fun getNearestPersonName(
        frameBitmap: Bitmap,
        exif: ExifInterface
    ): Pair<RecognitionMetrics?, List<FaceRecognitionResult>> {
        // Perform face-detection and get the cropped face as a Bitmap
        val frameBitmap = run {
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_UNDEFINED
            )
            Log.d("orientation", "getAllCroppedFaces: $orientation")
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(frameBitmap, 90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(frameBitmap, 180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(frameBitmap, 270f)
                else -> frameBitmap
            }
        }
        val (faceDetectionResult, t1) =
            measureTimedValue { mediapipeFaceDetector.getAllCroppedFaces(frameBitmap) }
        val faceRecognitionResults = ArrayList<FaceRecognitionResult>()
        var avgT2 = 0L
        var avgT3 = 0L
        var avgT4 = 0L
        for (result in faceDetectionResult) {
            // Get the embedding for the cropped face (query embedding)
            val (croppedBitmap, boundingBox) = result
            val (embedding, t2) = measureTimedValue { faceNet.getFaceEmbedding(croppedBitmap) }
            avgT2 += t2.toLong(DurationUnit.MILLISECONDS)
            // Perform nearest-neighbor search
            val (recognitionResult, t3) =
                measureTimedValue {
                    imagesVectorDB.getNearestEmbeddingPersonName(
                        embedding,
                        Constants.THRESHOLD_SCORE
                    )
                }
            avgT3 += t3.toLong(DurationUnit.MILLISECONDS)
            val spoofResult = faceSpoofDetector.detectSpoof(frameBitmap, boundingBox)
            avgT4 += spoofResult.timeMillis
            if (recognitionResult == null) {
                faceRecognitionResults.add(
                    FaceRecognitionResult(
                        -1L,
                        "Not_recognized",
                        boundingBox
                    )
                )
                continue
            } else {
                faceRecognitionResults.add(
                    FaceRecognitionResult(
                        recognitionResult.empId,
                        recognitionResult.personName,
                        boundingBox,
                        spoofResult
                    )
                )
            }

        }

        val metrics =
            if (faceDetectionResult.isNotEmpty()) {
                RecognitionMetrics(
                    timeFaceDetection = t1.toLong(DurationUnit.MILLISECONDS),
                    timeFaceEmbedding = avgT2 / faceDetectionResult.size,
                    timeVectorSearch = avgT3 / faceDetectionResult.size,
                    timeFaceSpoofDetection = avgT4 / faceDetectionResult.size,
                )
            } else {
                null
            }

        return Pair(metrics, faceRecognitionResults)
    }


//    private fun cosineDistance(
//        x1: FloatArray,
//        x2: FloatArray,
//    ): Float {
//        var mag1 = 0.0f
//        var mag2 = 0.0f
//        var product = 0.0f
//        for (i in x1.indices) {
//            mag1 += x1[i].pow(2)
//            mag2 += x2[i].pow(2)
//            product += x1[i] * x2[i]
//        }
//        mag1 = sqrt(mag1)
//        mag2 = sqrt(mag2)
//        return product / (mag1 * mag2)
//    }


    fun removeImages(empId: Long) {
        imagesVectorDB.removeFaceRecordsWithEmpId(empId)
    }

    fun removeImagesByIds(imageIds: List<Long>) {
        imagesVectorDB.removeFaceRecordsByIds(imageIds)
    }

    // get all Images
    fun getAllImages(): List<FaceImageRecord> {
        return imagesVectorDB.getAllRecords()
    }

    // add all images from the list
    fun addAllRecords(images: List<FaceImageRecord>) {
        for (image in images) {
            imagesVectorDB.addFaceImageRecord(image)
        }
    }
}
