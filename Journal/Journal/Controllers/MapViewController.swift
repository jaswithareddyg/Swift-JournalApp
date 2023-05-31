//
//  MapViewController.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/8/23.
//

import Foundation
import UIKit
import MapKit

class MapViewController: UIViewController {

    var mapView: MKMapView!
    var journalEntries: [(entry: Journal, latitude: Double, longitude: Double)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)
        
        updateMapWithJournalEntries()
    }
    
    func updateMapWithJournalEntries() {
        mapView.removeAnnotations(mapView.annotations)
        
        let visibleMapRect = mapView.visibleMapRect
        
        let visibleRegionEntries = LocalStorageManager.sharedInstance.journals.filter { entry in
            if let latitude = entry.latitude, let longitude = entry.longitude {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let mapPoint = MKMapPoint(coordinate)
                return visibleMapRect.contains(mapPoint)
            }
            return false
        }
        
        for entry in visibleRegionEntries {
            if let latitude = entry.latitude, let longitude = entry.longitude {
                let annotation = JournalAnnotation(entry: entry, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                mapView.addAnnotation(annotation)
                
                journalEntries.append((entry, latitude, longitude))
            }
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? JournalAnnotation else { return nil }
        
        let identifier = "JournalAnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.image = UIImage(named: "pinImage") // Set the image for the annotation view
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Customize the size of the annotation view
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

class JournalAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var entry: Journal
    
    init(entry: Journal, coordinate: CLLocationCoordinate2D) {
        self.entry = entry
        self.coordinate = coordinate
        self.title = entry.note
        
        super.init()
    }
}
