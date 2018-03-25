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

class ViewController: UIViewController {
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var locationSensingButton: UIButton!
    @IBOutlet weak var locationSensingLabel: UILabel!
    
    private let locationManager = GalleryLocationManager(locationManager: CLLocationManager())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Constants.backend.host = "https://hackathon.philamuseum.org";
        
        // Make sure to set the API key here, otherwise the app will scream!
        Constants.backend.apiKey = "YOUR_API_KEY";
        
        do {
            self.logTextView.text.append("Retrieving location assets from backend...\n")
            try BackendService.shared.retrieveGeolocationData(completion: {
                DispatchQueue.main.async {
                    self.logTextView.text.append("Successfully loaded location assets from backend.\n")
                    self.locationSensingButton.isEnabled = true
                }
            })
        } catch let error {
            self.logTextView.text.append("Error loading location assets from backend: \(error)\n")
        }
        
    }
    
    @IBAction func toggleLocationSensing(_ sender: Any) {
        self.startLocationSensing()
        self.locationSensingLabel.text = "Location Sensing active"
    }
    
    func startLocationSensing() {
        
        // setting ourselfs up as delegate for location updates
        locationManager.delegate = self
        
        // we need to ask the user for when in use permissions
        locationManager.requestPermissions()
        
        do {
            try locationManager.startLocationRanging(with: Constants.locationSensing.method.apple)
            self.logTextView.text.append("Starting Location Sensing...\n")
            self.locationSensingButton.isEnabled = false
        } catch let error {
            self.logTextView.text.append("Error starting Location Sensing: \(error)\n")
        }
        
        // this is a sample test call to match a given location with the geojson file
        // note that we need to set ignoreFloors to true since we cannot define a floor in CLLocation (yeah, really...)
        //        let location = CLLocation(latitude: 39.965186632142064, longitude: -75.1815766902897)
        //        let matchedLocation = LocationStore.sharedInstance.locationForCLLocation(location: location, ignoreFloors: true)
        //        print("Location: \(String(describing: matchedLocation?.name))") // this will return gallery 119
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : GalleryLocationManagerDelegate {
    func locationManager(locationManager: GalleryLocationManager, didEnterKnownLocation location: Location) {
        // do your magic here
        DispatchQueue.main.async {
            self.logTextView.text.append("Entered Location: \(location.name) \n")
        }
    }
    
    @nonobjc func locationManager(locationManager: GalleryLocationManager, didUpdateHeading newHeading: CLHeading) {
    }
}
