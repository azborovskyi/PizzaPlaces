//
//  ViewController.swift
//  PizzaPlaces
//
//  Created by Andrew Zborovskyi on 7/25/15.
//  Copyright (c) 2015 AZborovskyi. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveCocoa
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        let code = CLLocationManager.authorizationStatus()
        
        if (code == CLAuthorizationStatus.NotDetermined) {
            self.locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {}
    

    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        fetchRestaurants(newLocation.coordinate)
        // One update is enough for now
        self.locationManager?.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.AuthorizedWhenInUse
            || status == CLAuthorizationStatus.AuthorizedAlways) {
            self.locationManager?.startUpdatingLocation()
        } else {
            UIAlertView(title: "Please enable location access in order to use the app.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    func fetchRestaurants(coordinate: CLLocationCoordinate2D) {
        if let requestSignal = searchRequestForNearbyRestaurants(coordinate) {
            requestSignal.start(next: {
                [unowned self] data, URLResponse in
                    return self.parseJSONResultFromData(data)
                })
//                |> observeOn(UIScheduler())
            
        }
        
        
//        let urlRequest =
//        let searchResults = searchStrings
//            |> flatMap(.Latest) { query in
//                let URLRequest = self.searchRequestWithEscapedQuery(query)
//                return NSURLSession.sharedSession().rac_dataWithRequest(URLRequest)
//            }
//            |> map { data, URLResponse in
//                let string = String(data: data, encoding: NSUTF8StringEncoding)!
//                return parseJSONResultsFromString(string)
//            }
//            |> observeOn(UIScheduler())
//        https://www.google.me/search?q=reactivecocoa&rlz=1C5CHFA_enUA505UA505&oq=reac&aqs=chrome.0.69i59j69i60j69i57j69i60j69i65j69i60.1199j0j4&sourceid=chrome&es_sm=91&ie=UTF-8
        
    }
    
    func searchRequestForNearbyRestaurants(coordinate: CLLocationCoordinate2D) -> SignalProducer<(NSData, NSURLResponse), NSError>? {
        let urlStr = "https://api.foursquare.com/v2/venues/search?client_id=GV5GJYI55EMOUIKFAYLMYCWQJH1MU5T0CL3SPLX52NJ0MYPF&client_secret=R4IN2MF5MQA2EQV2IAYS5O50EWX5P1421ISWUT3NSFB2I25Y&v=20130815&ll=\(coordinate.latitude),\(coordinate.longitude)&query=restaurants"
        if let url = NSURL(string: urlStr) {
            let request = NSURLRequest(URL: url)
            return NSURLSession.sharedSession().rac_dataWithRequest(request)
        }
        return nil
    }
    
    
    func parseJSONResultFromData(data: NSData) -> [Dictionary<String,String>]? {
        let json = JSON(data: data)
        let resultsArr = [Dictionary<String,String>]()
        if let venues = json["response"]["venues"].array {
            for venue in venues {
                var venueDict = Dictionary<String,String>()
                if let name = venue["name"].string {
                    venueDict["name"] = name
                }
            }
        }
        
        return resultsArr
    }
}

