//
//  AddMissingCityVC.swift
//  HelloWorld
//
//  Created by Candance Smith on 10/26/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit
import CoreData
import MapKit

protocol AddMissingCityVCDelegate {
    func dropPinZoomIn(_ placemark: MKPlacemark)
}

class AddMissingCityVC: UIViewController, UISearchBarDelegate, MKMapViewDelegate {
    
    // MARK: - Outlets and Variables
    
    @IBOutlet var searchView: UIView?
    @IBOutlet weak var mapView: MKMapView?
    @IBOutlet weak var searchButton: UIButton!
    
    var searchController = UISearchController(searchResultsController: nil)
    
    var selectedPin: MKPlacemark?
    
    // MARK: - Set Up View

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = Style.sunglow
        
        mapView?.setRegion(MKCoordinateRegionForMapRect(MKMapRectWorld), animated: false)
        
        searchView?.layer.cornerRadius = 20.0
        StyleManager.setButtonImageWithCustomTint("search_globe", tintColor: UIColor.lightGray, button: searchButton, state: .highlighted)
    }
    
    // MARK: - Search
    
    @IBAction func searchButtonTouched(_ sender: Any) {
        setUpSearchResultsController()
        setUpSearchBar()
        searchView?.isHidden = true
        navigationItem.setHidesBackButton(true, animated:false)
    }
    
    // MARK: UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationItem.setHidesBackButton(false, animated:false)
        navigationItem.titleView = nil
        searchView?.isHidden = false
        if let annotations = mapView?.annotations {
            mapView?.removeAnnotations(annotations)
        }
        mapView?.setRegion(MKCoordinateRegionForMapRect(MKMapRectWorld), animated: false)
    }
    
    // MARK: - Map Annotation
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        pinView?.pinTintColor = Style.carnation
        pinView?.canShowCallout = true

        let button = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0))
        StyleManager.setButtonImageWithCustomTint("add_journal", tintColor: Style.turquoise, button: button, state: .normal)
        button.setImage(UIImage(named: "add_journal"), for: .highlighted)
        button.addTarget(self, action: #selector(AddMissingCityVC.addButtonTouched), for: .touchUpInside)
        pinView?.rightCalloutAccessoryView = button
        return pinView
    }
    
    // MARK: - Confirm or Deny Add
    
    func addButtonTouched() {
        if let selectedPin = selectedPin {
            print(selectedPin)
            if checkIfMissingCityAlreadyExists(selectedPin) == true {
                presentAlertController("Cannot Add City", message: "City already exists in database")
            } else if checkIfMissingCityAlreadyExists(selectedPin) == false {
                insertMissingCityIntoCoreData(selectedPin)
                saveManagedObject()
            }
        }
    }
    
    private func insertMissingCityIntoCoreData(_ placemark: MKPlacemark) {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext,
            let cityObject = NSEntityDescription.insertNewObject(forEntityName: "City", into: managedObjectContext) as? City {
            markMissingCityAsVisited(cityObject)
            cityObject.geonameID = 00000
            cityObject.name = placemark.locality
            cityObject.latitude = placemark.coordinate.latitude
            cityObject.longitude = placemark.coordinate.longitude
            cityObject.visited = false
            cityObject.wish = false
            cityObject.journalEntry = false
            
            saveCityCountry(placemark, cityObject: cityObject)
            
            if placemark.countryCode == "US" {
                saveCityState(placemark, cityObject: cityObject)
            }
        }
    }
    
    private func markMissingCityAsVisited(_ cityObject:City) {
        let alertController = UIAlertController(title: "Mark City As Visited?", message: nil, preferredStyle: .actionSheet)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {(alert:UIAlertAction?) in
            cityObject.visited = true
            cityObject.cityCountry?.visited = true
            self.saveManagedObject()
            self.presentAlertController("Success!", message: "City added to visited")
        })
        alertController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: .default, handler: {(alert:UIAlertAction?) in
            cityObject.visited = false
            self.saveManagedObject()
            self.presentAlertController("Success!", message: "City added to database")
        })
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveCityCountry(_ placemark: MKPlacemark, cityObject: City) {
        if let countryCode = placemark.countryCode,
            let countryObjectArray = fetchMatchingObject("Country", predicateRequest: "code == %@", predicateObject: countryCode) as? [Country] {
            for object in countryObjectArray {
                cityObject.cityCountry = object
            }
        }
    }
    
    private func saveCityState(_ placemark: MKPlacemark, cityObject: City) {
        if let state = placemark.administrativeArea,
        let stateObjectArray = fetchMatchingObject("State", predicateRequest: "name == %@", predicateObject: state) as? [State] {
            for object in stateObjectArray {
                cityObject.cityState = object
            }
        }
    }
    
    private func fetchMatchingObject(_ entity: String, predicateRequest: String, predicateObject: String) -> [NSManagedObject] {
        var results = [NSManagedObject]()
        
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
            let predicate = NSPredicate(format: predicateRequest, predicateObject)
            fetchRequest.predicate = predicate
            
            do {
                results = try managedObjectContext.fetch(fetchRequest)
            } catch {
                print("Failed to fetch")
                print(error)
            }
        }
        return results
    }

    private func checkIfMissingCityAlreadyExists(_ placemark: MKPlacemark) -> Bool {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext,
            let placemarkCity = placemark.locality,
            let placemarkCountryCode = placemark.countryCode {
            let fetchRequest = NSFetchRequest<City>(entityName: "City")
            
            var predicate = NSPredicate()
            
            if placemarkCountryCode == "US",
                let placemarkState = placemark.administrativeArea {
                predicate = NSPredicate(format: "name == %@ AND cityCountry.code == %@ AND cityState.name == %@", placemarkCity, placemarkCountryCode, placemarkState)
            } else {
                predicate = NSPredicate(format: "name == %@ AND cityCountry.code == %@", placemarkCity, placemarkCountryCode)
            }
            fetchRequest.predicate = predicate
            
            do {
                let cities = try managedObjectContext.fetch(fetchRequest)
                if cities.count > 0 {
                    return true
                }
            } catch {
                print("Failed to retrieve cities")
                print(error)
            }
        }
        return false
    }

    // MARK: - Helper Functions

    private func setUpSearchResultsController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let searchResultsController = storyboard.instantiateViewController(withIdentifier: "MissingCitySearchTVC") as? MissingCitySearchTVC
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        searchResultsController?.mapView = mapView
        searchResultsController?.addMissingCityVCDelegate = self
    }
    
    private func setUpSearchBar() {
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search City, Country e.g. 'Paris, France'"
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }
    
    private func presentAlertController(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - <AddMissingCityVCDelegate>

extension AddMissingCityVC: AddMissingCityVCDelegate {
    func dropPinZoomIn(_ placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        if let annotations = mapView?.annotations {
            mapView?.removeAnnotations(annotations)
        }
        let annotation = createAnnotation(placemark)
        mapView?.addAnnotation(annotation)
        mapView?.selectAnnotation(annotation, animated: true)
        
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView?.setRegion(region, animated: true)
    }
    
    private func createAnnotation(_ placemark: MKPlacemark) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.locality
        if let state = placemark.administrativeArea,
            let country = placemark.country {
            annotation.subtitle = "\(state), \(country)"
        }
        return annotation
    }
}
