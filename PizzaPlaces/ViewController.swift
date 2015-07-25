//
//  ViewController.swift
//  PizzaPlaces
//
//  Created by Andrew Zborovskyi on 7/25/15.
//  Copyright (c) 2015 AZborovskyi. All rights reserved.
//

import UIKit
import CoreLocation

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
        fetchRestaurants(newLocation)
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

    
    func fetchRestaurants(location: CLLocation) {
        
//        https://www.google.me/search?q=reactivecocoa&rlz=1C5CHFA_enUA505UA505&oq=reac&aqs=chrome.0.69i59j69i60j69i57j69i60j69i65j69i60.1199j0j4&sourceid=chrome&es_sm=91&ie=UTF-8
        
    }
    
}

