package com.example.face_native.domain.face_detection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.net.Uri
import android.util.Log
import androidx.core.graphics.toRect
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.example.face_native.domain.AppException
import com.example.face_native.domain.ErrorCode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.annotation.Single
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import kotlin.math.log

// Utility class for interacting with Mediapipe's Face Detector
// See https://ai.google.dev/edge/mediapipe/solutions/vision/face_detector/android
@Single
class MediapipeFaceDetector(
    private val context: Context,
) {
    // The model is stored in the assets folder
    private val modelName = "blaze_face_short_range.tflite"
    private val baseOptions = BaseOptions.builder().setModelAssetPath(modelName).build()
    private val faceDetectorOptions =
        FaceDetector.FaceDetectorOptions
            .builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .build()
    private val faceDetector = FaceDetector.createFromOptions(context, faceDetectorOptions)

    suspend fun getCroppedFace(imageUri: Uri): Result<Bitmap> =
        withContext(Dispatchers.IO) {
            try {
                // Try to handle both content URIs and file paths
                Log.d("imageUri.scheme", "getCroppedFace: ${imageUri.scheme}")
                val imageBitmap = if (imageUri.scheme == "content") {
                    // Handle content URI
                    var imageInputStream =
                        context.contentResolver.openInputStream(imageUri)
                            ?: return@withContext Result.failure<Bitmap>(
                                AppException(ErrorCode.FACE_DETECTOR_FAILURE),
                            )
                    val bitmap = BitmapFactory.decodeStream(imageInputStream)
                    imageInputStream.close()
                    bitmap
                } else {
                    // Handle file path
                    val filePath = imageUri.path ?: imageUri.toString()
                    BitmapFactory.decodeFile(filePath)
                        ?: return@withContext Result.failure<Bitmap>(
                            AppException(ErrorCode.FACE_DETECTOR_FAILURE),
                        )
                }
                // Handle EXIF rotation for file paths
                val rotatedBitmap = if (imageUri.scheme != "content") {
                    val filePath = imageUri.path ?: imageUri.toString()
                    val exifInterface = ExifInterface(filePath)
//                    Log.d("exifInterface", "getCroppedFace: ${exifInterface.}");
                    val orientation = exifInterface.getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_UNDEFINED
                    )
                    
                    when (orientation) {
                        ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(imageBitmap, 90f)
                        ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(imageBitmap, 180f)
                        ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(imageBitmap, 270f)
                        else -> imageBitmap
                    }
                } else {
                    // For content URIs, handle EXIF the original way
                    var imageInputStream =
                        context.contentResolver.openInputStream(imageUri)
                            ?: return@withContext Result.failure<Bitmap>(
                                AppException(ErrorCode.FACE_DETECTOR_FAILURE),
                            )
                    val exifInterface = ExifInterface(imageInputStream)
                    imageInputStream.close()
                    
                    val orientation = exifInterface.getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_UNDEFINED
                    )
                    
                    when (orientation) {
                        ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(imageBitmap, 90f)
                        ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(imageBitmap, 180f)
                        ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(imageBitmap, 270f)
                        else -> imageBitmap
                    }
                }

                // We need exactly one face in the image, in other cases, return the
                // necessary errors
                val faces = faceDetector.detect(BitmapImageBuilder(rotatedBitmap).build()).detections()
                if (faces.size > 1) {
                    return@withContext Result.failure<Bitmap>(AppException(ErrorCode.MULTIPLE_FACES))
                } else if (faces.size == 0) {
                    return@withContext Result.failure<Bitmap>(AppException(ErrorCode.NO_FACE))
                } else {
                    // Validate the bounding box and
                    // return the cropped face
                    val rect = faces[0].boundingBox().toRect()
                    if (validateRect(rotatedBitmap, rect)) {
                        val croppedBitmap =
                            Bitmap.createBitmap(
                                rotatedBitmap,
                                rect.left,
                            rect.top,
                            rect.width(),
                            rect.height(),
                        )
                    // i want save croppedBitmap to file /data/data/com.paracel.face_timekeeping.face_time_keeping/cache
                      // get ramdom number
                    // val randomNum = (100000..999999).random()
                    //     saveBitmap(context,croppedBitmap, "r${randomNum}"   )


                    return@withContext Result.success(croppedBitmap)
                } else {
                        return@withContext Result.failure<Bitmap>(
                            AppException(ErrorCode.FACE_DETECTOR_FAILURE),
                        )
                    }
                }
            } catch (e: Exception) {
                return@withContext Result.failure<Bitmap>(
                    AppException(ErrorCode.FACE_DETECTOR_FAILURE),
                )
            }
        }

    // Detects multiple faces from the `frameBitmap`
    // and returns pairs of (croppedFace , boundingBoxRect)
    // Used by ImageVectorUseCase.kt
    suspend fun getAllCroppedFaces(frameBitmap: Bitmap): List<Pair<Bitmap, Rect>> =
        withContext(Dispatchers.IO) {
            // val filePath = saveBitmap(context,frameBitmap, "frameBitmap1" )
            return@withContext faceDetector
                .detect(BitmapImageBuilder(frameBitmap).build())
                .detections()
                .filter { validateRect(frameBitmap, it.boundingBox().toRect()) }
                .map { detection -> detection.boundingBox().toRect() }
                .map { rect ->
                    val croppedBitmap =
                        Bitmap.createBitmap(
                            frameBitmap,
                            rect.left,
                            rect.top,
                            rect.width(),
                            rect.height(),
                        )
                    // val randomNum = (100000..999999).random()
                    // saveBitmap(context,croppedBitmap, "rab${randomNum}"  )
                    Pair(croppedBitmap, rect)
                }
        }

    // DEBUG: For testing purpose, saves the Bitmap to the app's private storage
    fun saveBitmap(
        context: Context,
        image: Bitmap,
        name: String,
    ) :String {
        val path= context.filesDir.absolutePath + "/$name.png"
        val fileOutputStream = FileOutputStream(File(path))
//        Log.d("MediapipeFaceDetector", "Saving image to ${context.filesDir.absolutePath}/$name.png")
        image.compress(Bitmap.CompressFormat.PNG, 100, fileOutputStream)
        return path
    }

    private fun rotateBitmap(
        source: Bitmap,
        degrees: Float,
    ): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, false)
    }

    // Check if the bounds of `boundingBox` fit within the
    // limits of `cameraFrameBitmap`
    private fun validateRect(
        cameraFrameBitmap: Bitmap,
        boundingBox: Rect,
    ): Boolean =
        boundingBox.left >= 0 &&
            boundingBox.top >= 0 &&
            (boundingBox.left + boundingBox.width()) < cameraFrameBitmap.width &&
            (boundingBox.top + boundingBox.height()) < cameraFrameBitmap.height
}
