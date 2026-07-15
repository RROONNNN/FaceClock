package com.example.face_native.di

import com.example.face_native.data.ImagesVectorDB
import com.example.face_native.domain.ImageVectorUseCase
import com.example.face_native.domain.embeddings.FaceNet
import com.example.face_native.domain.face_detection.FaceSpoofDetector
import com.example.face_native.domain.face_detection.MediapipeFaceDetector
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.dsl.module
@Module
@ComponentScan("com.example.face_native")
class AppModule {
    val module = module {
        single(createdAtStart = true) { ImagesVectorDB() }
        single() { FaceNet(context = get()) }
        single() { FaceSpoofDetector(context = get()) }
        single() { MediapipeFaceDetector(context = get()) }
        single(createdAtStart = true) {
            ImageVectorUseCase(
                mediapipeFaceDetector = get(),
                faceSpoofDetector = get(),
                imagesVectorDB = get(),
                faceNet = get()
            )
        }
    }
}
