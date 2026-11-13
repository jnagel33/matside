package com.example.matside.event

import com.example.matside.live.FakeLiveServer
import com.example.matside.model.Bout
import com.example.matside.model.LiveEvent
import kotlinx.coroutines.delay

/** Loads the event and its bouts. Backed by the bundled script; the delay stands in for a request. */
class EventRepository(private val server: FakeLiveServer) {
    suspend fun loadEvent(): Pair<LiveEvent, List<Bout>> {
        delay(400)
        return server.script.event to server.script.bouts
    }
}
