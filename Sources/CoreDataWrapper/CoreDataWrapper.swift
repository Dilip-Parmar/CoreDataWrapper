//MIT License
//
//Copyright (c) 2019 Dilip-Parmar
//
//Permission is hereby granted, free of charge, to any Car obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit Cars to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
import CoreData

// MARK: Main Class
@available(iOS 12.0, macOS 10.13, *)
final public class CoreDataWrapper {
    
    // MARK: - Properties
    public private (set) var modelFileName: String
    public private (set) var bundle: Bundle
    public private (set) var storeURL: URL?
    public private (set) var storeType: StoreType
    public private (set) var mergePolicy: NSMergePolicy
    public private (set) var databaseFileName: String = ""
    public private (set) var error: NSError?
    private var container: NSPersistentContainer?
    
    // MARK: Initializers
    @available(iOS 12.0, macOS 10.13, *)
    public init(modelFileName: String,
                databaseFileName: String,
                bundle: Bundle,
                storeType: StoreType,
                storeURL: URL? = nil,
                mergePolicy: NSMergePolicy = .mergeByPropertyObjectTrump) {
        
        self.modelFileName = modelFileName
        self.databaseFileName = databaseFileName
        self.bundle = bundle
        self.storeType = storeType
        self.storeURL = storeURL
        self.mergePolicy = mergePolicy
    }
    // MARK: De-Initializers
    @available(iOS 12.0, macOS 10.13, *)
    deinit {
        self.storeURL = nil
    }
    // MARK: Persistent container
    @available(iOS 12.0, macOS 10.13, *)
    final public lazy var persistentContainer: NSPersistentContainer = {
        self.container = NSPersistentContainer(name: self.modelFileName, managedObjectModel: self.model)
        self.container?.persistentStoreDescriptions = [self.storeDescription]
        return self.container!
    }()
    
    @available(iOS 12.0, macOS 10.13, *)
    final public func loadStore(completionBlock: @escaping ((Bool, NSError?) -> Void)) {
        self.persistentContainer.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                self?.error = error
                completionBlock(true, error)
            } else {
                completionBlock(true, nil)
            }
            debugPrint(storeDescription.url!)
            debugPrint(storeDescription.type)
        })
    }
    
    // MARK: Main context
    @available(iOS 12.0, macOS 10.13, *)
    final public lazy var mainContext: NSManagedObjectContext = {
        let mainContext = self.persistentContainer.viewContext
        self.setConfigTo(context: mainContext)
        return mainContext
    }()
    
    // MARK: Background context
    @available(iOS 12.0, macOS 10.13, *)
    final public lazy var bgContext: NSManagedObjectContext = {
        let backgroundContext = self.persistentContainer.newBackgroundContext()
        self.setConfigTo(context: backgroundContext)
        return backgroundContext
    }()
    
    // MARK: New Background context
    @available(iOS 12.0, macOS 10.13, *)
    final public func newBgContext() -> NSManagedObjectContext {
        let newContext = self.persistentContainer.newBackgroundContext()
        self.setConfigTo(context: newContext)
        return newContext
    }
    
    // MARK: Set configuration to context
    @available(iOS 12.0, macOS 10.13, *)
    private func setConfigTo(context: NSManagedObjectContext) {
        if context.hasChanges == false {
            context.mergePolicy = self.mergePolicy
            context.automaticallyMergesChangesFromParent = true
            context.shouldDeleteInaccessibleFaults = true
            context.retainsRegisteredObjects = false
        }
    }
    
    // MARK: Persistent store coordinator
    @available(iOS 12.0, macOS 10.13, *)
    final public lazy var storeCoordinator: NSPersistentStoreCoordinator = {
        return self.persistentContainer.persistentStoreCoordinator
    }()
    
    // MARK: Managed object model
    @available(iOS 12.0, macOS 10.13, *)
    final public lazy var managedObjectModel: NSManagedObjectModel = {
        return self.storeCoordinator.managedObjectModel
    }()
    
    @available(iOS 12.0, macOS 10.13, *)
    // MARK: Lazy property - managed object model
    private lazy var model: NSManagedObjectModel = {
        //Try
        if !self.bundle.isLoaded {  self.bundle.load() }
        //Retry
        if !self.bundle.isLoaded {  self.bundle.load() }
        guard let modelURL = bundle.url(forResource: modelFileName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
                debugPrint("Error in \(#file) \(#function) \(#line)")
                fatalError()
        }
        return model
    }()
    
    @available(iOS 12.0, macOS 10.13, *)
    // MARK: Store description
    private lazy var storeDescription: NSPersistentStoreDescription = {
        let storeDescription = NSPersistentStoreDescription.init()
        switch self.storeType {
        case .sqlite: debugPrint("\(self.storeType)"); fallthrough
        case .binary:
            if let storeURL = self.storeURL {
                let dbFileNameWithExt = self.databaseFileName + self.storeType.getStoreFileExt()
                storeDescription.url = storeURL.appendingPathComponent(dbFileNameWithExt)
            } else {
                storeDescription.url = self.storeFullURL
                self.storeURL = self.storeFullURL
            }
        case .inMemory:
            break
        }
        do {
            var resourceValues: URLResourceValues = URLResourceValues.init()
            resourceValues.isExcludedFromBackup = true
            try storeDescription.url?.setResourceValues(resourceValues)
        } catch let error {
            print("could not exlcude core data file from backup")
        }
        storeDescription.type = storeType.getStorageType()
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        return storeDescription
    }()
    
    @available(iOS 12.0, macOS 10.13, *)
    // MARK: Store URL
    private lazy var storeFullURL: URL? = {
        let searchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
        let databaseFileNameWidExt = self.databaseFileName + self.storeType.getStoreFileExt()
        let url = try? FileManager.default.url(for: searchPathDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        return url?.appendingPathComponent(databaseFileNameWidExt)
    }()
    
    // MARK: Save Context
    @available(iOS 12.0, macOS 10.13, *)
    final public func saveMainContext(isSync: Bool,
                                      completion: ((Bool) -> Void)?) {
        debugPrint("called \(#function) at = \(Date())")
        let saveChangesBlock = {
            if self.mainContext.hasChanges {
                do {
                    let count = self.mainContext.insertedObjects.count + self.mainContext.updatedObjects.count + self.mainContext.deletedObjects.count
                    try self.mainContext.obtainPermanentIDs(for: Array(self.mainContext.insertedObjects))
                    print("Total objects to be saved - \(count)")
                    try self.mainContext.save()
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                    completion?(false)
                    return
                }
            }
            completion?(true)
        }
        isSync ? (self.mainContext.performAndWait {
            saveChangesBlock()
        }): (self.mainContext.perform {
            saveChangesBlock()
        })
    }
    // MARK: Save background context
    @available(iOS 12.0, macOS 10.13, *)
    final public func saveBGContext(context: NSManagedObjectContext,
                                    isSync: Bool,
                                    completion: ((Bool) -> Void)?) {
        debugPrint("called \(#function) at = \(Date())")
        let saveChangesBlock = {
            if context.hasChanges {
                do {
                    let count = context.insertedObjects.count + context.updatedObjects.count + context.deletedObjects.count
                    print("Total objects to be saved - \(count)")
                    try context.obtainPermanentIDs(for: Array(context.insertedObjects))
                    try context.save()
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                    completion?(false)
                    return
                }
            }
            completion?(true)
        }
        isSync ? (context.performAndWait {
            saveChangesBlock()
        }):(context.perform {
            saveChangesBlock()
        })
    }
    // MARK: Revert context Changes
    @available(iOS 12.0, macOS 10.13, *)
    final public func revertChangesIn(context: NSManagedObjectContext,
                                      completion: @escaping () -> Void) {
        context.perform {
            context.rollback()
            completion()
        }
    }
    // MARK: Reset context Changes
    @available(iOS 12.0, macOS 10.13, *)
    final public func resetChangesIn(context: NSManagedObjectContext,
                                     completion: @escaping () -> Void) {
        context.perform {
            context.reset()
            completion()
        }
    }
    // MARK: Destory
    @available(iOS 12.0, macOS 10.13, *)
    final public func purgeStore(completionBlock: ((Bool) -> Void)? = nil) {
        guard let storeCoordinator = self.mainContext.persistentStoreCoordinator,
            let storeURL = self.storeURL else {
                completionBlock?(false)
                return
        }
        switch self.storeType {
        case .inMemory:
            break
        case .binary:
            do {
                try storeCoordinator.destroyPersistentStore(at: storeURL,
                                                            ofType: storeType.getStorageType(),
                                                            options: nil)
                completionBlock?(true)
            } catch {
                completionBlock?(false)
            }
        case .sqlite:
            do {
                try storeCoordinator.destroyPersistentStore(at: storeURL,
                                                            ofType: storeType.getStorageType(),
                                                            options: nil)
                try FileManager.default.removeItem(at: storeURL)
                
                let writeAheadLog = storeURL.path + "-wal"
                try FileManager.default.removeItem(atPath: writeAheadLog)
                
                let sharedMemoryfile = storeURL.path + "-shm"
                try FileManager.default.removeItem(atPath: sharedMemoryfile)
                completionBlock?(true)
                
            } catch {
                completionBlock?(false)
            }
        }
    }
}

// MARK: Store Type
@available(iOS 12.0, macOS 10.13, *)
public enum StoreType: String {
    case sqlite
    case binary
    case inMemory
    
    @available(iOS 12.0, macOS 10.13, *)
    internal func getStorageType() -> String {
        switch self {
        case .sqlite:
            return NSSQLiteStoreType
        case .binary:
            return NSBinaryStoreType
        case .inMemory:
            return NSInMemoryStoreType
        }
    }
    
    @available(iOS 12.0, macOS 10.13, *)
    internal func getStoreFileExt() -> String {
        switch self {
        case .sqlite:
            return ".sqlite"
        default:
            return ""
        }
    }
}
