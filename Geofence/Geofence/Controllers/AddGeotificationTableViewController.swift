//
//  AddGeonotificationTableViewController.swift
//  Geofence
//
//  Created by Christian Torres on 2/27/16.
//  Copyright © 2016 Christian Torres. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

protocol AddGeotificationDelegate {
    func addGeotification(controller: AddGeotificationTableViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
        radius: Double, identifier: String, note: String, eventType: EventType)
}

class AddGeotificationTableViewController: UITableViewController {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    @IBOutlet weak var eventTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var delegate: AddGeotificationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Deshabilitando boton de agregar
        addButton.enabled = false
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        CLLocationManager.sharedInstance.requestWhenInUseAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        addButton.enabled = !(radiusTextField.text!.isEmpty || noteTextField.text!.isEmpty)
    }
    
    @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
        zoomToUserLocationInMapView(mapView)
    }
    
    @IBAction private func onAdd(sender: AnyObject) {
        let coordinate = mapView.centerCoordinate
        let radius = Double(radiusTextField.text!)!
        let identifier = NSUUID().UUIDString
        let note = noteTextField.text!
        let eventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? EventType.OnEntry : EventType.OnExit
        delegate?.addGeotification(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
    }

}
