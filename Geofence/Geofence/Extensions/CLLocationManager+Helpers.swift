//
//  CLLocationManager+Helpers.swift
//  Geofence
//
//  Created by Christian Torres on 2/27/16.
//  Copyright © 2016 Christian Torres. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationManager {
    
    class var sharedInstance: CLLocationManager {
        struct Static {
            static let instance = CLLocationManager()
        }
        return Static.instance
    }
    
}