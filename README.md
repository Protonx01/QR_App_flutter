# QR app

Flutter app with functionalities to scan and create QR codes

## Important Files

- Download and install **[QR-app.apk](QR-app.apk)** from the project folder. It is the release version of the app
- **[main.dart](/lib/main.dart)** contains the entire code for the app
- Also check **[AndroidManifest.xml](/android/app/src/main/AndroidManifest.xml)**, **[pubspec.yaml](pubspec.yaml)**, and  **[build.gradle](/android/app/build.gradle)**  for further metadata, dependencies and build information

### version 1.0

- **Basic working + design**
  - Scan QR code with camera
  - Copying the retrieved text
  - Creating QR code
  - Creating app specific directory
  - Sharing created QR
  - Saving in storage with proper naming

## Future Plans
- Reduce APK size
- Adding settings button to change theme and further options with storage
- Optimizing the code, and spliting them in different files for ease of maintainance
