//
//  CoreDataManager.swift
//  Time Lines Shared
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import CoreData
import SwiftUI

public let NO_VALUE = "__no_value__"

public class CoreDataManager {

  public static let shared = CoreDataManager()

  let groupIdentifier = "group.me.dutour.mathieu.TimeLine"
  let cloudkitIdentifier = "iCloud.me.dutour.mathieu.TimeLine"
  let model = "Model"

  lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let messageKitBundle = Bundle(for: CoreDataManager.self)
    let modelURL = messageKitBundle.url(forResource: self.model, withExtension: "momd")!
    let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)

    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
    */
    let container = NSPersistentCloudKitContainer(name: self.model, managedObjectModel: managedObjectModel!)

    let store = storeURL(for: groupIdentifier, databaseName: "TimeLine")
    let storeDescription = NSPersistentStoreDescription(url: store)
    storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudkitIdentifier)

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

      // set up cloud sync
      container.viewContext.automaticallyMergesChangesFromParent = true
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

  public func findContact(_ uriRepresentation: String) -> Contact? {
    guard
      let url = URL(string: uriRepresentation),
      let objectID = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
    else {
      return nil
    }
    return viewContext.object(with: objectID) as? Contact
  }

  public func findContact(withName name: String) -> Contact? {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Contact>(entityName: "Contact")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "name == %@", name)

    do {
      let contacts = try context.fetch(fetchRequest)

      return contacts.first
    } catch let fetchErr {
      print("❌ Failed to fetch Contact:", fetchErr)
      return nil
    }
  }

  public func findTag(_ name: String) -> Tag? {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "name == %@", name)

    do {
      let tags = try context.fetch(fetchRequest)

      return tags.first
    } catch let fetchErr {
      print("❌ Failed to fetch Tag:", fetchErr)
      return nil
    }
  }

  public func findTags(_ names: [String]) -> [Tag] {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "name IN %@", names)

    do {
      let tags = try context.fetch(fetchRequest)

      return tags
    } catch let fetchErr {
      print("❌ Failed to fetch Tags:", fetchErr)
      return []
    }
  }

  @discardableResult
  public func createContact(
    name: String,
    latitude: Double = 0,
    longitude: Double = 0,
    locationName: String = "",
    timezone: Int32 = Int32(0),
    startTime: Date? = nil,
    endTime: Date? = nil,
    tags: NSSet? = NSSet(),
    favorite: Bool = false
  ) -> Contact? {
    let index = self.count()
    let context = persistentContainer.viewContext
    let contact = NSEntityDescription.insertNewObject(forEntityName: "Contact", into: context) as! Contact

    contact.name = name
    contact.longitude  = longitude
    contact.latitude = latitude
    contact.locationName = locationName
    contact.timezone = timezone
    contact.index = Int16(index)
    contact.startTime = startTime
    contact.endTime = endTime
    contact.tags = tags
    contact.favorite = favorite

    do {
      try context.save()
      print("✅ Contact saved succesfuly")
      return contact
    } catch let error {
      print("❌ Failed to create Contact: \(error.localizedDescription)")
      return nil
    }
  }

  @discardableResult
  public func createTag(name: String, color: CPColor = Tag.randomColor()) -> Tag? {
    let context = persistentContainer.viewContext
    let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: context) as! Tag

    tag.name = name
    let components = color.rgba
    tag.red = Double(components.red)
    tag.green = Double(components.green)
    tag.blue = Double(components.blue)

    do {
      try context.save()
      print("✅ Tag saved succesfuly")
      return tag
    } catch let error {
      print("❌ Failed to create Tag: \(error.localizedDescription)")
      return nil
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

  public func deleteTag(_ tag: Tag) {
    let context = persistentContainer.viewContext
    context.delete(tag)

    do {
      try context.save()
      print("✅ Tag deleted succesfuly")
    } catch let error {
      print("❌ Failed to delete Tag: \(error.localizedDescription)")
    }
  }

  public func moveContact(from source: Int, to destination: Int) {
    if source == destination {
      return
    }

    let context = persistentContainer.viewContext

    context.performAndWait {
      var contacts = self.fetch()
      let sourceContact = contacts[source]
      contacts.remove(at: source)

      // for some reason, we need this
      var realDestination = destination
      if source < destination {
        realDestination -= 1
      }

      if realDestination > contacts.count {
        contacts.append(sourceContact)
      } else {
        contacts.insert(sourceContact, at: realDestination)
      }

      var i = 0
      for contact in contacts {
        contact.index = Int16(i)
        i += 1
      }
    }

    do {
      try context.save()
      print("✅ Contact moved succesfuly")
    } catch let error {
      print("❌ Failed to moved Contact: \(error.localizedDescription)")
    }
  }

  public func fetch() -> [Contact] {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Contact>(entityName: "Contact")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]

    do {
      let contacts = try context.fetch(fetchRequest)

      return contacts
    } catch let fetchErr {
      print("❌ Failed to fetch Contacts:", fetchErr)
      return []
    }
  }

  public func fetchTags() -> [Tag] {
    let context = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]

    do {
      let tags = try context.fetch(fetchRequest)

      return tags
    } catch let fetchErr {
      print("❌ Failed to fetch Tags:", fetchErr)
      return []
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
