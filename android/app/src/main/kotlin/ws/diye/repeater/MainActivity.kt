package ws.diye.repeater

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"
    private lateinit var recorder: Recorder;

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "startRecord") {
                recorder = Recorder()
                recorder.start()
            } else if (call.method == "stopRecord") {
                recorder.stop()
            } else if (call.method == "replay") {
                recorder.replay()
            } else {
                result.notImplemented()
            }
        }
    }
}
