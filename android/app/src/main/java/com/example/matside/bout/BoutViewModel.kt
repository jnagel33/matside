package com.example.matside.bout

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.matside.live.FakeLiveServer
import com.example.matside.model.Bout
import com.example.matside.model.BoutStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class BoutViewModel(application: Application) : AndroidViewModel(application) {
    private val server = FakeLiveServer.get(application)

    private val _bout = MutableStateFlow<Bout?>(null)
    val bout: StateFlow<Bout?> = _bout.asStateFlow()

    fun start(boutId: String) {
        if (_bout.value != null) return
        _bout.value = server.script.bouts.first { it.id == boutId }

        viewModelScope.launch {
            server.connect().collect { raw ->
                val json = runCatching { Json.parseToJsonElement(raw).jsonObject }.getOrNull() ?: return@collect
                if (json["type"]?.jsonPrimitive?.contentOrNull != "update") return@collect
                val update = json["update"]?.jsonObject ?: return@collect
                if (update["boutId"]?.jsonPrimitive?.contentOrNull != boutId) return@collect

                _bout.update { current ->
                    current?.copy(
                        redScore = update["redScore"]?.jsonPrimitive?.intOrNull ?: current.redScore,
                        blueScore = update["blueScore"]?.jsonPrimitive?.intOrNull ?: current.blueScore,
                        period = update["period"]?.jsonPrimitive?.intOrNull ?: current.period,
                        status = when (update["status"]?.jsonPrimitive?.contentOrNull) {
                            "live" -> BoutStatus.LIVE
                            "final" -> BoutStatus.FINAL
                            "scheduled" -> BoutStatus.SCHEDULED
                            else -> current.status
                        },
                    )
                }
            }
        }
    }
}
