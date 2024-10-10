package com.yourcompany.yourapp

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.speech.tts.TextToSpeech
import android.content.Context
import java.util.*

// 移除这两行
// import com.yourcompany.yourapp.MainActivity
// import com.yourcompany.yourapp.R

class TtsService : Service(), TextToSpeech.OnInitListener {
    private val CHANNEL_ID = "TtsServiceChannel"
    private val NOTIFICATION_ID = 1
    private lateinit var tts: TextToSpeech
    private var isSpeaking = false

    override fun onCreate() {
        super.onCreate()
        tts = TextToSpeech(this, this)
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        when (intent.action) {
            "START" -> startSpeaking(intent.getStringExtra("text") ?: "")
            "STOP" -> stopSpeaking()
            "PAUSE" -> pauseSpeaking()
            "RESUME" -> resumeSpeaking()
        }
        return START_NOT_STICKY
    }

    private fun startSpeaking(text: String) {
        if (!isSpeaking) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "utteranceId")
            isSpeaking = true
            updateNotification("正在朗读")
        }
    }

    private fun stopSpeaking() {
        if (isSpeaking) {
            tts.stop()
            isSpeaking = false
            updateNotification("已停止")
        }
    }

    private fun pauseSpeaking() {
        if (isSpeaking) {
            tts.stop()
            isSpeaking = false
            updateNotification("已暂停")
        }
    }

    private fun resumeSpeaking() {
        // 实现恢复朗读的逻辑
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts.setLanguage(Locale.CHINESE)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                // 处理语言不支持的情况
            }
        } else {
            // 初始化失败
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "TTS Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun buildNotification(status: String): Notification {
        val notificationIntent = Intent(this, this::class.java) // 修改这行
        val pendingIntent = PendingIntent.getActivity(
            this,
            0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TTS 服务")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_media_play) // 修改这行
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun updateNotification(status: String) {
        val notification = buildNotification(status)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        tts.shutdown()
        super.onDestroy()
    }
}