# SDL MobileWeather Example App

This example app uses the OpenWeather API to present a basic connected weather app with SDL UI.

## Configuration

### Install Dependencies
Use [Cocoapods](https://cocoapods.org/) to install the dependencies:

1. Install Cocoapods if necessary.
2. Navigate to the root directory in terminal.
3. Run `pod install`.

### Weather API Key
1. Sign up and get your own [OpenWeather API Key](https://home.openweathermap.org/api_keys).
1. Set the API key into `APIKey.swift` to use.

### SDL
You will need to customize the configuration of the app depending on whether you are connecting it to a module over IAP (USB or Bluetooth) or TCP (Manticore or an emulator).

To check what type of connection is currently set up, go to `WeatherSDLManager.swift` and go to the `func start()` method. There you will see a call to `SDLLifecycleConfiguration(appName: , fullAppId: )` and one to `SDLLifecycleConfiguration(appName: , fullAppId: , ipAddress: , port: )` where one is active and the other is commented out. For more information on these calls, see [the network connection type guide](https://smartdevicelink.com/en/guides/iOS/getting-started/integration-basics/#network-connection-type) depending on if you are connecting over IAP or TCP you may need to configure and alter these calls.

## Connecting
Once you've configured the app with your own OpenWeather API key and based on the device you are connecting to, you only have to run the app on your device (IAP or TCP) or a Simulator (TCP-only) and connect!
