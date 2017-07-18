//
//  MissingCitySearchTVC.swift
//  HelloWorld
//
//  Created by Candance Smith on 11/5/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit
import MapKit

class MissingCitySearchTVC: UITableViewController {
    
    // MARK: - Outlets and Variables

    var matchingItems = [MKMapItem]()
    var mapView: MKMapView?
    
    var addMissingCityVCDelegate: AddMissingCityVCDelegate?
    
    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "City Cell") else {
            return UITableViewCell()
        }
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.locality
        cell.detailTextLabel?.text = parseAddress(selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        addMissingCityVCDelegate?.dropPinZoomIn(selectedItem)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper Functions
    
    func parseAddress(_ selectedItem: MKPlacemark) -> String {
        // put comma between state and country in subtitle
        let comma = (selectedItem.administrativeArea != nil && selectedItem.country != nil) ? ", " : ""
        let addressLine = String(
            format:"%@%@%@",
            // state or province
            selectedItem.administrativeArea ?? "",
            comma,
            selectedItem.country ?? ""
        )
        return addressLine
    }
}

// MARK: - Search Extension

extension MissingCitySearchTVC : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else {
                return
        }

        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            let allItems = response.mapItems
            self.matchingItems = self.removeNonCityItems(allItems)
            self.tableView.reloadData()
        }
    }
    
    private func removeNonCityItems(_ allItems: [MKMapItem]) -> [MKMapItem] {
        var cityItems = [MKMapItem]()
        for item in allItems {
            if item.placemark.subThoroughfare == nil && item.placemark.thoroughfare == nil && item.placemark.subLocality == nil && item.placemark.locality != nil {
                cityItems.append(item)
            }
        }
        return cityItems
    }
}
