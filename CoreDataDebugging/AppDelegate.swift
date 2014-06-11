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
    var storeCoordinator: NSPersistentStoreCoordinator?
    var backgroundContext: NSManagedObjectContext?
    var store: NSPersistentStore?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        
        let rootViewController = UIViewController()
        self.window!.rootViewController = rootViewController
        self.window!.makeKeyAndVisible()
        
        setupCoreDataStack()
        
        return true
    }
    
    func setupCoreDataStack()
    {
        let objectModelURL = NSBundle.mainBundle().URLForResource("CoreDataDebugging", withExtension: "momd")
        let objectModel: NSManagedObjectModel? = NSManagedObjectModel(contentsOfURL: objectModelURL)
        assert(objectModel)
        
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        assert(storeCoordinator)
        
        store = storeCoordinator!.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        assert(store)

        // Set up a managed object context with private queue concurrency
        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        assert(backgroundContext)
        backgroundContext!.name = "Background context"
        backgroundContext!.persistentStoreCoordinator = storeCoordinator
        
        dispatch_async(dispatch_get_main_queue()) {
            self.completedCoreDataSetup(self.backgroundContext!)
        }
    }
    
    func completedCoreDataSetup(backgroundContext: NSManagedObjectContext!) {
        backgroundContext.performBlock {
            let person = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: backgroundContext) as NSManagedObject
            person.setValue("John Appleseed", forKey: "name")
            
            if true {
                var potentialSaveError: NSError?
                let didSave = backgroundContext.save(&potentialSaveError)
                if (didSave) {
                    println("Saving successful")
                } else {
                    let saveError = potentialSaveError!
                    println("Saving failed with error: \(saveError)")
                }
            }
        }
    }
}
