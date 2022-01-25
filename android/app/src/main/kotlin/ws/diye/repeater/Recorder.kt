package ws.diye.repeater

import android.media.AudioAttributes
import android.media.MediaDataSource
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper

import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.InputStream


class Recorder constructor(private val methodChannel: MethodChannel) {
    var running = false
    var isPrepared = false
    private lateinit var recorderRunner: RecorderRunner
    val player: MediaPlayer = MediaPlayer()

    fun start() {
        if (isPrepared) player.stop()
        recorderRunner = RecorderRunner(::bc)
        recorderRunner.start()
    }

    fun stop() {
        recorderRunner.interrupt()
    }

    fun replay() {
        player.start()
    }

    private fun bc(buffer: ByteDataSource) {
        isPrepared = false
        player.reset()
        player.setDataSource(buffer)
        player.prepare()
        isPrepared = true
        sendDuration()
        player.start()
    }

    private fun sendDuration() {
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod("updateDuration", player.duration)
        }
    }

    private fun setupPlayer() {
        player.setAudioAttributes(
                AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
        )
    }

    init {
        setupPlayer()
    }
}

class RecorderRunner constructor(
        private val byteDataCallback: (buffer: ByteDataSource) -> Unit
): Thread() {
    override fun run() {
        // Byte array for audio record
        // Byte array for audio record
        val byteArrayOutputStream = ByteArrayOutputStream()

        val descriptors = ParcelFileDescriptor.createPipe()
        val parcelRead = ParcelFileDescriptor(descriptors[0])
        val parcelWrite = ParcelFileDescriptor(descriptors[1])

        val inputStream: InputStream = ParcelFileDescriptor.AutoCloseInputStream(parcelRead)

        val recorder = MediaRecorder()
        recorder.setAudioSamplingRate(192000)
        recorder.setAudioEncodingBitRate(192000)
        recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.AAC_ADTS)
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        recorder.setOutputFile(parcelWrite.fileDescriptor)
        recorder.prepare()

        recorder.start()

        var read = 0
        val data = ByteArray(16384)


        while (inputStream.read(data, 0, data.size).also({ read = it }) != -1) {
            if (isInterrupted) {
                break;
            }
            byteArrayOutputStream.write(data, 0, read)
        }

        byteArrayOutputStream.flush()
        val byteDataSource = ByteDataSource(byteArrayOutputStream.toByteArray())
        recorder.release()
        byteDataCallback(byteDataSource)
    }
}

class ByteDataSource(
        private val data: ByteArray
) : MediaDataSource() {
    @Synchronized
    override fun getSize(): Long {
        return data.size.toLong()
    }

    @Synchronized
    override fun close() = Unit

    @Synchronized
    override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
        if (position >= data.size) {
            return -1
        }

        var remainingSize = size
        if (position + remainingSize > data.size) {
            remainingSize -= position.toInt() + remainingSize - data.size
        }
        System.arraycopy(data, position.toInt(), buffer, offset, remainingSize)
        return remainingSize
    }
}