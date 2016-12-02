//
//  WorldWishListVC.swift
//  HelloWorld
//
//  Created by Candance Smith on 8/31/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit
import Mapbox
import CoreData

class WorldWishListVC: UIViewController, MGLMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets and Variables
    
    @IBOutlet weak var mapView: MGLMapView?
    @IBOutlet weak var tableView: UITableView?
    
    fileprivate var pointAnnotations = [MGLPointAnnotation]()
    fileprivate var sortedContinents: [Continent]?
    fileprivate var wishListCountries = [[Country]]()
    fileprivate var oldWishListCountries = [[Country]]()
    fileprivate var wishListCities = [City]()
    
    // MARK: - Set Up View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parent?.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.title = "Travel Wish List"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        mapView?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        mapView?.removeAnnotations(pointAnnotations)
        pointAnnotations.removeAll()
        
        wishListCities.removeAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView?.setCenter(CLLocationCoordinate2D(latitude: 33.88, longitude: 9.53), zoomLevel: 0.0, animated: false)
        
        wishListCountries.removeAll()
        sortedContinents?.removeAll()
        
        (sortedContinents, wishListCountries) = fetchCountriesAndContinentsBasedOnCondition("wish == %@")
        extractCitiesOnWishList()
        
        pointAnnotations = annotateOnMap(wishListCities)
        mapView?.addAnnotations(pointAnnotations)
        
        tableView?.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        mapView?.setCenter(CLLocationCoordinate2D(latitude: 33.88, longitude: 9.53), zoomLevel: 0.0, animated: false)
    }
    
    // MARK: - MGLMapViewDelegate methods
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "heart")
        
        if annotationImage == nil {
            if var image = UIImage(named: "heart") {
                image = image.withAlignmentRectInsets(UIEdgeInsetsMake(0, 0, image.size.height/2, 0))
                annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "heart")
            }
        }
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedContinents?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        let countriesList = wishListCountries[numberOfRowsInSection]
        
        return countriesList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // so "Optional" is not shown in title
        var continentName = String()
        
        if let sortedContinentName = sortedContinents?[section].name {
            continentName = sortedContinentName
        }
        return ("\(continentName) (\(wishListCountries[section].count))")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Country Cell") else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        let countriesList = wishListCountries[(indexPath as NSIndexPath).section]
        let country = countriesList[(indexPath as NSIndexPath).row]
        if let code = country.code {
            cell.imageView?.image = UIImage(named: code)
        }
        cell.textLabel?.text = country.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Display Wish List Cities", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var countriesList = wishListCountries[(indexPath as NSIndexPath).section]
            let country = countriesList[(indexPath as NSIndexPath).row]
            country.wish = false
            countriesList.remove(at: (indexPath as NSIndexPath).row)
            wishListCountries.remove(at: (indexPath as NSIndexPath).section)
            wishListCountries.insert(countriesList, at: (indexPath as NSIndexPath).section)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveManagedObject()
            
            tableView.reloadData()
            reloadMapViewAnnotations()
        }
    }
    
    // MARK: - Settings
    
    @IBAction func settingsButtonTouched(_ sender: AnyObject) {
        performSegue(withIdentifier: "Display Settings", sender: sender)
    }
    
    // MARK: - Segue
    
    @IBAction func addButtonTouched(_ sender: AnyObject) {
        performSegue(withIdentifier: "Add Countries To Wish List", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Display Wish List Cities" {
            if let destinationVC = segue.destination as? CountryWishListVC,
                let indexPath = sender as? IndexPath {
                let countryList = wishListCountries[(indexPath as NSIndexPath).section]
                destinationVC.country = countryList[(indexPath as NSIndexPath).row]
            }
            
        } else if segue.identifier == "Add Countries To Wish List" {
            if let destinationVC = segue.destination as? UINavigationController,
                let addCountriesToWishListVC = destinationVC.topViewController as? AddCountriesToWishList {
                
                oldWishListCountries = wishListCountries
                setUpSegueVCToEditWishList(addCountriesToWishListVC, cancelAction: #selector(WorldWishListVC.handleCancel), saveAction: #selector(WorldWishListVC.handleDone))
            }
        }
    }
    
    func handleCancel() {
        wishListCountries.removeAll()
        sortedContinents?.removeAll()
        (sortedContinents, wishListCountries) = fetchCountriesAndContinentsBasedOnCondition("wish == %@")
        
        var newWishListCountries = [Country]()
        var originalWishListCountries = [Country]()
        
        newWishListCountries = convertToArrayFrom(wishListCountries)
        originalWishListCountries = convertToArrayFrom(oldWishListCountries)
        
        undoWishListChanges(newWishListCountries, original: originalWishListCountries)
        
        saveManagedObject()
        dismiss(animated: true, completion: nil)
    }
    
    func handleDone() {
        (sortedContinents, wishListCountries) = fetchCountriesAndContinentsBasedOnCondition("wish == %@")
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper Functions
    
    fileprivate func convertToArrayFrom(_ countries: [[Country]]) -> [Country] {
        var countryArray = [Country]()
        
        if countries.count > 0 {
            for i in 0...countries.count - 1 {
                let countriesList = countries[i]
                for country in countriesList {
                    countryArray.append(country)
                }
            }
        }
        return countryArray
    }
    
    fileprivate func undoWishListChanges(_ current: [Country], original: [Country]) {
        if current != original {
            let matchedCountries = current.filter(original.contains)
            let mergedCountries = current + original
            var mergedCountriesSet = Set(mergedCountries)
            
            for country in mergedCountriesSet {
                if matchedCountries.contains(country) {
                    mergedCountriesSet.remove(country)
                }
            }
            let unmatchedCountries = mergedCountriesSet
            for country in unmatchedCountries {
                country.wish = !country.wish
            }
        }
    }
    
    fileprivate func extractCitiesOnWishList() {
        var wishListCitiesInCountry = [City]()
        
        if wishListCountries.count > 0 {
            for i in 0...wishListCountries.count - 1 {
                let countriesInContinent = wishListCountries[i]
                for country in countriesInContinent {
                    wishListCitiesInCountry = getWishListCities(country)
                    wishListCities.append(contentsOf: wishListCitiesInCountry)
                }
            }
        }
    }
    
    fileprivate func reloadMapViewAnnotations() {
        mapView?.removeAnnotations(pointAnnotations)
        pointAnnotations.removeAll()
        wishListCities.removeAll()
        extractCitiesOnWishList()
        pointAnnotations = annotateOnMap(wishListCities)
        mapView?.addAnnotations(pointAnnotations)
    }
}
