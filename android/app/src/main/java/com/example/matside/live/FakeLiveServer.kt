package com.example.matside.live

import android.content.Context
import android.os.SystemClock
import com.example.matside.model.Bout
import com.example.matside.model.LiveEvent
import com.example.matside.model.LiveUpdate
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Stands in for the realtime backend. Replays `feed.json` on a loop, timed from app launch,
 * so every connection sees the same timeline. Nothing here touches the network.
 */
class FakeLiveServer(val script: FeedScript) {
    private val startMillis = SystemClock.elapsedRealtime()

    /** Opens a connection that emits raw JSON frames, like a WebSocket would. */
    fun connect(): Flow<String> = flow {
        val loopMillis = (script.loopSeconds * 1000).toLong()
        var elapsed = now()
        var loopIndex = (elapsed / loopMillis).toInt()

        while (true) {
            val loopStart = loopIndex * loopMillis
            if (loopIndex > 0 && elapsed - loopStart < 1000) {
                emit(json.encodeToString(FeedFrame.serializer(), FeedFrame.Snapshot(loopIndex * 100, script.bouts)))
            }
            for (frame in script.frames) {
                val at = loopStart + (frame.at * 1000).toLong()
                if (at <= elapsed) continue
                val wait = at - now()
                if (wait > 0) delay(wait)
                val update = frame.update.copy(seq = loopIndex * 100 + frame.update.seq)
                emit(json.encodeToString(FeedFrame.serializer(), FeedFrame.Update(update)))
            }
            loopIndex += 1
            val nextLoop = loopIndex * loopMillis - now()
            if (nextLoop > 0) delay(nextLoop)
            elapsed = now()
        }
    }

    private fun now() = SystemClock.elapsedRealtime() - startMillis

    companion object {
        val json = Json { ignoreUnknownKeys = true; classDiscriminator = "type" }

        @Volatile private var instance: FakeLiveServer? = null

        fun get(context: Context): FakeLiveServer = instance ?: synchronized(this) {
            instance ?: FakeLiveServer(FeedScript.load(context)).also { instance = it }
        }
    }
}

/** The wire format of a frame on the live connection. */
@Serializable
sealed class FeedFrame {
    @Serializable
    @SerialName("snapshot")
    data class Snapshot(val seq: Int, val bouts: List<Bout>) : FeedFrame()

    @Serializable
    @SerialName("update")
    data class Update(val update: LiveUpdate) : FeedFrame()
}

@Serializable
data class FeedScript(
    val event: LiveEvent,
    val bouts: List<Bout>,
    val loopSeconds: Double,
    val frames: List<Frame>,
) {
    @Serializable
    data class Frame(val at: Double, val update: LiveUpdate)

    companion object {
        fun load(context: Context): FeedScript {
            val text = context.assets.open("feed.json").bufferedReader().use { it.readText() }
            return FakeLiveServer.json.decodeFromString(serializer(), text)
        }
    }
}
