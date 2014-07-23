//
//  AppDelegate.swift
//  CoreDataDebugging
//
//  Created by Ole Begemann on 10.06.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var backgroundContext: NSManagedObjectContext?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        
        let rootViewController = UIViewController()
        self.window!.rootViewController = rootViewController
        self.window!.makeKeyAndVisible()
        
        setupCoreDataStackAndViolateThreadingContract()
        
        return true
    }
    
    func setupCoreDataStackAndViolateThreadingContract()
    {
        let objectModelURL = NSBundle.mainBundle().URLForResource("CoreDataDebugging", withExtension: "momd")
        let objectModel: NSManagedObjectModel? = NSManagedObjectModel(contentsOfURL: objectModelURL)
        assert(objectModel)
        
        // Set up a simple in-memory Store (without error handling)
        let storeCoordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        assert(storeCoordinator)
        let store: NSPersistentStore? = storeCoordinator!.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        assert(store)

        // Set up a managed object context with private queue concurrency
        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        assert(backgroundContext)
        backgroundContext!.persistentStoreCoordinator = storeCoordinator!

        let insertPerson: () -> () = {
            let person = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: self.backgroundContext!) as NSManagedObject
            person.setValue("John Appleseed", forKey: "name")
            
            var potentialSaveError: NSError?
            
            // The following line fails with EXC_BAD_INSTRUCTION in +[NSManagedObjectContext __Multithreading_Violation_AllThatIsLeftToUsIsHonor__]:
            // Why? We're not violating the threading contract here.
            let didSave = self.backgroundContext!.save(&potentialSaveError)
            if (didSave) {
                println("Saving successful")
            } else {
                let saveError = potentialSaveError!
                println("Saving failed with error: \(saveError)")
            }
        };
        
        // Work on the background context by using performBlock:. This should work.
        backgroundContext!.performBlockAndWait {
            insertPerson();
        }
        
        // Work with the background context on the main thread. This should throw a multithreading violation.
        insertPerson();
        
    }
}
