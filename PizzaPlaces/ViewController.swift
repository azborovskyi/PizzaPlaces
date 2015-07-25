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

let kNotificationModelUpdated = "ModelUpdated"

class ViewController: UITableViewController, CLLocationManagerDelegate {

    ///
    enum VenueKeys: String {
        case Key_Name = "name"
        case Key_FormattedAddress = "formattedAddress"
        case Key_ID = "id"
        case Key_FormattedPhone = "formattedPhone"
        case Key_CategoryName = "categoryName"
    }
    
    let kCellIdentifier = "RestaurantCell"
    
    var locationManager: CLLocationManager?
    
    var fetchResultsController: NSFetchedResultsController?
    
    // ==========
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        let code = CLLocationManager.authorizationStatus()
        
        if (code == CLAuthorizationStatus.NotDetermined) {
            self.locationManager?.requestWhenInUseAuthorization()
        }

        let cellXib = UINib(nibName: "RestaurantCell", bundle: nil)
        self.tableView.registerNib(cellXib, forCellReuseIdentifier: kCellIdentifier);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "modelUpdated:", name: kNotificationModelUpdated, object: nil)
        
        fetchRestaurantsLocally()
    }
    
    // ==========
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // ==========
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {}
    
    // ==========
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        fetchRestaurants(newLocation.coordinate)
        // One update is enough for now
        self.locationManager?.stopUpdatingLocation()
    }
    
    // ==========
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.AuthorizedWhenInUse
            || status == CLAuthorizationStatus.AuthorizedAlways) {
            self.locationManager?.startUpdatingLocation()
        } else {
            UIAlertView(title: "Please enable location access in order to use the app.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }

    // ==========
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // ==========
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
                
                if let addressLines = venue["location"]["formattedAddress"].array {
                    venueDict[VenueKeys.Key_FormattedAddress] = addressLines.reduce("") { (sum, json) in
                        sum! + "\n" + json.string! }
                }
                
                resultsArr.append(venueDict)
            }
        }
        
        return resultsArr
    }
    
    // ==========
    func searchRequestForNearbyRestaurants(coordinate: CLLocationCoordinate2D) -> SignalProducer<(NSData, NSURLResponse), NSError>? {
        let urlStr = "https://api.foursquare.com/v2/venues/search?client_id=GV5GJYI55EMOUIKFAYLMYCWQJH1MU5T0CL3SPLX52NJ0MYPF&client_secret=R4IN2MF5MQA2EQV2IAYS5O50EWX5P1421ISWUT3NSFB2I25Y&v=20130815&ll=\(coordinate.latitude),\(coordinate.longitude)&query=restaurants"
        if let url = NSURL(string: urlStr) {
            let request = NSURLRequest(URL: url)
            return NSURLSession.sharedSession().rac_dataWithRequest(request)
        }
        return nil
    }
    
    // ==========
    func fetchRestaurants(coordinate: CLLocationCoordinate2D) {
        if let requestSignal = searchRequestForNearbyRestaurants(coordinate) {
            requestSignal.start(next: {
                [unowned self] data, URLResponse in
                
                let venues = self.parseJSONResultFromData(data)
                let appDelegate = UIApplication.sharedApplication().delegate! as! AppDelegate
                let tmpContext = NSManagedObjectContext()
                tmpContext.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
                
                for dictVenue in venues {
                    self.insertRestaurantIfUniqueId(dictVenue, moc: tmpContext)
                }

                var error: NSError?
                if !tmpContext.save(&error) {
                    println("Error while storing to CoreData \(error)")
                }
                
                // Notify that data was updated
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationModelUpdated, object: nil)
                })
            })
        }
    }

    func insertRestaurantIfUniqueId(dictVenue: Dictionary<VenueKeys,String>, moc: NSManagedObjectContext) {
        let request = NSFetchRequest()
        
        let id = dictVenue[VenueKeys.Key_ID] ?? ""
        if id.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < 1 {
            return
        }
        
        request.entity = NSEntityDescription.entityForName("Restaurant", inManagedObjectContext: moc)
        request.predicate = NSPredicate(format: "id = %@", id)

        var executeFetchError: NSError?
        var theVenue: Restaurant?
        // Check if id already exists
        theVenue = moc.executeFetchRequest(request, error: &executeFetchError)?.last as? Restaurant
        // If doesn't exist - create new
        if nil == theVenue {
            theVenue = NSEntityDescription.insertNewObjectForEntityForName(
                "Restaurant", inManagedObjectContext: moc) as? Restaurant
        }
        
        theVenue!.name = dictVenue[VenueKeys.Key_Name] ?? ""
        theVenue!.id = dictVenue[VenueKeys.Key_ID] ?? ""
        theVenue!.formattedPhone = dictVenue[VenueKeys.Key_FormattedPhone] ?? ""
        theVenue!.formattedAddress = dictVenue[VenueKeys.Key_FormattedAddress] ?? ""
    }
    
    // ==========
    func modelUpdated(notification: NSNotification) {
        fetchRestaurantsLocally()
        self.tableView.reloadData()
    }
    
    // ==========
    func fetchRestaurantsLocally() {
        if let moc = (UIApplication.sharedApplication().delegate! as! AppDelegate).managedObjectContext {
            var fetchRequest: NSFetchRequest = NSFetchRequest()
            var entityDescription: NSEntityDescription = NSEntityDescription.entityForName("Restaurant", inManagedObjectContext:moc)!
            fetchRequest.entity = entityDescription
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key:"name", ascending: true, selector: "localizedCaseInsensitiveCompare:")]
            
            var error: NSError?
            self.fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            self.fetchResultsController!.performFetch(&error)
        }
    }
    
    // ==========
    // MARK: - TableView
    // ==========
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchController = self.fetchResultsController {
            return fetchController.sections![section].numberOfObjects
        }
        return 0
    }
    
    // ==========
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let fetchController = self.fetchResultsController {
            return 1
        } else {
            return 0
        }
    }
    
    // ==========
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as! RestaurantCell
        
        if let venue = self.fetchResultsController?.objectAtIndexPath(indexPath) as? Restaurant {
            cell.configureWithRestaurant(venue)
        }
        
        return cell
    }
    
    // ==========
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let venue = self.fetchResultsController?.objectAtIndexPath(indexPath) as? Restaurant {
            self.performSegueWithIdentifier("details", sender: venue)
        }
    }
    
    // MARK: - Navigation
    
    // ==========================================================================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "details") {
            let detailsVC = segue.destinationViewController as? PPDetailsViewController
            detailsVC?.venueToDisplay = sender as? Restaurant
        }
    }
    
    
}
