//
//  ViewController.swift
//  Geofence
//
//  Created by Christian Torres on 2/27/16.
//  Copyright © 2016 Christian Torres. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

let kSavedItemsKey = "savedItems"

class GeotificationsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    private var geotifications = [Geotification]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadAllGeotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navController =  segue.destinationViewController as? UINavigationController,
        addGeotificationTableViewController = navController.viewControllers.first as? AddGeotificationTableViewController {
            addGeotificationTableViewController.delegate = self
        }
    }
    
    @IBAction func unwindToGeonotifications(segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Actions
    
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
        zoomToUserLocationInMapView(mapView)
    }
    
    // MARK: - Helpers
    
    func loadAllGeotifications() {
        geotifications = []
        
        if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
            for savedItem in savedItems {
                if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
                    addGeotification(geotification)
                }
            }
        }
    }
    
    func addRadiusOverlayForGeotification(geotification: Geotification) {
        mapView?.addOverlay(MKCircle(centerCoordinate: geotification.coordinate, radius: geotification.radius))
    }
    
    func removeRadiusOverlayForGeotification(geotification: Geotification) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        if let overlays = mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
                        mapView?.removeOverlay(circleOverlay)
                        break
                    }
                }
            }
        }
    }
    
    func updateGeotificationsCount() {
        title = "Geotifications (\(geotifications.count))"
        navigationItem.rightBarButtonItem?.enabled = (geotifications.count < 20)  // Add this line
    }
    
    func saveAllGeotifications() {
        let items = NSMutableArray()
        for geotification in geotifications {
            let item = NSKeyedArchiver.archivedDataWithRootObject(geotification)
            items.addObject(item)
        }
        NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func addGeotification(geotification: Geotification) {
        geotifications.append(geotification)
        mapView.addAnnotation(geotification)
        addRadiusOverlayForGeotification(geotification)
        updateGeotificationsCount()
    }
    
    func removeGeotification(geotification: Geotification) {
        if let indexInArray = geotifications.indexOf(geotification) {
            geotifications.removeAtIndex(indexInArray)
        }
        
        mapView.removeAnnotation(geotification)
        removeRadiusOverlayForGeotification(geotification)
        updateGeotificationsCount()
    }
    
    /// Registering Your Geofences
    func regionWithGeotification(geotification: Geotification) -> CLCircularRegion {
        // 1
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        // 2
        region.notifyOnEntry = (geotification.eventType == .OnEntry)
        region.notifyOnExit = !region.notifyOnEntry
        
        return region
    }
    
    ///  Note: Core Location restricts the number of registered geofences to a maximum of 20 per app.
    func startMonitoringGeotification(geotification: Geotification) {
        // 1
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
        }
        // 3
        let region = regionWithGeotification(geotification)
        // 4
        CLLocationManager.sharedInstance.startMonitoringForRegion(region)
    }
    
    func stopMonitoringGeotification(geotification: Geotification) {
        for region in CLLocationManager.sharedInstance.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == geotification.identifier {
                    CLLocationManager.sharedInstance.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
}

// MARK: - AddGeotificationDelegate

extension GeotificationsViewController: AddGeotificationDelegate {
    
    func addGeotification(controller: AddGeotificationTableViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        
        // 1
        let clampedRadius = (radius > CLLocationManager.sharedInstance.maximumRegionMonitoringDistance) ?
            CLLocationManager.sharedInstance.maximumRegionMonitoringDistance : radius
        
        // Add geotification
        let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        addGeotification(geotification)
        
        startMonitoringGeotification(geotification)
        
        saveAllGeotifications()
    }
    
}

// MARK: - MKMapViewDelegate

extension GeotificationsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeotification"
        
        if annotation is Geotification {
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .Custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteGeotification")!, forState: .Normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purpleColor()
            circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
            return circleRenderer
        }
        
        return MKPolylineRenderer()
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        if let geotification = view.annotation as? Geotification {
            stopMonitoringGeotification(geotification)   // Add this statement
            removeGeotification(geotification)
            saveAllGeotifications()
        }
    }
    
}

// MARK: - CLLocationManagerDelegate

extension GeotificationsViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .AuthorizedAlways)
    }
    
    // Reacting to Geofence Events
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region?.identifier)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
    }
    
}
