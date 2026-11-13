package com.example.matside

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.matside.bout.BoutScreen
import com.example.matside.event.EventScreen
import com.example.matside.live.LiveEventManager

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                var session by remember { mutableIntStateOf(0) }

                // Equivalent to relaunching: the feed restarts at 0:00 and every screen is rebuilt.
                key(session) {
                    val navController = rememberNavController()
                    NavHost(navController = navController, startDestination = "event") {
                        composable("event") {
                            EventScreen(
                                onBoutSelected = { navController.navigate("bout/${it.id}") },
                                onRestart = {
                                    LiveEventManager.restart()
                                    session++
                                },
                            )
                        }
                        composable("bout/{boutId}") { entry ->
                            BoutScreen(
                                boutId = entry.arguments?.getString("boutId").orEmpty(),
                                onBack = { navController.popBackStack() },
                            )
                        }
                    }
                }
            }
        }
    }
}
