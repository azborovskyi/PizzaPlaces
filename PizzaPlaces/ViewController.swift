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
import CoreData

class ViewController: UIViewController, CLLocationManagerDelegate {

    ///
    enum VenueKeys: String {
        case Key_Name = "name"
        case Key_FormattedAddress = "formattedAddress"
        case Key_ID = "id"
        case Key_FormattedPhone = "formattedPhone"
        case Key_CategoryName = "categoryName"
    }
    
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

    
    ///
    func parseJSONResultFromData(data: NSData) -> [Dictionary<VenueKeys,String>] {
        let json = JSON(data: data)
        var resultsArr = [Dictionary<VenueKeys,String>]()
        if let venues = json["response"]["venues"].array {
            for venue in venues {
                var venueDict = Dictionary<VenueKeys,String>()
                if let id = venue["id"].string {
                    venueDict[VenueKeys.Key_ID] = id
                }
                
                if let name = venue["name"].string {
                    venueDict[VenueKeys.Key_Name] = name
                }
                
                if let formattedPhone = venue["contact"]["formattedPhone"].string {
                    venueDict[VenueKeys.Key_FormattedPhone] = formattedPhone
                }
                
                if let addressLines = venue["formattedAddress"].array {
                    venueDict[VenueKeys.Key_FormattedAddress] = addressLines.description
                }
                
                resultsArr.append(venueDict)
            }
        }
        
        return resultsArr
    }
    
    
    func searchRequestForNearbyRestaurants(coordinate: CLLocationCoordinate2D) -> SignalProducer<(NSData, NSURLResponse), NSError>? {
        let urlStr = "https://api.foursquare.com/v2/venues/search?client_id=GV5GJYI55EMOUIKFAYLMYCWQJH1MU5T0CL3SPLX52NJ0MYPF&client_secret=R4IN2MF5MQA2EQV2IAYS5O50EWX5P1421ISWUT3NSFB2I25Y&v=20130815&ll=\(coordinate.latitude),\(coordinate.longitude)&query=restaurants"
        if let url = NSURL(string: urlStr) {
            let request = NSURLRequest(URL: url)
            return NSURLSession.sharedSession().rac_dataWithRequest(request)
        }
        return nil
    }
    
    func fetchRestaurants(coordinate: CLLocationCoordinate2D) {
        if let requestSignal = searchRequestForNearbyRestaurants(coordinate) {
            requestSignal.start(next: {
                [unowned self] data, URLResponse in
                
                let venues = self.parseJSONResultFromData(data)
                let appDelegate = UIApplication.sharedApplication().delegate! as! AppDelegate
                let tmpContext = NSManagedObjectContext()
                tmpContext.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
                
                for dictVenue in venues {
                    if let theVenue = NSEntityDescription.insertNewObjectForEntityForName(
                        "Restaurant", inManagedObjectContext: tmpContext) as? Restaurant {
                            theVenue.name = dictVenue[VenueKeys.Key_Name] ?? ""
                            theVenue.id = dictVenue[VenueKeys.Key_ID] ?? ""
                            theVenue.formattedPhone = dictVenue[VenueKeys.Key_FormattedPhone] ?? ""
                            theVenue.formattedAddress = dictVenue[VenueKeys.Key_FormattedAddress] ?? ""
                    }
                }

                var error: NSError?
                if !tmpContext.save(&error) {
                    println("Error while storing to CoreData \(error)")
                }
            })
        }
    }

}
