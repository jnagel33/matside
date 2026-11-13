package com.example.matside.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class BoutStatus {
    @SerialName("scheduled") SCHEDULED,
    @SerialName("live") LIVE,
    @SerialName("final") FINAL,
}

@Serializable
data class LiveEvent(
    val id: String,
    val name: String,
    val status: BoutStatus,
)

@Serializable
data class Bout(
    val id: String,
    val mat: Int,
    val red: String,
    val blue: String,
    val redScore: Int,
    val blueScore: Int,
    val period: Int,
    val status: BoutStatus,
    val streamId: String? = null,
    val seq: Int? = null,
)

/** A change to one bout pushed by the live feed. Fields that didn't change are omitted. */
@Serializable
data class LiveUpdate(
    val seq: Int,
    val boutId: String,
    val redScore: Int? = null,
    val blueScore: Int? = null,
    val period: Int? = null,
    val status: BoutStatus? = null,
    val streamId: String? = null,
)

fun Bout.apply(update: LiveUpdate): Bout = copy(
    redScore = update.redScore ?: redScore,
    blueScore = update.blueScore ?: blueScore,
    period = update.period ?: period,
    status = update.status ?: status,
    streamId = update.streamId,
    seq = update.seq,
)
