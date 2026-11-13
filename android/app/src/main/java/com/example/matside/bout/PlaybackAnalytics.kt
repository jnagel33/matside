package com.example.matside.bout

import android.os.Handler
import android.os.Looper
import android.util.Log

/** Reports a playback heartbeat every few seconds while a session is open. */
object PlaybackAnalytics {
    private data class Session(val boutId: String, val position: () -> Long)

    private val sessions = mutableMapOf<Int, Session>()
    private var nextId = 0
    private val handler = Handler(Looper.getMainLooper())
    private var running = false

    private val heartbeat = object : Runnable {
        override fun run() {
            sessions.values.forEach { session ->
                Log.d("Analytics", "heartbeat bout=${session.boutId} position=${session.position() / 1000}s")
            }
            handler.postDelayed(this, 5_000)
        }
    }

    fun begin(boutId: String, position: () -> Long): Int {
        val id = nextId++
        sessions[id] = Session(boutId, position)
        if (!running) {
            running = true
            handler.postDelayed(heartbeat, 5_000)
        }
        return id
    }

    fun end(id: Int) {
        sessions.remove(id)
    }
}
