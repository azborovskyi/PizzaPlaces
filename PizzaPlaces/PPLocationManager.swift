//
//  PPLocationManager.swift
//  PizzaPlaces
//
//  Created by Andrew Zborovskyi on 7/25/15.
//  Copyright (c) 2015 AZborovskyi. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveCocoa

class PPLocationManager: NSObject, CLLocationManagerDelegate {
    
    /// Location Manager
    var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
    }
    
    /// Blocks for signals
    var authorizationChangeBlock:((CLAuthorizationStatus)->())?
    var locationUpdateBlock:((CLLocation)->())?
    
    // ==========
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {}
    
    // ==========
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!,
        fromLocation oldLocation: CLLocation!) {
            if nil != self.locationUpdateBlock {
                self.locationUpdateBlock!(newLocation)
            }
    }
    
    // ==========
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if nil != self.authorizationChangeBlock {
            self.authorizationChangeBlock!(status)
        }
    }
    
    // ==========
    // MARK: - Signals
    // ==========
    
    /// Location Manager Authorization
    func authorizationSignalProducer() -> SignalProducer<CLAuthorizationStatus, NoError> {
        return SignalProducer {
            [weak self]
            sink, disposable in
            self?.authorizationChangeBlock = {
                [sink] status in
                sendNext(sink, status)
                if (status == CLAuthorizationStatus.AuthorizedWhenInUse
                    || status == CLAuthorizationStatus.AuthorizedAlways) {
                        sendCompleted(sink)
                }
            }   
            self?.locationManager?.requestWhenInUseAuthorization()
            let code = CLLocationManager.authorizationStatus()
            sendNext(sink, code)
            if (code == CLAuthorizationStatus.AuthorizedWhenInUse
                || code == CLAuthorizationStatus.AuthorizedAlways) {
                    sendCompleted(sink)
            }
        }
    }
    
    /// Location Updates
    func locationUpdateSignalProducer() -> SignalProducer<CLLocation, NoError> {
        return SignalProducer {
            sink, disposable in
            self.locationUpdateBlock = {
                [sink] location in
                sendNext(sink, location)
            }
            self.locationManager?.startUpdatingLocation()
        }
    }
    
}
