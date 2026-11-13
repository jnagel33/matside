# Mat Side

A small sample app that shows a live wrestling event: a list of mats with live scores, and a bout screen with video and a scoreboard. The same app is implemented natively for iOS and Android.

Everything runs offline. The "live" data comes from a fake server inside the app that replays a bundled script (`feed.json`) on a 60-second loop, and the video is a bundled test clip. All names and events are fictional.

## Running it

### iOS

- Xcode 16 or later, iOS 17+ simulator
- Open `ios/MatSide.xcodeproj` and run the `MatSide` scheme

### Android

- Android Studio Ladybug or later, JDK 17
- Open the `android/` folder and run the `app` configuration on an API 26+ emulator or device

## Layout

```
ios/
  MatSide/
    App/        app entry point
    Model/      bout, event, and live update models
    Live/       fake live server and the shared live connection
    Event/      event screen (list of mats)
    Bout/       bout screen (video + scoreboard)
    Resources/  feed.json, bout.mp4
  MatSideTests/
android/
  app/src/main/java/com/example/matside/
    model/  live/  event/  bout/
  app/src/main/assets/   feed.json, bout.mp4
```

## How the live feed works

`FakeLiveServer` plays the frames in `feed.json` at their `at` offsets (seconds into the loop), timed from app launch, so every connection sees the same timeline. Each frame is delivered as a raw JSON string, the way a WebSocket message would arrive:

```json
{ "type": "update", "update": { "seq": 12, "boutId": "b4", "redScore": 2, "blueScore": 0 } }
```

At the start of each loop the server sends a `snapshot` frame with the full list of bouts.
