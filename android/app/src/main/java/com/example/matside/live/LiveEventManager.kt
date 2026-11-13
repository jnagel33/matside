package com.example.matside.live

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Shares one live connection between every screen that needs event updates.
 * The connection opens with the first subscriber and closes when the last one leaves.
 */
class LiveEventManager(private val server: FakeLiveServer) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val subscribers = mutableMapOf<Int, (FeedFrame) -> Unit>()
    private var nextId = 0
    private var connection: Job? = null

    fun subscribe(handler: (FeedFrame) -> Unit): Int {
        val id = nextId++
        subscribers[id] = handler
        if (connection == null) open()
        return id
    }

    fun unsubscribe(id: Int) {
        subscribers.remove(id)
        if (subscribers.isEmpty()) {
            connection?.cancel()
            connection = null
        }
    }

    private fun shutdown() {
        subscribers.clear()
        connection?.cancel()
        connection = null
    }

    private fun open() {
        connection = scope.launch {
            server.connect().collect { raw ->
                val frame = runCatching { FakeLiveServer.json.decodeFromString(FeedFrame.serializer(), raw) }
                    .getOrNull() ?: return@collect
                subscribers.values.toList().forEach { it(frame) }
            }
        }
    }

    companion object {
        @Volatile private var instance: LiveEventManager? = null

        fun get(server: FakeLiveServer): LiveEventManager = instance ?: synchronized(this) {
            instance ?: LiveEventManager(server).also { instance = it }
        }

        /** Drops every subscriber and closes the connection; the next [get] reconnects from 0:00. */
        fun restart() {
            instance?.shutdown()
            instance = null
            FakeLiveServer.restart()
        }
    }
}
