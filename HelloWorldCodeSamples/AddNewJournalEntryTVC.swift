//
//  AddNewJournalEntryTVC.swift
//  HelloWorld
//
//  Created by Candance Smith on 9/6/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit
import CoreData

protocol AddNewJournalEntryTVCDelegate {
    func journalSaved(_ forCity: City)
}

class AddNewJournalEntryTVC: UITableViewController, ChooseCountryForJournalVCDelegate, ChooseCityForJournalVCDelegate, UIImagePickerControllerDelegate, JournalPhotoCollectionViewCellEditingDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    // MARK: - Outlets and Variables

    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var datePicker: UIDatePicker?
    fileprivate var journalDate: Date?
    
    @IBOutlet weak var countryLabel: UILabel?
    @IBOutlet weak var flagImageView: UIImageView?
    
    @IBOutlet weak var cityLabel: UILabel?
    
    @IBOutlet weak var textView: UITextView?
    
    var journal: Journal?
    var chosenCountry: Country?
    var chosenCity: City?
    
    fileprivate var collectionViewCellItem: Int?
    fileprivate var currentChosenImage: UIImage?
    fileprivate var cameraImage = UIImage(named: "camera")
    fileprivate var chosenImageArray = [UIImage]()
    
    var newJournalEntryDelegate: AddNewJournalEntryTVCDelegate?
    
    // MARK: - Set Up View

    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker?.isHidden = true
        
        setUpChosenImageArrayWithCameraImage()
        
        textView?.text = "Write something about the city!"
        textView?.textColor = UIColor.lightGray
        
        if let journal = journal {
            setUpJournalForEditing(journal)
        } else {
            setUpNewJournalWithTodaysDate()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let chosenCountry = chosenCountry {
            setUpCountryAndCityLabels(chosenCountry, city: chosenCity)
        } else {
            countryLabel?.text = ""
            cityLabel?.text = ""
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.selectionStyle = .none
        
        return cell
    }
    
    // Setting collection view delegate for photos row
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 4 {
            guard let photosCell = cell as? NewJournalEntryPhotosTableViewCell else {
                return
            }
            photosCell.setCollectionViewDataSourceDelegate(self)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Expanding cell for datePicker
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 1 {
            if let datePicker = datePicker {
                let height:CGFloat = datePicker.isHidden ? 0.00 : 162.0
                return height
            }
        }
        
        // textView row fills screen
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 5 {
            let height:CGFloat = UIScreen.main.bounds.height - 64 - 44 * 3 - 152
            return height
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 {
            displayOrHideDatePicker(indexPath)
            
        } else if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 2 {
            performSegue(withIdentifier: "Choose Country", sender: indexPath)
            
        } else if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 3 {
            
            if chosenCountry == nil {
                showAlert("Please choose a country first")
            } else {
                performSegue(withIdentifier: "Choose City", sender: indexPath)
            }
        }
    }
    
    // MARK: - Date
    
    @IBAction func dateChanged(_ sender: AnyObject) {
        if let datePicker = datePicker {
            dateLabel?.text = DateFormatter.stringFromDate(DateFormatter.dateFormatterFull, date: datePicker.date)
            journalDate = datePicker.date
        }
    }
    
    fileprivate func displayOrHideDatePicker(_ indexPath: IndexPath) {
        if let datePicker = datePicker {
            datePicker.isHidden = !datePicker.isHidden
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.tableView.beginUpdates()
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.tableView.endUpdates()
            })
        }
    }
    
    // MARK: - Text View Protocol
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write something about the city!"
            textView.textColor = UIColor.lightGray
        }
    }
    
    // MARK: - Journal Entry Save/Cancel
    
    @IBAction func cancelButtonTouched(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: save journal entry to core data
    @IBAction func saveButtonTouched(_ sender: AnyObject) {
        
        // only saves if at least country and city are filled out
        if chosenCity != nil && cityLabel?.text?.isEmpty == false {
            if let journal = journal {
                updateJournalEntry(journal)
            } else {
                createNewJournalObjectInCoreData()
            }
            saveManagedObject()
            
            if let chosenCity = chosenCity {
                newJournalEntryDelegate?.journalSaved(chosenCity)
            }
            dismiss(animated: true, completion: nil)
        } else {
            showAlert("Please choose a city")
        }
    }
    
    fileprivate func updateJournalEntry(_ journal: Journal) {
        journal.date = journalDate
        journal.journalCountry = chosenCountry
        if journal.journalCity != chosenCity {
            checkIfCityHasOtherJournalEntries(journal)
            journal.journalCity = chosenCity
            chosenCity?.journalEntry = true
        }
        if textView?.text != "Write something about the city!" {
            journal.notes = textView?.text
        } else {
            journal.notes = nil
        }
        deleteImagesFromCoreData(journal)
        convertAndInsertImagesIntoCoreData(journal)
    }
    
    fileprivate func createNewJournalObjectInCoreData() {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext,
            let journalObject = NSEntityDescription.insertNewObject(forEntityName: "Journal", into: managedObjectContext) as? Journal {
            journalObject.date = journalDate
            
            if textView?.text != "Write something about the city!" {
                journalObject.notes = textView?.text
            } else {
                journalObject.notes = nil
            }
            
            journalObject.journalCountry = chosenCountry
            journalObject.journalCity = chosenCity
            chosenCity?.journalEntry = true
            
            convertAndInsertImagesIntoCoreData(journalObject)
            journal = journalObject
        }
    }
    
    fileprivate func showAlert(_ cityOrCountry: String) {
        let alertController = UIAlertController(title: cityOrCountry, message: nil, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Choose Country" {
            let destinationVC = segue.destination as? UINavigationController
            let chooseCountryForJournalVC = destinationVC?.topViewController as? ChooseCountryForJournalVC
            
            chooseCountryForJournalVC?.chooseCountryDelegate = self
            
        } else if segue.identifier == "Choose City" {
            let destinationVC = segue.destination as? UINavigationController
            let chooseCityForJournalVC = destinationVC?.topViewController as? ChooseCityForJournalVC
            
            chooseCityForJournalVC?.country = chosenCountry
            chooseCityForJournalVC?.chooseCityDelegate = self
        }
    }
    
    // MARK: - Delegates
    
    // MARK: <ChooseCountryForJournalVCDelegate>
    
    func countryChosen(_ country: Country) {
        chosenCountry = country
    }
    
    // MARK: <ChooseCityForJournalVCDelegate>
    
    func cityChosen(_ city: City) {
        chosenCity = city
    }
    
    // MARK: <JournalPhotoCollectionViewCellEditingDelegate>
    
    func deleteButtonTouched(_ cell: JournalPhotoCollectionViewCell) {
        chosenImageArray.remove(at: cell.tag)
        
        if let cameraImage = cameraImage {
            chosenImageArray.insert(cameraImage, at: 4)
        }
        
        tableView?.reloadData()
    }
    
    // MARK: - Helper Functions
    
    fileprivate func setUpChosenImageArrayWithCameraImage() {
        if let cameraImage = cameraImage {
            for i in 0...4 {
                chosenImageArray.insert(cameraImage, at: i)
            }
        }
    }
    
    fileprivate func setUpJournalForEditing(_ journal: Journal) {
        displayExistingJournalDateAndLocation(journal)
        displayExistingJournalImages(journal)
        displayExistingJournalNotes(journal)
    }
    
    fileprivate func setUpNewJournalWithTodaysDate() {
        if let datePicker = datePicker {
            datePicker.date = Date()
            dateLabel?.text = DateFormatter.stringFromDate(DateFormatter.dateFormatterFull, date: datePicker.date)
            journalDate = datePicker.date
        }
    }
    
    fileprivate func displayExistingJournalDateAndLocation(_ journal: Journal) {
        if let date = journal.date,
            let country = journal.journalCountry {
            dateLabel?.text = DateFormatter.stringFromDate(DateFormatter.dateFormatterFull, date: date)
            journalDate = date
            
            setUpCountryAndCityLabels(country, city: journal.journalCity)
            chosenCountry = country
            chosenCity = journal.journalCity
        }
    }
    
    fileprivate func displayExistingJournalImages(_ journal: Journal) {
        if let imagesSet = journal.journalImage,
            imagesSet.count > 0,
            let imagesArray = imagesSet.allObjects as? [Image] {
            for i in 0...imagesArray.count - 1 {
                if let imageData = imagesArray[i].fullRes,
                    let image = UIImage(data: imageData, scale: 1.0) {
                    chosenImageArray[i] = image
                }
            }
            tableView?.reloadData()
        }
    }
    
    fileprivate func displayExistingJournalNotes(_ journal: Journal) {
        if let notes = journal.notes {
            textView?.text = notes
            textView?.textColor = UIColor.black
        }
    }
    
    fileprivate func setUpCountryAndCityLabels (_ country: Country, city: City?) {
        countryLabel?.text = country.name
        if let code = country.code {
            flagImageView?.image = UIImage(named: code)
        }
        if city != nil,
            let city = city {
            if city.cityCountry != country {
                cityLabel?.text = ""
            } else {
                cityLabel?.text = setUpCityName(city, requiresState: checkIfCityRequiresState(city))
            }
        }
    }
    
    fileprivate func checkNumberOfChosenImages(_ chosenImageArray: [UIImage]) -> Int {
        var numberOfImages = 0
        
        for image in chosenImageArray {
            if image != cameraImage {
                numberOfImages += 1
            }
        }
        return numberOfImages
    }
    
    fileprivate func deleteImagesFromCoreData(_ journal: Journal) {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext {
            
            let fetchRequest = NSFetchRequest<Image>(entityName: "Image")
            let predicate = NSPredicate(format: "imageJournal == %@", journal)
            fetchRequest.predicate = predicate
            
            do {
                let images = try managedObjectContext.fetch(fetchRequest)
                for image in images {
                    managedObjectContext.delete(image)
                }
            } catch {
                print("Failed to retrieve images")
                print(error)
            }
        }
    }
    
    fileprivate func convertAndInsertImagesIntoCoreData(_ journal: Journal) {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext {
            for image in chosenImageArray {
                if image != cameraImage {
                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        print("full res image conversion error")
                        return
                    }
                    let thumbnail = scaleImage(image)
                    guard let thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.7) else {
                        print("thumbnail image conversion error")
                        return
                    }
                    insertImagesIntoCoreData(managedObjectContext, imageData: imageData, thumbnailData: thumbnailData, journalObject: journal)
                }
            }
        }
    }
    
    fileprivate func insertImagesIntoCoreData(_ managedObjectContext: NSManagedObjectContext, imageData: Data, thumbnailData: Data, journalObject: Journal) {
        if let imageObject = NSEntityDescription.insertNewObject(forEntityName: "Image", into: managedObjectContext) as? Image {
            imageObject.fullRes = imageData
            imageObject.thumbnail = thumbnailData
            imageObject.imageJournal = journalObject
        }
    }
    
    fileprivate func scaleImage(_ imageToScale: UIImage) -> UIImage {
        var thumbnailImage = UIImage()
        
        let thumbnailSize = imageToScale.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        let hasAlpha = false
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, !hasAlpha, scale)
        imageToScale.draw(in: CGRect(origin: CGPoint.zero, size: thumbnailSize))
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            thumbnailImage = image
        }
        UIGraphicsEndImageContext()
        
        return thumbnailImage
    }
}

// MARK: - UICollectionViewDelegate

extension AddNewJournalEntryTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfImages = checkNumberOfChosenImages(chosenImageArray)
        if numberOfImages == 5 {
            return 5
        }
        return numberOfImages + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Image Cell", for: indexPath) as? JournalPhotoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.deletingDelegate = self
        cell.tag = (indexPath as NSIndexPath).item
        cell.photoImageView?.layer.borderColor = UIColor.lightGray.cgColor
        cell.photoImageView?.layer.borderWidth = 1.0
        
        if chosenImageArray[(indexPath as NSIndexPath).item] == currentChosenImage {
            cell.photoImageView?.image = currentChosenImage
            showDeleteOption(cell)
            
        } else if chosenImageArray[(indexPath as NSIndexPath).item] == cameraImage {
            cell.photoImageView?.image = cameraImage
            hideDeleteOption(cell)
            
        } else {
            cell.photoImageView?.image = chosenImageArray[(indexPath as NSIndexPath).item]
            showDeleteOption(cell)
        }
        return cell
    }
    
    fileprivate func showDeleteOption(_ cell: JournalPhotoCollectionViewCell) {
        cell.deleteImageView?.isHidden = false
        cell.deleteImageView?.image = UIImage(named: "remove_button")
        cell.deleteButton?.isUserInteractionEnabled = true
    }
    
    fileprivate func hideDeleteOption(_ cell: JournalPhotoCollectionViewCell) {
        cell.deleteImageView?.isHidden = true
        cell.deleteButton?.isUserInteractionEnabled = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showPhotoOptionsAsActionSheet(indexPath as NSIndexPath)
    }
    
    fileprivate func showPhotoOptionsAsActionSheet(_ indexPath: NSIndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: {(alert:UIAlertAction?) in
            self.openCamera(indexPath)
        })
        alertController.addAction(takePhotoAction)
        
        let choosePhotoAction = UIAlertAction(title: "Choose Photo", style: .default, handler: {(alert:UIAlertAction?) in
            self.openPhotoLibrary(indexPath)
        })
        alertController.addAction(choosePhotoAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func openCamera(_ indexPath: NSIndexPath) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            collectionViewCellItem = nil
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = true
            collectionViewCellItem = indexPath.item
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    fileprivate func openPhotoLibrary(_ indexPath: NSIndexPath) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            collectionViewCellItem = nil
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = true
            collectionViewCellItem = indexPath.item
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: Image Picker Controller
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        if let item = collectionViewCellItem {
            chosenImageArray[item] = image
            currentChosenImage = image
            if picker.sourceType == .camera {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}
