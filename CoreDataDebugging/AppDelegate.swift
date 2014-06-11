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
        
        let storeCoordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        assert(storeCoordinator)
        
        let store: NSPersistentStore? = storeCoordinator!.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        assert(store)

        // Set up a managed object context with private queue concurrency
        let backgroundContext: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        assert(backgroundContext)
        backgroundContext!.persistentStoreCoordinator = storeCoordinator!
        
        // Work on the background context without using performBlock:
        // This should fail because we are violating Core Data's concurrency contract.
//        let person = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: backgroundContext!) as NSManagedObject
//        person.setValue("John Appleseed", forKey: "name")
//        var potentialSaveError: NSError?
//        let didSave = backgroundContext!.save(&potentialSaveError)
//        if (didSave) {
//            println("Saving successful")
//        } else {
//            let saveError = potentialSaveError!
//            println("Saving failed with error: \(saveError)")
//        }

        // Work on the background context with using performBlock:
        // This should work but throws a multithreading violation exception on backgroundContext!.save(&potentialSaveError)
        backgroundContext!.performBlock {
            let person = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: backgroundContext!) as NSManagedObject
            person.setValue("John Appleseed", forKey: "name")
            var potentialSaveError: NSError?
            let didSave = backgroundContext!.save(&potentialSaveError)
            if (didSave) {
                println("Saving successful")
            } else {
                let saveError = potentialSaveError!
                println("Saving failed with error: \(saveError)")
            }
        }
    }
}
