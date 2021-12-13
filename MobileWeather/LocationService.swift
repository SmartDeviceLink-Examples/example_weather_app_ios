//
//  LocationService.swift
//  WeatherLocationService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import CoreLocation
import Foundation

protocol LocationServiceDelegate: AnyObject {
    func locationDidUpdate(newLocation: WeatherLocation)
}

class LocationService: NSObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocationUpdate = Date(timeIntervalSince1970: 0)
    private let minimumLocationUpdateSeconds = 120.0
    private weak var delegate: LocationServiceDelegate?

    public init(delegate: LocationServiceDelegate) {
        self.delegate = delegate

        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.desiredAccuracy = 500.0
        locationManager.distanceFilter = 500.0
        locationManager.requestWhenInUseAuthorization()

        super.init()
        locationManager.delegate = self
    }

    @objc public func start() {
        locationManager.startMonitoringSignificantLocationChanges()
    }

    @objc public func stop() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse: fallthrough
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined: break
        case .denied: fallthrough
        case .restricted: fallthrough
        default:
            // TODO: Something to display that location isn't allowed
            break;
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let now = Date()
        guard locations.count > 0,
              now.timeIntervalSince(lastLocationUpdate) > minimumLocationUpdateSeconds else { return }

        lastLocationUpdate = now
        geocoder.reverseGeocodeLocation(locations.last!) { placemarks, error in
            guard let place = placemarks?.last, let gpsLocation = place.location else {
                print("Error reverse geocoding location: \(locations.last!), error: \(error!)")
                return
            }

            let weatherLocation = WeatherLocation(country: place.country, state: place.administrativeArea, city: place.locality, zipCode: place.postalCode, gpsLocation: gpsLocation)
            self.delegate?.locationDidUpdate(newLocation: weatherLocation)
        }
    }
}
