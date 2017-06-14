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
        
        // let's download some data
        
        let sampleData = "rodinSampleData"
        
        let bundle = Bundle(for: type(of: self))
        guard let fileURL = bundle.url(forResource: sampleData, withExtension: "json")
            else {
                print("Error loading file \(sampleData)")
                return
        }
        
        do {
            let localData = try Data(contentsOf: fileURL)
            let JSON = try JSONSerialization.jsonObject(with: localData, options: []) as! [String: AnyObject]
            let filesToDownload = getFilesToDownloadFromDataFile(jsonObject: JSON)
            
            print("Files to download: \(filesToDownload.count)")
            
            let queue = QueueController.sharedInstance
            
            queue.reset()
            
            for file in filesToDownload {
                queue.addItem(url: file)
            }
            
            queue.startDownloading()
            
        } catch {
            print("Error parsing \(sampleData)")
        }
        
    }
    
    func getFilesToDownloadFromDataFile(jsonObject: [String: AnyObject]) -> [URL] {
        
        var urls = [URL]()
        
        let objects = jsonObject["objects"] as! [[String: Any]]
        
        for objectArray in objects {
            let object = objectArray["object"] as! [String: Any]
            
            let thumbnailArray = object["thumbnail"] as! [String : Any]
            let thumbnail = thumbnailArray["src"] as! String
            
            urls.append(URL(string: thumbnail)!)
            
//            let headerArray = object["images_header"] as! [[String : Any]]
//            for headerItem in headerArray {
//                let header = headerItem["src"] as! String
//                urls.append(URL(string: header)!)
//            }
//            
//            
//            let fullImageArray = object["full"] as! [[String : Any]]
//            for fullImageItem in fullImageArray {
//                let fullImage = fullImageItem["src"] as! String
//                urls.append(URL(string: fullImage)!)
//            }
            
        }

        return urls
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

extension ViewController : QueueControllerDelegate {
    
    func QueueControllerDidFinishDownloading(queueController: QueueController) {
        print("FINISHED DOWNLOADING")
    }
}

