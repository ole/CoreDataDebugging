# Core Data Concurrency Debugging

**Update: Apple confirmed this as a bug. It has been fixed in Xcode 6 beta 4.**

When running the app from Xcode, make sure that `-com.apple.CoreData.ConcurrencyDebug 1` is included in your launch arguments.

This code is supposed to test the Core Data concurrency debugging flag in iOS 8.

It fails in this line in the AppDelegate class (`let didSave = self.backgroundContext!.save(&potentialSaveError)`) with a multithreading violation exception and I have no idea why. I believe it should work because I wrapped the access to `backgroundContext` in a `performBlock { }` call.

When I remove the performBlock { } wrapper, the code fails on a previous line with a multithreading violation (`NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: self.backgroundContext!`), which is expected behavior because we are accessing the background context from the wrong queue.

I also tested essentially the same code with Objective-C so it is probably not a Swift issue.
