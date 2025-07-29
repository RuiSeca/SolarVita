import Flutter
import UIKit
// import GoogleMaps  // Commented out - using lightweight fitness tracker instead

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps initialization commented out - using lightweight fitness tracker
    // let apiKey = getGoogleMapsApiKey()
    // GMSServices.provideAPIKey(apiKey)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getGoogleMapsApiKey() -> String {
    // Try to get from dart-define first
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String, !apiKey.isEmpty {
      return apiKey
    }
    
    // Fallback to environment variable
    if let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"], !apiKey.isEmpty {
      return apiKey
    }
    
    // Fallback to default key (for development only)
    return "AIzaSyCuIiBhdkW5DOxHZa7D05HfZ8SO8Hunjrk"
  }
}
