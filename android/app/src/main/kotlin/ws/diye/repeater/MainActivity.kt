package ws.diye.repeater

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ws.diye/repeater"
    private lateinit var recorder: Recorder
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val sharedPreferences = activity.getSharedPreferences("ws.diye.repeater.SHARED_PRE_1", Context.MODE_PRIVATE)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        recorder = Recorder(methodChannel, sharedPreferences)
        methodChannel.setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startRecord" -> {
                    recorder.start()
                    result.success(true)
                }
                "stopRecord" -> {
                    recorder.stop()
                    result.success(true)
                }
                "replay" -> {
                    recorder.replay()
                    result.success(true)
                }
                "seek" -> {
                    recorder.player.seekTo(call.argument<Int>("position") as Int)
                    result.success(true)
                }
                "getCurrentPosition" -> {
                    result.success(if (recorder.isPrepared) recorder.player.currentPosition else 0)
                }
                "getRecordEncoder" -> {
                    result.success(recorder.getRecordEncoder())
                }
                "setRecordEncoder" -> {
                    val res = recorder.setRecordEncoder(call.argument<Int>("encoder") as Int)
                    result.success(res)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
