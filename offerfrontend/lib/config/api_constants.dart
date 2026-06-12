

class ApiConstants {
  static String get baseUrl {
    // We have set up an ADB reverse tunnel (adb reverse tcp:8080 tcp:8080).
    // This allows Emulators, Physical Devices, and Web to all seamlessly 
    // connect to the local Spring Boot backend using localhost:8080.
    return "http://localhost:8080";
  }
}