//MIT License
//
//Copyright (c) 2019 Dilip-Parmar
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
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

@available(iOS 12.0, macOS 10.13, *)
extension CoreDataWrapper {
    
    // MARK: - Add
    final public func addAsyncOf<M: NSManagedObject>(type: M.Type,
                                                     context: NSManagedObjectContext? = nil,
                                                     completion: @escaping (M?) -> Void) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let addBlock = {
            let entityName = String(describing: type)
            guard let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: innerContext) else {
                completion(nil)
                return
            }
            let entity = NSManagedObject.init(entity: entityDesc, insertInto: innerContext) as? M
            try? innerContext.obtainPermanentIDs(for: Array(innerContext.insertedObjects))
            completion(entity)
        }
        innerContext.perform {
            addBlock()
        }
    }
    // MARK: - Add with properties
    final public func addAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         properties: [String: Any],
         shouldSave: Bool,
         completion: @escaping (M?) -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let addBlock = {
            let entityName = String(describing: type)
            guard let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: innerContext) else {
                completion(nil)
                return
            }
            let entity = NSManagedObject.init(entity: entityDesc, insertInto: innerContext) as? M
            try? innerContext.obtainPermanentIDs(for: Array(innerContext.insertedObjects))
            for (key, value) in properties {
                entity?.setValue(value, forKey: key)
            }
            let saveMain = { (completion: @escaping () -> Void) in
                self.saveMainContext(isSync: false, completion: completion)
            }
            let saveBG = { (completion: @escaping () -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: completion)
            }
            let mainCaller = {
                self.mainContext.perform {
                    if let entity = entity, let fetched = self.fetchBy(objectId: entity.objectID) as? M {
                        completion(fetched)
                    } else {
                        completion(nil)
                    }
                }
            }
            let bgCaller = {
                completion(entity)
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, false, true): //It's main context and no main thread callback
                saveMain({
                    bgCaller()
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller()
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({
                    bgCaller()
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller()
            case (true, false, true): //It's main context and main thread callback
                saveMain({
                    bgCaller()
                })
            case (true, true, false): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            case (true, true, true): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            }
        }
        innerContext.perform {
            addBlock()
        }
    }
    // MARK: - Fetch
    final public func fetchAsyncBy(objectId: NSManagedObjectID,
                                   context: NSManagedObjectContext? = nil,
                                   completion: @escaping (NSManagedObject?) -> Void,
                                   completionOnMainThread: Bool) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            let fetched = try? innerContext.existingObject(with: objectId)
            
            let mainCaller = {
                self.mainContext.perform {
                    if let fetched = fetched, let existing = self.fetchBy(objectId: fetched.objectID) {
                        completion(existing)
                    } else {
                        completion(nil)
                    }
                }
            }
            let bgCaller = {
                completion(fetched)
            }
            let tuple = (completionOnMainThread, (context != nil))
            switch tuple {
            case (false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, true): //It's bg context and no main thread callback
                bgCaller()
            case (true, false): //It's main context and main thread callback
                bgCaller()
            case (true, true): //It's bg context and main thread callback
                mainCaller()
            }
        }
    }
    // MARK: - Fetch all
    final public func fetchAllAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         predicate: NSPredicate? = nil,
         sortBy:[String: Bool]?,
         completion: @escaping ([M]?) -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let sortByBlock = { () -> [NSSortDescriptor] in
            var sortDescriptors = [NSSortDescriptor]()
            guard let sortBy = sortBy else {
                return sortDescriptors
            }
            for (key, sortOrder) in sortBy {
                sortDescriptors.append(NSSortDescriptor(key: key, ascending: sortOrder))
            }
            return sortDescriptors
        }
        innerContext.perform {
            let request = NSFetchRequest<M>.init(entityName: String(describing: type))
            request.predicate = predicate
            request.sortDescriptors = sortByBlock()
            request.returnsObjectsAsFaults = false
            let fetched = try? innerContext.fetch(request)
            
            let mainCaller = {
                self.mainContext.perform {
                    if let fetched = fetched {
                        var allObjects = [M]()
                        for fetchedObj in fetched {
                            if let existing = try? self.mainContext.existingObject(with: fetchedObj.objectID) as? M {
                                allObjects.append(existing)
                            }
                        }
                        completion(allObjects)
                    } else {
                        completion(nil)
                    }
                }
            }
            let bgCaller = {
                completion(fetched)
            }
            let tuple = (completionOnMainThread, (context != nil))
            switch tuple {
            case (false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, true): //It's bg context and no main thread callback
                bgCaller()
            case (true, false): //It's main context and main thread callback
                bgCaller()
            case (true, true): //It's bg context and main thread callback
                mainCaller()
            }
        }
    }
    // MARK: - Fetch Properties
    final public func fetchPropertiesAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         propertiesToFetch: [String],
         predicate: NSPredicate? = nil,
         sortBy:[String: Bool]? = nil,
         needDistinctResults: Bool = false,
         completion: @escaping ([[String: AnyObject]]?) -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let sortByBlock = { () -> [NSSortDescriptor] in
            var sortDescriptors = [NSSortDescriptor]()
            guard let sortBy = sortBy else {
                return sortDescriptors
            }
            for (key, sortOrder) in sortBy {
                sortDescriptors.append(NSSortDescriptor(key: key, ascending: sortOrder))
            }
            return sortDescriptors
        }
        innerContext.perform {
            var properties: [[String: AnyObject]]?
            let request = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            request.propertiesToFetch = propertiesToFetch
            request.returnsObjectsAsFaults = false
            request.resultType = .dictionaryResultType
            request.predicate = predicate
            request.returnsDistinctResults = needDistinctResults
            request.sortDescriptors = sortByBlock()
            properties = try? innerContext.fetch(request) as? [[String: AnyObject]]
            
            let mainCaller = {
                self.mainContext.perform {
                    completion(properties)
                }
            }
            let bgCaller = {
                completion(properties)
            }
            let tuple = (completionOnMainThread, (context != nil))
            switch tuple {
            case (false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, true): //It's bg context and no main thread callback
                bgCaller()
            case (true, false): //It's main context and main thread callback
                bgCaller()
            case (true, true): //It's bg context and main thread callback
                mainCaller()
            }
        }
    }
    // MARK: - Delete
    final public func deleteAsyncBy(objectId: NSManagedObjectID,
                                    context: NSManagedObjectContext? = nil,
                                    shouldSave: Bool,
                                    completion: @escaping () -> Void,
                                    completionOnMainThread: Bool) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            if let existingObject = try? innerContext.existingObject(with: objectId),
                !existingObject.isDeleted {
                innerContext.delete(existingObject)
            }
            let saveMain = { (completion: @escaping () -> Void) in
                self.saveMainContext(isSync: false, completion: completion)
            }
            let saveBG = { (completion: @escaping () -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: completion)
            }
            let mainCaller = {
                self.mainContext.perform {
                    completion()
                }
            }
            let bgCaller = {
                completion()
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, false, true): //It's main context and no main thread callback
                saveMain({
                    bgCaller()
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller()
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({
                    bgCaller()
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller()
            case (true, false, true): //It's main context and main thread callback
                saveMain({
                    bgCaller()
                })
            case (true, true, false): //It's bg context and main thread callback
                mainCaller()
            case (true, true, true): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            }
        }
    }
    // MARK: - Delete all
    final public func deleteAllAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         predicate: NSPredicate? = nil,
         shouldSave: Bool,
         completion: @escaping () -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let deleteAllObjectBlock = {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            fetchRequest.predicate = predicate
            
            //Important: Batch delete are only available when you are using a SQLite persistent store.
            if (self.storeType == .sqlite && shouldSave) {
                let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteBatchRequest.resultType = .resultTypeObjectIDs
                do {
                    let deleteResult = try innerContext.execute(deleteBatchRequest) as? NSBatchDeleteResult
                    if let ids = deleteResult?.result as? [NSManagedObjectID],
                        ids.count > 0 {
                        let changedObjects = [NSDeletedObjectsKey: ids]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changedObjects as [AnyHashable: Any],
                                                            into: [innerContext])
                    }
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                }
            } else {
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let fetchedObjects = try? innerContext.fetch(fetchRequest) as? [M]
                    if let fetchedObjects = fetchedObjects {
                        for object in fetchedObjects {
                            if (!object.isDeleted) {
                                innerContext.delete(object)
                            }
                        }
                    }
                }
            }
        }
        innerContext.perform {
            deleteAllObjectBlock()
            
            let saveMain = { (completion: @escaping () -> Void) in
                if (self.storeType != .sqlite) {
                    self.saveMainContext(isSync: false, completion: completion)
                } else {
                    completion()
                }
            }
            let saveBG = { (completion: @escaping () -> Void) in
                if (self.storeType != .sqlite) {
                    self.saveBGContext(context: innerContext, isSync: true, completion: completion)
                } else {
                    completion()
                }
            }
            let mainCaller = {
                self.mainContext.perform {
                    completion()
                }
            }
            let bgCaller = {
                completion()
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, false, true): //It's main context and no main thread callback
                saveMain({
                    bgCaller()
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller()
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({
                    bgCaller()
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller()
            case (true, false, true): //It's main context and main thread callback
                saveMain({
                    bgCaller()
                })
            case (true, true, false): //It's bg context and main thread callback
                mainCaller()
            case (true, true, true): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            }
        }
    }
    // MARK: - Update
    final public func updateAsyncBy(objectId: NSManagedObjectID,
                                    context: NSManagedObjectContext? = nil,
                                    properties: [String: Any],
                                    shouldSave: Bool,
                                    completion: @escaping () -> Void,
                                    completionOnMainThread: Bool) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            if let fetched = try? innerContext.existingObject(with: objectId) {
                for (key, value) in properties {
                    fetched.setValue(value, forKey: key)
                }
            }
            let saveMain = { (completion: @escaping () -> Void) in
                self.saveMainContext(isSync: false, completion: completion)
            }
            let saveBG = { (completion: @escaping () -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: completion)
            }
            let mainCaller = {
                self.mainContext.perform {
                    completion()
                }
            }
            let bgCaller = {
                completion()
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, false, true): //It's main context and no main thread callback
                saveMain({
                    bgCaller()
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller()
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({
                    bgCaller()
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller()
            case (true, false, true): //It's main context and main thread callback
                saveMain({
                    bgCaller()
                })
            case (true, true, false): //It's bg context and main thread callback
                mainCaller()
            case (true, true, true): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            }
        }
    }
    // MARK: - Update all
    final public func updateAllAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         properties:[AnyHashable: Any],
         predicate: NSPredicate? = nil,
         shouldSave: Bool,
         completion: @escaping () -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        let updateAllBlock = {
            if (self.storeType == .sqlite && shouldSave) {
                guard let entityDesc =
                    NSEntityDescription.entity(forEntityName: String(describing: type),
                                               in: innerContext) else {
                                                completion()
                                                return
                }
                //Batch updates are only available when you are using a SQLite persistent store.
                let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDesc)
                
                batchUpdateRequest.resultType = .updatedObjectIDsResultType
                batchUpdateRequest.propertiesToUpdate = properties as [AnyHashable: Any]
                batchUpdateRequest.predicate = predicate
                do {
                    let batchUpdateResult = try innerContext.execute(batchUpdateRequest) as? NSBatchUpdateResult
                    let objectIDArray = batchUpdateResult?.result as? [NSManagedObjectID]
                    
                    if let ids = objectIDArray, ids.count > 0 {
                        let changes = [NSUpdatedObjectsKey: ids] as [AnyHashable: Any]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes,
                                                            into: [innerContext])
                    }
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                }
            } else {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
                fetchRequest.returnsObjectsAsFaults = false
                fetchRequest.predicate = predicate
                do {
                    let fetchedObjects = try innerContext.fetch(fetchRequest) as? [M]
                    if let fetchedObjects = fetchedObjects {
                        for object in fetchedObjects {
                            for (key, value) in properties {
                                if key is String {
                                    object.setValue(value, forKey: key as! String)
                                }
                            }
                        }
                    }
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                }
            }
        }
        innerContext.perform {
            updateAllBlock()
            let saveMain = { (completion: @escaping () -> Void) in
                if (self.storeType != .sqlite) {
                    self.saveMainContext(isSync: false, completion: completion)
                } else {
                    completion()
                }
            }
            let saveBG = { (completion: @escaping () -> Void) in
                if (self.storeType != .sqlite) {
                    self.saveBGContext(context: innerContext, isSync: true, completion: completion)
                } else {
                    completion()
                }
            }
            let mainCaller = {
                self.mainContext.perform {
                    completion()
                }
            }
            let bgCaller = {
                completion()
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, false, true): //It's main context and no main thread callback
                saveMain({
                    bgCaller()
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller()
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({
                    bgCaller()
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller()
            case (true, false, true): //It's main context and main thread callback
                saveMain({
                    bgCaller()
                })
            case (true, true, false): //It's bg context and main thread callback
                mainCaller()
            case (true, true, true): //It's bg context and main thread callback
                saveBG({
                    mainCaller()
                })
            }
        }
    }
    // MARK: - Count
    final public func countAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         predicate: NSPredicate?,
         completion: @escaping (Int) -> Void,
         completionOnMainThread: Bool) {
        
        var innerContext: NSManagedObjectContext
        if let context = context {
             innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            let request = NSFetchRequest<M>.init(entityName: String(describing: type))
            request.predicate = predicate
            let count = (try? innerContext.count(for: request)) ?? -1
            
            let mainCaller = {
                self.mainContext.perform {
                    completion(count)
                }
            }
            let bgCaller = {
                completion(count)
            }
            let tuple = (completionOnMainThread, (context != nil))
            switch tuple {
            case (false, false): //It's main context and no main thread callback
                bgCaller()
            case (false, true): //It's bg context and no main thread callback
                bgCaller()
            case (true, false): //It's main context and main thread callback
                bgCaller()
            case (true, true): //It's bg context and main thread callback
                mainCaller()
            }
        }
    }
    // MARK: - Math Operation
    public final func performOperationAsync<M: NSManagedObject>
        (operation: MathOperation,
         type: M.Type,
         context: NSManagedObjectContext? = nil,
         propertyName: String,
         predicate: NSPredicate? = nil,
         completion: @escaping ([[String: AnyObject]]?) -> Void,
         completionOnMainThread: Bool) {
        
        if self.storeType == .sqlite {
            var innerContext: NSManagedObjectContext
            if let context = context {
                innerContext = context
            } else {
                innerContext = self.mainContext
            }
            let operationBlock = {
                var properties: [[String: AnyObject]]?
                let keypathExp = NSExpression(forKeyPath: propertyName) // can be any column
                let expression = NSExpression(forFunction: (operation.rawValue + ":"),
                                              arguments: [keypathExp])
                
                let expressionDesc = NSExpressionDescription()
                expressionDesc.expression = expression
                expressionDesc.name = propertyName
                
                var expressionResultType: NSAttributeType
                switch operation {
                case .count: fallthrough
                case .min:   fallthrough
                case .max:   fallthrough
                case .sum:
                    expressionResultType = .integer64AttributeType
                    
                case .average:
                    expressionResultType = .doubleAttributeType
                    
                case .lowercase: fallthrough
                case .uppercase:
                    expressionResultType = .stringAttributeType
                }
                expressionDesc.expressionResultType = expressionResultType
                
                let entityName = String(describing: type)
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                request.returnsObjectsAsFaults = false
                //request.propertiesToGroupBy = [propertyName]
                request.propertiesToFetch = [expressionDesc]
                request.resultType = .dictionaryResultType
                request.predicate = predicate
                do {
                    properties = try innerContext.fetch(request) as? [[String: AnyObject]]
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                }
                let mainCaller = {
                    self.mainContext.perform {
                        completion(properties)
                    }
                }
                let bgCaller = {
                    completion(properties)
                }
                let tuple = (completionOnMainThread, (context != nil))
                switch tuple {
                case (false, false): //It's main context and no main thread callback
                    bgCaller()
                case (false, true): //It's bg context and no main thread callback
                    bgCaller()
                case (true, false): //It's main context and main thread callback
                    bgCaller()
                case (true, true): //It's bg context and main thread callback
                    mainCaller()
                }
            }
            innerContext.perform {
                operationBlock()
            }
        } else {
            completion(nil)
        }
    }
}
