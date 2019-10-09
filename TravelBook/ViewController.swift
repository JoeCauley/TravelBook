//
//  ViewController.swift
//  TravelBook
//
//  Created by Joseph Cauley on 10/5/19.
//  Copyright © 2019 Joseph Cauley. All rights reserved.
//
//Imported libraries
import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    //UI Outlets
    @IBOutlet var placeName: UITextField!
    @IBOutlet var placeNotes: UITextField!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var saveButton: UIButton!
    
    //Variables to store working LAT and LONG
    var chosenLat = Double()
    var chosenLong = Double()
    
    //Working cariables to contain record from table view to be sent to Map View
    var selectedTitle = ""
    var selectedId: UUID?
    
    //Working variables to contain data from Places object for current user requested record.
    var pinTitle = ""
    var pinNote = ""
    var pinLat = Double()
    var pinLong = Double()
    
    //Instance of Location Manager NSobject
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.isEnabled = false
        
        if selectedTitle != "" {
            
            //CoreData Fetch
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "name") as? String {
                            pinTitle = title
                                if let note = result.value(forKey: "note") as? String {
                                pinNote = note
                                    if let lat = result.value(forKey: "lat") as? Double {
                                    pinLat = lat
                                        if let long = result.value(forKey: "long") as? Double {
                                        pinLong = long
                                            
                                            let annotation = MKPointAnnotation()
                                            
                                            annotation.title = pinTitle
                                            annotation.subtitle = pinNote
                                            
                                            let coordinates = CLLocationCoordinate2D(latitude: pinLat, longitude: pinLong)
                                            
                                            annotation.coordinate = coordinates
                                            
                                            mapView.addAnnotation(annotation)
                                            
                                            placeName.text = annotation.title
                                            placeNotes.text = annotation.subtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            let region = MKCoordinateRegion(center: coordinates, span: span)
                                            mapView.setRegion(region, animated: true)
                        
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                print("Error loading data") //Not a real solution.
                }
            }
 
        //Configure LocationManager object properites
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //gesture recognizers
        //Two second long press to add pin to the map
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinToMap(gestureRecogniser:)))
       
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //Tap anywhere in the view controller to hide the keyboard
        let hideKBgestureRecinizer = UITapGestureRecognizer(target: self, action: #selector(hideKB))
        view.addGestureRecognizer(hideKBgestureRecinizer)
    }
    
    //Hides keyboard when the user taps outside the text field.
    @objc func hideKB() {
        
        view.endEditing(true)
        textCheck()
    }
    
    //Only enables save button if the Title field is populated
    func textCheck() {
        
        if placeName.text != "" {
            saveButton.isEnabled = true
    
        }
    }
    
    //Creates a pin on the map, and attaches the title and note to it.
    @objc func pinToMap (gestureRecogniser: UILongPressGestureRecognizer) {
        
        if gestureRecogniser.state == .began {
            //Where to place pin on Map
            let touchedPoint = gestureRecogniser.location(in: self.mapView)
            let touchCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //set these variables to current lat and long
            chosenLat = touchCoordinates.latitude
            chosenLong = touchCoordinates.longitude
            
            //Attach title and note to pin.
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = placeName.text
            annotation.subtitle = placeNotes.text
            self.mapView.addAnnotation(annotation)
            
        }
    }
//Assign lat and long of current location to a created location constant.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
     //Set area and default zoom of map
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
    }
    
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
           
           if annotation is MKUserLocation {
               return nil
           }
           
           let reuseId = "myAnnotation"
           var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
           
           if pinView == nil {
               pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
               pinView?.canShowCallout = true
               pinView?.tintColor = UIColor.black
               
               let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
               pinView?.rightCalloutAccessoryView = button
               
           } else {
               pinView?.annotation = annotation
           }
           
           
           
           return pinView
       }
       
       
       func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
           if selectedTitle != "" {
               
               let requestLocation = CLLocation(latitude: pinLat, longitude: pinLong)
               
               
               CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                   //closure
                   
                   if let placemark = placemarks {
                       if placemark.count > 0 {
                                         
                           let newPlacemark = MKPlacemark(placemark: placemark[0])
                           let item = MKMapItem(placemark: newPlacemark)
                           item.name = self.pinTitle
                           let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                           item.openInMaps(launchOptions: launchOptions)
                                         
                   }
               }
           }
               
               
           }
       
       
       
       
       }
       
//Save current title, notes and location to Places Entity in CoreData.
    @IBAction func saveButton(_ sender: Any) {
     //Create an instance of the AppDelegate and context.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
     //Create a new record in the Places Entity.
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(placeName.text, forKey: "name")
        newPlace.setValue(placeNotes.text, forKey: "note")
        newPlace.setValue(chosenLat, forKey: "lat")
        newPlace.setValue(chosenLong, forKey: "long")
        newPlace.setValue(UUID(), forKey: "id")
        
     //Save new record
        do {
            try context.save()
        } catch {
            print("Save Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
}

