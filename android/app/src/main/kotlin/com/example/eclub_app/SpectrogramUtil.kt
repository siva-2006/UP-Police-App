// android/app/src/main/kotlin/com/example/eclub_app/SpectrogramUtil.kt
package com.example.eclub_app

import com.jlibrosa.audio.JLibrosa

object SpectrogramUtil {
    private const val SAMPLE_RATE = 22050
    private const val N_MELS = 128
    private const val N_FFT = 2048
    private const val HOP_LENGTH = 512
    private const val AUDIO_DURATION_SECONDS = 3
    private const val TARGET_FRAMES = 130

    @JvmStatic
    fun getSpectrogram(audioFilePath: String): FloatArray {
        val jLibrosa = JLibrosa()

        // 1. Load raw audio samples (FloatArray)
        val audioSamples: FloatArray =
            jLibrosa.loadAndRead(audioFilePath, SAMPLE_RATE, AUDIO_DURATION_SECONDS * SAMPLE_RATE)

        // 2. Generate mel spectrogram (2D: [time, mel])
        val melSpec: Array<FloatArray> =
            jLibrosa.generateMelSpectroGram(audioSamples, SAMPLE_RATE, N_FFT, N_MELS, HOP_LENGTH)

        // 3. Ensure melSpec is in shape [N_MELS x timeFrames]
        val melSpecFixed = if (melSpec.size == N_MELS) {
            melSpec
        } else {
            transpose(melSpec) // convert [time, N_MELS] -> [N_MELS, time]
        }

        // 4. Pad/crop to TARGET_FRAMES (130)
        val fixed = Array(N_MELS) { FloatArray(TARGET_FRAMES) }
        val timeFrames = melSpecFixed[0].size
        val copyCols = minOf(timeFrames, TARGET_FRAMES)
        for (m in 0 until N_MELS) {
            System.arraycopy(melSpecFixed[m], 0, fixed[m], 0, copyCols)
        }

        // 5. Flatten into 1D FloatArray (size = 128*130)
        val flat = FloatArray(N_MELS * TARGET_FRAMES)
        var k = 0
        for (m in 0 until N_MELS) {
            for (t in 0 until TARGET_FRAMES) {
                flat[k++] = fixed[m][t]
            }
        }
        return flat
    }

    private fun transpose(a: Array<FloatArray>): Array<FloatArray> {
        val rows = a.size
        val cols = a[0].size
        val out = Array(cols) { FloatArray(rows) }
        for (r in 0 until rows) {
            for (c in 0 until cols) {
                out[c][r] = a[r][c]
            }
        }
        return out
    }
}
