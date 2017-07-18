//
//  BackupAndRestoreTVC.swift
//  Glossy
//
//  Created by Candance Smith on 2/21/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import UIKit
import CoreData

class BackupAndRestoreTVC: UITableViewController {

    // MARK: - Outlets and Variables
    
    @IBOutlet weak var automaticBackupSwitch: UISwitch?
    
    // MARK: - Set Up View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticBackupSwitch?.onTintColor = StyleManager.darkGrayColor
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 85.0
        }
        if section == 2 {
            return 0
        }
        return 70.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header = UITableViewHeaderFooterView()
        
        if section == 0 {
            header = createHeaderView("BACKUP", subtitle: "Files can be found in iTunes under File Sharing.", subtitleHeight: 30.0)
        } else if section == 1 {
            header = createHeaderView("RESTORE", subtitle: "Add the saved Backup folder that you want to restore in iTunes File Sharing.", subtitleHeight: 45.0)
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView()
        
        if section == 0 {
            let lastBackupLabel = UILabel(frame: CGRect(x: 8.0, y: 0, width: tableView.frame.width, height: 30.0))
            if let backupDate = UserDefaults.standard.object(forKey: "backupDate") as? Date {
                lastBackupLabel.text = "Last Backup: \(DateFormatter.stringFromDate(DateFormatter.dateFormatterWithTime, date: backupDate))"
            } else {
                lastBackupLabel.text = "Last Backup: Never"
            }
            lastBackupLabel.font = UIFont(name: "Avenir", size: 15.0)
            lastBackupLabel.textColor = StyleManager.headerFooterColor
            
            footer.addSubview(lastBackupLabel)
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0,
            let supportURL = NSURL(string: "http://www.candance.io/glossy/support/") {
            UIApplication.shared.openURL(supportURL as URL)
        }
    }
    
    // MARK: - Backup
    
    // MARK: Automatic Backup Switch
    
    @IBAction func automaticBackupSwitchTouched(_ sender: AnyObject) {
        if automaticBackupSwitch?.isOn == true {
            UserDefaults.standard.set(true, forKey: "isOnAutomaticBackup")
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.checkAndCreateBackup()
            }
        } else if automaticBackupSwitch?.isOn == false {
            UserDefaults.standard.set(false, forKey: "isOnAutomaticBackup")
        }
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Backup Now
    
    @IBAction func backupNowButtonTouched(_ sender: Any) {
        createBackup()
    }
    
    private func createBackup() {
        saveManagedObject()
        copySqliteFilesToBackupFolder()
        addCoreDataVersionPlist()
        UserDefaults.standard.set(Date(), forKey: "backupDate")
        UserDefaults.standard.synchronize()
        tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .none)
    }
    
    private func copySqliteFilesToBackupFolder() {
        if let applicationLibraryDirectory = (UIApplication.shared.delegate as? AppDelegate)?.applicationLibraryDirectory,
            let applicationDocumentsDirectory = (UIApplication.shared.delegate as? AppDelegate)?.applicationDocumentsDirectory {
            let atURL = applicationLibraryDirectory.appendingPathComponent("Store")
            let toURL = applicationDocumentsDirectory.appendingPathComponent("Backup")
            if FileManager.default.fileExists(atPath: toURL.path) {
                do {
                    try FileManager.default.removeItem(at: toURL)
                } catch let error as NSError {
                    print("Error removing existing .sqlite files in Backup folder: \(error.localizedDescription)")
                }
            }
            do {
                try FileManager.default.copyItem(at: atURL, to: toURL)
                presentAlertController("Success!", message: "Backup is now in iTunes")
            } catch let error as NSError {
                print("Error adding .sqlite files to Documents Directory: \(error.localizedDescription)")
                presentAlertController("Error", message: "Backup not created. Please try again.")
            }
        }
    }
    
    // Adds .plist file to backup folder to remember Core Data Version (for future updates) so restore works properly
    private func addCoreDataVersionPlist() {
        if let backupFolder = (UIApplication.shared.delegate as? AppDelegate)?.backupFolder,
            let atPath = Bundle.main.path(forResource: "CoreDataVersion", ofType: ".plist") {
            let toPath = backupFolder.appendingPathComponent("CoreDataVersion.plist").path
            
            if !FileManager.default.fileExists(atPath: toPath) {
                do {
                    try FileManager.default.copyItem(atPath: atPath, toPath: toPath)
                } catch let error as NSError {
                    print("Error adding CoreDataVersion.plist to Documents Directory: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Restore
    
    @IBAction func restoreButtonTouched(_ sender: Any) {
        confirmRestore()
    }
    
    private func confirmRestore() {
        let alertController = UIAlertController(title: "Are you sure you want to restore to backup version in iTunes File Sharing?", message: "All existing data will be replaced with backup data. This action cannot be undone.", preferredStyle: .actionSheet)
        alertController.view.tintColor = StyleManager.darkGrayColor
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let restoreAction = UIAlertAction(title: "Restore", style: .default, handler: {(alert:UIAlertAction?) in
            self.restoreBackup()
        })
        alertController.addAction(restoreAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func restoreBackup() {
        let backupFolder = backupFolderInDocumentsDirectory()
        if !backupFolder.isEmpty,
            verifyBackupFolderContents(backupFolder) {
            destroyExistingCoreDataStack()
            replaceSqliteFilesWithBackup(backupFolder)
            addNewPersistentStoreToCoordinator()
            presentAlertControllerWithHandler()
        }
    }
    
    private func addNewPersistentStoreToCoordinator() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let atURL = appDelegate.storeFolder.appendingPathComponent("GlossyDatabase.sqlite")
            let migrationOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                                    NSInferMappingModelAutomaticallyOption: true]
            do {
                try appDelegate.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: atURL, options: migrationOptions)
            } catch let error as NSError {
                print("Error adding adding new Persistent Store: \(error.localizedDescription)")
                presentAlertController("Error", message: "Cannot restore.")
            }
        }
    }
    
    private func replaceSqliteFilesWithBackup(_ backupFolderName: String) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let toURL = appDelegate.applicationDocumentsDirectory.appendingPathComponent(backupFolderName)
            let atURL = appDelegate.applicationLibraryDirectory.appendingPathComponent("Store")
            do {
                try FileManager.default.replaceItem(at: atURL, withItemAt: toURL, backupItemName: nil, options: FileManager.ItemReplacementOptions(rawValue: 0), resultingItemURL: nil)
            } catch let error as NSError {
                print("Error adding .sqlite files to Store folder: \(error.localizedDescription)")
                presentAlertController("Error", message: "Cannot restore. Backup files corrupted")
            }
        }
    }
    
    private func destroyExistingCoreDataStack() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.managedObjectContext.reset()
            
            for store in appDelegate.persistentStoreCoordinator.persistentStores {
                do {
                    try appDelegate.persistentStoreCoordinator.remove(store)
                } catch let error as NSError {
                    print("Error removing Persistent Store: \(error.localizedDescription)")
                    presentAlertController("Error", message: "Cannot restore.")
                }
            }
        }
    }
    
    private func verifyBackupFolderContents(_ backupFolderName: String) -> Bool {
        if let documentsDirectory = (UIApplication.shared.delegate as? AppDelegate)?.applicationDocumentsDirectory,
            let BundleCoreDataVersionPlist = Bundle.main.path(forResource: "CoreDataVersion", ofType: ".plist") {
            let backupFolder = documentsDirectory.appendingPathComponent(backupFolderName)
            
            let coreDataVersionPlist = backupFolder.appendingPathComponent("CoreDataVersion.plist").path
            let mainSqliteFile = backupFolder.appendingPathComponent("GlossyDatabase.sqlite").path
            
            if FileManager.default.fileExists(atPath: coreDataVersionPlist),
                FileManager.default.fileExists(atPath: mainSqliteFile),
                FileManager.default.contentsEqual(atPath: coreDataVersionPlist, andPath: BundleCoreDataVersionPlist) {
                return true
            } else {
                presentAlertController("Error", message: "Backup files missing or corrupted.")
            }
        }
        return false
    }
    
    private func backupFolderInDocumentsDirectory() -> String {
        if let documentsDirectory = (UIApplication.shared.delegate as? AppDelegate)?.applicationDocumentsDirectory {
            do {
                let backupFolderArray = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
                if let backupFolder = backupFolderArray.first {
                    return backupFolder
                } else {
                    presentAlertController("Error", message: "Backup folder missing.")
                }
            } catch let error as NSError {
                print("Error locating Backup file in Documents Directory: \(error.localizedDescription)")
                presentAlertController("Error", message: "Backup folder missing.")
            }
        }
        return ""
    }
    
    // MARK: - Helper Functions
    
    private func presentAlertControllerWithHandler() {
        let alertController = UIAlertController(title: "Success!", message: "Data successfully restored.", preferredStyle: .alert)
        alertController.view.tintColor = StyleManager.darkGrayColor
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
            StoreTVC().restorePurchases()
        })
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func saveManagedObject() {
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext {
            do {
                try managedObjectContext.save()
            } catch {
                print("Failed to save context")
            }
        }
    }
    
    private func presentAlertController(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.view.tintColor = StyleManager.darkGrayColor
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
