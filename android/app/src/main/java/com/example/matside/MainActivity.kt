package com.example.matside

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.matside.bout.BoutScreen
import com.example.matside.event.EventScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                val navController = rememberNavController()
                NavHost(navController = navController, startDestination = "event") {
                    composable("event") {
                        EventScreen(onBoutSelected = { navController.navigate("bout/${it.id}") })
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
