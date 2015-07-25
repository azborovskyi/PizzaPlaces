//
//  PPDetailsViewController.swift
//  PizzaPlaces
//
//  Created by Andrew Zborovskyi on 7/25/15.
//  Copyright (c) 2015 AZborovskyi. All rights reserved.
//

import UIKit

class PPDetailsViewController: UIViewController {

    @IBOutlet var labelPhone: UILabel?
    @IBOutlet var labelAddress: UILabel?
    
    var venueToDisplay: Restaurant?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = venueToDisplay?.name
        
        self.labelPhone?.text = venueToDisplay?.formattedPhone
        self.labelAddress?.text = venueToDisplay?.formattedAddress
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
