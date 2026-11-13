package com.example.matside.event

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.matside.live.FakeLiveServer
import com.example.matside.live.FeedFrame
import com.example.matside.live.LiveEventManager
import com.example.matside.model.Bout
import com.example.matside.model.LiveEvent
import com.example.matside.model.apply
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class EventUiState(
    val event: LiveEvent? = null,
    val bouts: List<Bout> = emptyList(),
    val isLoading: Boolean = true,
)

class EventViewModel(application: Application) : AndroidViewModel(application) {
    private val server = FakeLiveServer.get(application)
    private val repository = EventRepository(server)
    private val liveEvents = LiveEventManager.get(server)

    private val _state = MutableStateFlow(EventUiState())
    val state: StateFlow<EventUiState> = _state.asStateFlow()

    private var subscription: Int? = null
    private var hasLoaded = false

    fun start() {
        if (hasLoaded) return
        hasLoaded = true

        viewModelScope.launch {
            val (event, bouts) = repository.loadEvent()
            _state.value = EventUiState(event = event, bouts = bouts, isLoading = false)
            subscription = liveEvents.subscribe(::handle)
        }
    }

    fun stop() {
        subscription?.let { liveEvents.unsubscribe(it) }
        subscription = null
    }

    override fun onCleared() {
        stop()
    }

    private fun handle(frame: FeedFrame) {
        when (frame) {
            is FeedFrame.Snapshot -> _state.update { it.copy(bouts = frame.bouts) }
            is FeedFrame.Update -> _state.update { state ->
                state.copy(bouts = state.bouts.map { bout ->
                    if (bout.id == frame.update.boutId) bout.apply(frame.update) else bout
                })
            }
        }
    }
}
