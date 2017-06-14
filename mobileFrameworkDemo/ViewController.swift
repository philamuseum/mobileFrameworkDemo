//
//  ViewController.swift
//  mobileFrameworkDemo
//
//  Created by Peter.Alt on 5/9/17.
//  Copyright © 2017 Philadelphia Museum of Art. All rights reserved.
//

import UIKit
import mobileFramework
import CoreLocation

class ViewController: UIViewController, GalleryLocationManagerDelegate {
    
    var locationManager = GalleryLocationManager(locationManager: CLLocationManager())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setting ourselfs up as delegate
        locationManager.delegate = self
        
        // we need to ask the user for when in use permissions
        locationManager.requestPermissions()
        
        // define the UUID you want to monitor along with a unique identifier
        let sampleRegion = CLBeaconRegion(proximityUUID: Constants.beacons.defaultUUID!, identifier: "mobileFrameworkDemo")
        locationManager.beaconRegion = sampleRegion
        
        // loading our locations
        do {
            try FeatureStore.sharedInstance.load(filename: "sampleLocations", type: .location, completion: {
                if let asset = FeatureStore.sharedInstance.getAsset(for: .location) as? LocationAsset {
                    LocationStore.sharedInstance.load(fromAsset: asset)
                }
            })
        } catch {
            print("Error loading locations")
        }
        
        // loading our beacons
        do {
            try FeatureStore.sharedInstance.load(filename: "sampleBeacons", type: .beacon, completion: {
                if let asset = FeatureStore.sharedInstance.getAsset(for: .beacon) as? BeaconAsset {
                    BeaconStore.sharedInstance.load(fromAsset: asset)
                }
            })
        } catch {
            print("Error loading beacons")
        }
        
        // just some debug output
        print("Number of beacons loaded: \(BeaconStore.sharedInstance.beacons.count)")
        print("Number of locations loaded: \(LocationStore.sharedInstance.locations.count)")
        
        // let's start ranging locations
        do {
            try locationManager.startLocationRanging()
            print("Started ranging locations")
        } catch {
            print("Error staring location ranging")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationManager(locationManager: GalleryLocationManager, didEnterLocation location: Location) {
        // do your magic here
        print("Entered location: \(location.name)")
    }


}

