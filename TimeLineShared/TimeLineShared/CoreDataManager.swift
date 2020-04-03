//
//  CoreDataManager.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import CoreData

public class CoreDataManager {

  public static let shared = CoreDataManager()

  let identifier = "me.dutour.mathieu.TimeLineShared"
  let model = "Model"

  lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let messageKitBundle = Bundle(identifier: self.identifier)
    let modelURL = messageKitBundle!.url(forResource: self.model, withExtension: "momd")!
    let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)

    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
    */
    let container = NSPersistentCloudKitContainer(name: self.model, managedObjectModel: managedObjectModel!)

    let store = storeURL(for: "group.me.dutour.mathieu.TimeLine", databaseName: "TimeLine")
    let storeDescription = NSPersistentStoreDescription(url: store)
    container.persistentStoreDescriptions = [storeDescription]

    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

  public lazy var viewContext: NSManagedObjectContext = {
    return self.persistentContainer.viewContext
  }()

  public func saveContext () {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }

  public func createContact(name: String, latitude: Double, longitude: Double, locationName: String, timezone: Int16) {
    let context = persistentContainer.viewContext
    let contact = NSEntityDescription.insertNewObject(forEntityName: "Contact", into: context) as! Contact

    contact.name = name
    contact.longitude  = longitude
    contact.latitude = latitude
    contact.locationName = locationName
    contact.timezone = timezone

    do {
      try context.save()
      print("✅ Contact saved succesfuly")
    } catch let error {
      print("❌ Failed to create Contact: \(error.localizedDescription)")
    }
  }

  public func deleteContact(_ contact: Contact) {
    let context = persistentContainer.viewContext
    context.delete(contact)

    do {
      try context.save()
      print("✅ Contact deleted succesfuly")
    } catch let error {
      print("❌ Failed to delete Contact: \(error.localizedDescription)")
    }
  }

  public func fetch() {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Contact>(entityName: "Contact")

    do {
      let contacts = try context.fetch(fetchRequest)

      for (index, contact) in contacts.enumerated() {
        print("Contact \(index): \(contact.name ?? "N/A") (\(contact.latitude):\(contact.longitude))")
      }
    } catch let fetchErr {
        print("❌ Failed to fetch Contact:",fetchErr)
    }
  }

  public func count() -> Int {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Contact>(entityName: "Contact")

    return (try? context.count(for: fetchRequest)) ?? 0
  }

  /// Returns a URL for the given app group and database pointing to the sqlite database.
  private func storeURL(for appGroup: String, databaseName: String) -> URL {
    guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
        fatalError("Shared file container could not be created.")
    }

    return fileContainer.appendingPathComponent("\(databaseName).sqlite")
  }
}
