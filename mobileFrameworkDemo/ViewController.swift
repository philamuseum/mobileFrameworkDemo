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
    
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var publishDataButton: UIButton!
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var imageView: UIImageView!
    
    private let locationManager = GalleryLocationManager(locationManager: CLLocationManager())
    private let downloadQueue = QueueController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // this is a demo and we want to start fresh every time, probably not a good idea in production
        self.downloadQueue.reset()
        
        // register our custom URL protocol to allow request interception on an app level
        URLProtocol.registerClass(mobileFrameworkURLProtocol.self)
        
        print("Cache Folder: \(CacheService.sharedInstance.cacheURL)")

    }
    
    func getFilesToDownloadFromDataFile(jsonObject: [String: AnyObject]) -> [URL] {
        
        var urls = [URL]()
        
        let objects = jsonObject["objects"] as! [[String: Any]]
        
        for objectArray in objects {
            let object = objectArray["object"] as! [String: Any]
            
            let thumbnailArray = object["thumbnail"] as! [String : Any]
            let thumbnail = thumbnailArray["src"] as! String
            
            urls.append(URL(string: thumbnail)!)
            
            let headerArray = object["images_header"] as! [[String : Any]]
            for headerItem in headerArray {
                let header = headerItem["src"] as! String
                urls.append(URL(string: header)!)
            }
            
            let fullImageArray = object["full"] as! [[String : Any]]
            for fullImageItem in fullImageArray {
                let fullImage = fullImageItem["src"] as! String
                urls.append(URL(string: fullImage)!)
            }
        }
        return urls
    }
    
    @IBAction func startLocationSensing(_ sender: Any) {
        
        // setting ourselfs up as delegate for location updates
        locationManager.delegate = self
        
        // we need to ask the user for when in use permissions
        // (this should be done when you actually need it in your application and probably not in viewDidLoad)
        locationManager.requestPermissions()
        
        // define the UUID you want to monitor along with a unique identifier
        let sampleRegion = CLBeaconRegion(proximityUUID: Constants.beacons.defaultUUID!, identifier: "mobileFrameworkDemo")
        locationManager.beaconRegion = sampleRegion
        
        // loading our location assets that are stored locally
        do {
            try FeatureStore.sharedInstance.load(filename: "sampleLocations", type: .location, completion: {
                if let asset = FeatureStore.sharedInstance.getAsset(for: .location) as? LocationAsset {
                    LocationStore.sharedInstance.load(fromAsset: asset)
                }
            })
        } catch {
            print("Error loading locations")
        }
        
        // loading our beacon assets
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
    
    @IBAction func startDownloadingContent(_ sender: Any) {
        
        // let's download some data (just an example, you would probably want to download asset data here)
        
        self.publishDataButton?.isEnabled = false
        
        // let's make this controller our delegate so we can track progress
        self.downloadQueue.delegate = self
        
        // let's start off fresh by deleting everything in staging
        CacheService.sharedInstance.purgeEnvironment(environment: Constants.cache.environment.staging, completion: { _ in })
        
        let sampleData = "rodinSampleData"
        
        let bundle = Bundle(for: type(of: self))
        guard let sampleDataPathURL = bundle.url(forResource: sampleData, withExtension: "json")
            else {
                print("Error loading file \(sampleData)")
                return
        }
        
        do {
            let localData = try Data(contentsOf: sampleDataPathURL)
            let JSON = try JSONSerialization.jsonObject(with: localData, options: []) as! [String: AnyObject]
            
            // we process the JSON file and get an array of files to download back
            let filesToDownload = getFilesToDownloadFromDataFile(jsonObject: JSON)
            print("Files to download: \(filesToDownload.count)")
            
            for file in filesToDownload {
                self.downloadQueue.addItem(url: file)
            }
            self.downloadQueue.startDownloading()
            
        } catch {
            print("Error parsing \(sampleData)")
        }

    }
    
    @IBAction func publishData(_ sender: Any) {
        CacheService.sharedInstance.publishStagingEnvironment(completion: { success in
            print("Publishing content successful: \(success)")
        })
    }
    
    
    @IBAction func loadCachedPage(_ sender: Any) {
        let url = URL(string: "http://org.philamuseum.mobileframeworktests.s3.amazonaws.com/header.jpg")
        let request = CacheService.sharedInstance.makeRequest(url: url!)
        self.webView.loadRequest(request)
        
    
        CacheService.sharedInstance.requestData(url: url!, forceUncached: false, completion: { localPath, data in
            if data != nil {
                let image = UIImage(data: data!)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        })
    }
    
    @IBAction func deleteCachedData(_ sender: Any) {
        CacheService.sharedInstance.purgeEnvironment(environment: Constants.cache.environment.live, completion: { _ in })
        CacheService.sharedInstance.purgeEnvironment(environment: Constants.cache.environment.staging, completion: { _ in })
        CacheService.sharedInstance.purgeEnvironment(environment: Constants.cache.environment.manual, completion: { _ in })
    }
    
    
    @IBAction func forceUncachedRequest(_ sender: Any) {
        let url = URL(string: "http://org.philamuseum.mobileframeworktests.s3.amazonaws.com/header.jpg")
        let request = CacheService.sharedInstance.makeRequest(url: url!, forceUncached: true)
        
        self.webView.loadRequest(request)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : GalleryLocationManagerDelegate {
    func locationManager(locationManager: GalleryLocationManager, didEnterKnownLocation location: Location) {
        // do your magic here
        print("Entered location: \(location.name)")
        DispatchQueue.main.async {
            self.currentLocationLabel.text = location.name
        }
    }
}

extension ViewController : QueueControllerDelegate {
    func QueueControllerDownloadInProgress(queueController: QueueController, withProgress progress: Float) {
        print("Download queue progress update: \(progress) %")
        DispatchQueue.main.async {
            self.downloadProgressView?.setProgress(progress, animated: false)
        }
        
    }

    
    func QueueControllerDidFinishDownloading(queueController: QueueController) {
        print("Download queue finished downloading.")
        DispatchQueue.main.async {
            self.publishDataButton?.isEnabled = true
        }
    }
}

