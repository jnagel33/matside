package com.example.matside

import com.example.matside.live.FakeLiveServer
import com.example.matside.live.FeedScript
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FeedScriptTest {
    @Test
    fun bundledScriptDecodes() {
        val text = File("src/main/assets/feed.json").readText()
        val script = FakeLiveServer.json.decodeFromString(FeedScript.serializer(), text)

        assertEquals(4, script.bouts.size)
        assertTrue(script.frames.isNotEmpty())
    }
}
