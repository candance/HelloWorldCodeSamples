//
//  JournalHomeVC.swift
//  HelloWorld
//
//  Created by Candance Smith on 9/2/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit
import CoreData

class JournalHomeVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Outlets and Variables
   
    @IBOutlet var settingsBarButtonItem: UIBarButtonItem?
    
    @IBOutlet weak var journalSortSegmentedControl: UISegmentedControl?
    @IBOutlet weak var tableView: UITableView?
    
    @IBOutlet var tableViewToTopLayoutConstraint: NSLayoutConstraint?
    @IBOutlet var tableViewToSegementedControlTopLayoutConstraint: NSLayoutConstraint?

    var journalCity: City?
    fileprivate var journalEntries: [Journal]?
    fileprivate var sortedDatesWithMonthYear = [String]()
    fileprivate var journalEntriesSortedByMonthYear = [[Journal]]()
    
    let searchController = UISearchController(searchResultsController: nil)
    fileprivate var filteredJournalEntries = [[Journal]]()
    fileprivate var shouldShowSearchResults = false

    // MARK: - Set Up View

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        setUpRightBarButtonItems()
        
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.estimatedRowHeight = 200
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetNavigationBarToDefaultState()
        checkSegmentedControl()
        
        tableView?.reloadData()
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return journalEntriesSortedByMonthYear.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        var journalEntriesPerMonthYear = [Journal]()
        
        if shouldShowSearchResults && searchController.searchBar.text != "" {
            journalEntriesPerMonthYear = filteredJournalEntries[numberOfRowsInSection]
        } else {
            journalEntriesPerMonthYear = journalEntriesSortedByMonthYear[numberOfRowsInSection]
        }
        return journalEntriesPerMonthYear.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedDatesWithMonthYear[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Plain Journal Cell") as? JournalHomePlainTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        let entries: [Journal]
        if shouldShowSearchResults && searchController.searchBar.text != "" {
            entries = filteredJournalEntries[(indexPath as NSIndexPath).section]
        } else {
            entries = journalEntriesSortedByMonthYear[(indexPath as NSIndexPath).section]
        }
        let entry = entries[(indexPath as NSIndexPath).row]

        displayCellContent(entry, cell: cell)
        displayImages(entry, cell: cell)
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Display Journal Entry", sender: indexPath)
    }
    
    // MARK: - Settings

    @IBAction func settingsButtonTouched(_ sender: AnyObject) {
        performSegue(withIdentifier: "Display Settings", sender: sender)
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Display Journal Entry" {
            let destinationVC = segue.destination as? JournalEntryVC
            if let indexPath = sender as? IndexPath {
                let journalEntries = journalEntriesSortedByMonthYear[(indexPath as NSIndexPath).section]
                destinationVC?.journalEntry = journalEntries[(indexPath as NSIndexPath).row]
            }
        }
    }

    // unwind segue from JournalEntryVC after user deletes entry
    @IBAction func unwindFromJournalEntryVC(_ segue: UIStoryboardSegue) {
    }
    
    // MARK: - Right Bar Button Items
    
    fileprivate func setUpRightBarButtonItems() {
        let addButtonItem = setUpCustomBarButton("add_button", selector: #selector(JournalHomeVC.addButtonTouched))
        let searchButton = setUpCustomBarButton("remove_button", selector: #selector(JournalHomeVC.searchButtonTouched))
        
        self.navigationItem.rightBarButtonItems = [addButtonItem,searchButton]
    }
    
    func addButtonTouched(_ sender: AnyObject) {
        performSegue(withIdentifier: "Add New Entry", sender: sender)
    }
    
    func searchButtonTouched() {
        setUpSearchBar()
        showSearchBarAsNavigationBar()
        hidebarButtonItems()
        hideSegmentedControl()
    }
    
    fileprivate func setUpCustomBarButton(_ imageName: String, selector: Selector) -> UIBarButtonItem {
        let button = UIButton()
        button.setImage(UIImage(named: imageName), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: selector, for: .touchUpInside)
        let buttonItem = UIBarButtonItem()
        buttonItem.customView = button
        
        return buttonItem
    }
    
    fileprivate func hidebarButtonItems() {
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    fileprivate func unhideBarButtonItems() {
        setUpRightBarButtonItems()
        navigationItem.leftBarButtonItem = settingsBarButtonItem
        navigationItem.setHidesBackButton(false, animated: false)
    }
    
    fileprivate func resetNavigationBarToDefaultState() {
        unhideBarButtonItems()
        unhideSegmentedControl()
        navigationItem.titleView = nil
    }
    
    // MARK: - Search
    
    // MARK: UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        shouldShowSearchResults = true
        tableView?.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        shouldShowSearchResults = false
        resetNavigationBarToDefaultState()
        tableView?.reloadData()
    }
    
    fileprivate func filterJournalsForSearchText(_ searchText: String) {
        filteredJournalEntries.removeAll()
        if journalEntriesSortedByMonthYear.count > 0 {
            for i in 0...journalEntriesSortedByMonthYear.count - 1 {
                let filteredJournalEntriesByMonthYear = journalEntriesSortedByMonthYear[i].filter { entry in
                    
                    let (monthAndYear, dayOfTheWeek, dateNumber) = convertAllDateElementsToString(entry)
                    let (city, country) = unwrapJournalOptionals(entry)
                    
                    return dayOfTheWeek.lowercased().contains(searchText.lowercased()) ||
                        dateNumber.contains(searchText) ||
                        monthAndYear.lowercased().contains(searchText.lowercased()) ||
                        city.lowercased().contains(searchText.lowercased()) ||
                        country.lowercased().contains(searchText.lowercased()) ||
                        entry.notes?.lowercased().contains(searchText.lowercased()) ?? false
                }
                filteredJournalEntries.append(filteredJournalEntriesByMonthYear)
            }
            tableView?.reloadData()
        }
    }
    
    fileprivate func setUpSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.placeholder = "Search your travel memories..."
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = UIColor.purple
    }
    
    fileprivate func showSearchBarAsNavigationBar() {
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.becomeFirstResponder()
    }
    
    // MARK: - Segmented Control
    
    fileprivate func checkSegmentedControl() {
        if journalSortSegmentedControl?.selectedSegmentIndex == 0 {
            fetchAndSortJournalEntries(true)
        } else if journalSortSegmentedControl?.selectedSegmentIndex == 1 {
            fetchAndSortJournalEntries(false)
        }
    }
    
    @IBAction func changeJournalSort(_ sender: AnyObject) {
        checkSegmentedControl()
        tableView?.reloadData()
        if journalEntriesSortedByMonthYear.count > 0 {
            tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    fileprivate func hideSegmentedControl() {
        journalSortSegmentedControl?.isHidden = true
        tableViewToTopLayoutConstraint?.isActive = true
        tableViewToTopLayoutConstraint?.constant = 0
        tableViewToSegementedControlTopLayoutConstraint?.isActive = false
    }
    
    fileprivate func unhideSegmentedControl() {
        journalSortSegmentedControl?.isHidden = false
        tableViewToTopLayoutConstraint?.isActive = false
        tableViewToSegementedControlTopLayoutConstraint?.isActive = true
        tableViewToSegementedControlTopLayoutConstraint?.constant = 10.0
    }
    
    // MARK: - Helper Functions
  
    fileprivate func fetchAndSortJournalEntries(_ newest: Bool) {
        // clear all existing arrays
        sortedDatesWithMonthYear.removeAll()
        journalEntriesSortedByMonthYear.removeAll()
        
        if let journalCity = journalCity {
            let journalForCitySet = journalCity.cityJournal
            let journalForCity = journalForCitySet?.allObjects as? [Journal]
            sortJournalEntries(journalForCity, newest: newest)
        } else {
            
            if let fetchedJournalEntries = fetchWithSortDescriptor("Journal", sortDescriptorKey: "date", ascending: false) as? [Journal], fetchedJournalEntries.count > 0 {
                journalEntries = fetchedJournalEntries
                sortJournalEntries(journalEntries, newest: newest)
            }
        }
    }
    
    fileprivate func sortJournalEntries(_ journal: [Journal]?, newest: Bool) {
        if let journal = journal, journal.count > 0 {
        
            let datesSet = extractMonthAndYearFromJournalEntries(journal)
            let datesAsDate = turnDatesSetIntoDateArray(datesSet)
            let sortedDatesByMonthAndYear = sortDatesByMonthAndYear(datesAsDate, newest: newest)
            
            for date in sortedDatesByMonthAndYear {
                let monthAndYear = DateFormatter.stringFromDate(DateFormatter.dateFormatterMonthYear, date: date)
                sortedDatesWithMonthYear.append(monthAndYear)
            }
            
            createJournalBasedOnMonthAndYear(journal, newest: newest)
            //                        print(journalEntriesSortedByMonthYear)
        }
    }
    
    fileprivate func unwrapJournalOptionals(_ journal: Journal) -> (String, String) {
        var cityName = String()
        var countryName = String()
        
        if let city = journal.journalCity,
            let country = journal.journalCountry?.name {
            cityName = setUpCityName(city, requiresState: checkIfCityRequiresState(city))
            countryName = country
        }
        return (cityName, countryName)
    }
    
    fileprivate func convertAllDateElementsToString(_ journal: Journal) -> (String, String, String) {
        var monthAndYear = String()
        var dayOfTheWeek = String()
        var dateNumber = String()
        
        if let date = journal.date {
            monthAndYear = DateFormatter.stringFromDate(DateFormatter.dateFormatterMonthYear, date: date)
            dayOfTheWeek = DateFormatter.stringFromDate(DateFormatter.dateFormatterDayOfTheWeek, date: date)
            dateNumber = DateFormatter.stringFromDate(DateFormatter.dateFormatterDate, date: date)
        }
        return (monthAndYear, dayOfTheWeek, dateNumber)
    }
    
    fileprivate func displayCellContent(_ journal: Journal, cell: JournalHomePlainTableViewCell) {
        if let city = journal.journalCity,
            let country = journal.journalCountry,
            let date = journal.date {
            cell.setUpCellDate(date)
            cell.setUpCellCountry(country)
            cell.cityLabel?.text = setUpCityName(city, requiresState: checkIfCityRequiresState(city))
        }
        cell.setUpTextView(journal)
    }
    
    fileprivate func displayImages(_ journal: Journal, cell: JournalHomePlainTableViewCell) {
        if let imagesSet = journal.journalImage {
            if imagesSet.count > 0 {
                cell.setUpCellImages(imagesSet, imagesExist: true)
            } else {
                cell.setUpCellImages(imagesSet, imagesExist: false)
            }
        }
    }
    
    fileprivate func extractMonthAndYearFromJournalEntries(_ journalEntries: [Journal]) -> Set<String> {
        var datesSet = Set<String>()
        for entry in journalEntries {
            if let date = entry.date {
                let monthAndYear = DateFormatter.stringFromDate(DateFormatter.dateFormatterMonthYear, date: date)
                datesSet.insert(monthAndYear)
            }
        }
        return datesSet
    }
    
    fileprivate func turnDatesSetIntoDateArray(_ datesSet: Set<String>) -> [Date] {
        var dateArray = [Date]()
        let dates = Array(datesSet)
        for date in dates {
            if let dateAsDate = DateFormatter.dateFromString(DateFormatter.dateFormatterMonthYear, string: date) {
                dateArray.append(dateAsDate)
            }
        }
        return dateArray
    }
    
    fileprivate func sortDatesByMonthAndYear(_ dates: [Date], newest: Bool) -> [Date] {
        var sortedDates = [Date]()
        if newest == true {
            sortedDates = dates.sorted {$0 > $1}
        } else if newest == false {
            sortedDates = dates.sorted {$0 < $1}
        }
        return sortedDates
    }
    
    fileprivate func createJournalBasedOnMonthAndYear(_ journalEntries: [Journal], newest: Bool) {
        for i in 0...sortedDatesWithMonthYear.count - 1 {
            var journalEntriesWithSameMonthYear = [Journal]()
            for entry in journalEntries {
                if let date = entry.date {
                    let monthAndYear = DateFormatter.stringFromDate(DateFormatter.dateFormatterMonthYear, date: date)
                    if monthAndYear == sortedDatesWithMonthYear[i] {
                        journalEntriesWithSameMonthYear.append(entry)
                    }
                }
            }
            journalEntriesWithSameMonthYear = sortJournalInEachMonthYearByDate(journalEntriesWithSameMonthYear, newest: newest)
            journalEntriesSortedByMonthYear.append(journalEntriesWithSameMonthYear)
        }
    }
    
    fileprivate func sortJournalInEachMonthYearByDate(_ journalEntries: [Journal], newest: Bool) -> [Journal] {
        var journalEntriesInEachMonthYear = [Journal]()
        if newest == true {
            journalEntriesInEachMonthYear = journalEntries.sorted {$0.date! > $1.date!}
        } else if newest == false {
            journalEntriesInEachMonthYear = journalEntries.sorted {$0.date! < $1.date!}
        }
        return journalEntriesInEachMonthYear
    }
}

// MARK: - Search Extension

extension JournalHomeVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        filterJournalsForSearchText(text)
    }
}
