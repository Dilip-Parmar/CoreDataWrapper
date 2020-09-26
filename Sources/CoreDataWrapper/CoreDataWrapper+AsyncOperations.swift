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
// swiftlint:disable file_length
@available(iOS 12.0, macOS 10.13, *)
extension CoreDataWrapper {
    
    // MARK: - Add
    final public func addAsyncOf<M: NSManagedObject>
        (type: M.Type,
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
            completion(entity)
        }
        innerContext.perform {
            addBlock()
        }
    }
    // MARK: - Add with properties
    // swiftlint:disable function_body_length
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
            for (key, value) in properties {
                entity?.setValue(value, forKey: key)
            }
            let saveMain = { (completion: @escaping () -> Void) in
                self.saveMainContext(isSync: false, completion: { (bool) in
                    completion()
                })
            }
            let saveBG = { (completion: @escaping () -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: { (bool) in
                    completion()
                })
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
            //It's main context and no main thread callback
            case (false, false, false): debugPrint("\(tuple)"); fallthrough
                
            //It's bg context and no main thread callback
            case (false, true, false): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, false):
                bgCaller()
                
            //It's main context and no main thread callback
            case (false, false, true): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, true):
                saveMain({
                    bgCaller()
                })
                
            //It's bg context and no main thread callback
            case (false, true, true):
                saveBG({
                    bgCaller()
                })
                
            //It's bg context and main thread callback
            case (true, true, false): debugPrint("\(tuple)"); fallthrough
                
            //It's bg context and main thread callback
            case (true, true, true):
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
    final public func fetchAsyncBy<M: NSManagedObject>
        (type: M.Type,
         objectId: NSManagedObjectID,
         context: NSManagedObjectContext? = nil,
         completion: @escaping (M?) -> Void,
         completionOnMainThread: Bool) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            let fetched = try? innerContext.existingObject(with: objectId) as? M
            
            let mainCaller = {
                self.mainContext.perform {
                    if let fetched = fetched, let existing = self.fetchBy(objectId: fetched.objectID) as? M {
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
         sortBy: [String: Bool]?,
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
         sortBy: [String: Bool]? = nil,
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
    final public func deleteAsyncBy
        (objectId: NSManagedObjectID,
         context: NSManagedObjectContext? = nil,
         shouldSave: Bool,
         completion: @escaping (Bool) -> Void,
         completionOnMainThread: Bool) {
        var innerContext: NSManagedObjectContext
        if let context = context {
            innerContext = context
        } else {
            innerContext = self.mainContext
        }
        innerContext.perform {
            var isDeleted = false
            if let existingObject = try? innerContext.existingObject(with: objectId),
                !existingObject.isDeleted {
                innerContext.delete(existingObject)
                isDeleted = true
            }
            let saveMain = { (completion: @escaping (Bool) -> Void) in
                self.saveMainContext(isSync: false, completion: { (isSuccess) in
                    completion(isSuccess && isDeleted)
                })
            }
            let saveBG = { (completion: @escaping (Bool) -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: { (isSuccess) in
                    completion(isSuccess && isDeleted)
                })
            }
            let mainCaller = { (isSuccess: Bool) in
                self.mainContext.perform {
                    completion(isSuccess)
                }
            }
            let bgCaller = { (isSuccess: Bool) in
                completion(isSuccess)
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            case (false, false, false): //It's main context and no main thread callback
                bgCaller(isDeleted)
            case (false, false, true): //It's main context and no main thread callback
                saveMain({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
            case (false, true, false): //It's bg context and no main thread callback
                bgCaller(isDeleted)
            case (false, true, true): //It's bg context and no main thread callback
                saveBG({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
            case (true, false, false): //It's main context and main thread callback
                bgCaller(isDeleted)
            case (true, false, true): //It's main context and main thread callback
                saveMain({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
            case (true, true, false): //It's bg context and main thread callback
                mainCaller(isDeleted)
            case (true, true, true): //It's bg context and main thread callback
                saveBG({ (isSuccess: Bool) in
                    mainCaller(isSuccess)
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
         completion: @escaping (Bool) -> Void,
         completionOnMainThread: Bool) {
        
        let innerContext: NSManagedObjectContext = (context != nil) ? context! : self.mainContext
        let deleteAllObjectBlock = { () -> Bool in
            var result = false
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            fetchRequest.predicate = predicate
            //Local function
            func sqliteBlock() -> Bool {
                var sqliteResult = false
                let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteBatchRequest.resultType = .resultTypeObjectIDs
                do {
                    let deleteResult = try innerContext.execute(deleteBatchRequest) as? NSBatchDeleteResult
                    if let ids = deleteResult?.result as? [NSManagedObjectID],
                        ids.count > 0 {
                        let changedObjects = [NSDeletedObjectsKey: ids]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changedObjects as [AnyHashable: Any],
                                                            into: [innerContext, self.mainContext])
                        sqliteResult = true
                    }
                } catch let error {
                    debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                }
                return sqliteResult
            }
            //Local function
            func nonSqliteBlock() -> Bool {
                var nonSqliteResult = false
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let fetchedObjects = try? innerContext.fetch(fetchRequest) as? [M]
                    if let fetchedObjects = fetchedObjects {
                        for object in fetchedObjects where object.isDeleted == false {
                            innerContext.delete(object)
                        }
                        nonSqliteResult = true
                    } else {
                        nonSqliteResult = false
                    }
                }
                return nonSqliteResult
            }
            //Important: Batch delete are only available when you are using a SQLite persistent store.
            if self.storeType == .sqlite && shouldSave {
                result = sqliteBlock()
            } else {
                result = nonSqliteBlock()
            }
            return result
        }
        innerContext.perform {
            let isDeleted = deleteAllObjectBlock()
            
            let saveMain = { (completion: @escaping (Bool) -> Void) in
                if self.storeType != .sqlite {
                    self.saveMainContext(isSync: false, completion: { (isSuccess) in
                        completion(isSuccess && isDeleted)
                    })
                } else {
                    completion(isDeleted)
                }
            }
            let saveBG = { (completion: @escaping (Bool) -> Void) in
                if self.storeType != .sqlite {
                    self.saveBGContext(context: innerContext, isSync: true, completion: { (isSuccess) in
                        completion(isSuccess && isDeleted)
                    })
                } else {
                    completion(isDeleted)
                }
            }
            let mainCaller = { (isSuccess: Bool) in
                self.mainContext.perform {
                    completion(isDeleted)
                }
            }
            let bgCaller = { (isSuccess: Bool) in
                completion(isDeleted)
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            //It's bg context and no main thread callback
            case (false, true, false): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, false): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and no main thread callback
            case (false, false, false):
                bgCaller(isDeleted)
                
            //It's main context and no main thread callback
            case (false, false, true): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, true):
                saveMain({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
                
            //It's bg context and no main thread callback
            case (false, true, true):
                saveBG({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
                
            //It's bg context and main thread callback
            case (true, true, false):
                mainCaller(isDeleted)
                
            //It's bg context and main thread callback
            case (true, true, true):
                saveBG({ (isSuccess: Bool) in
                    mainCaller(isSuccess)
                })
            }
        }
    }
    // MARK: - Update
    final public func updateAsyncBy
        (objectId: NSManagedObjectID,
         context: NSManagedObjectContext? = nil,
         properties: [String: Any],
         shouldSave: Bool,
         completion: @escaping (Bool) -> Void,
         completionOnMainThread: Bool) {
        let innerContext: NSManagedObjectContext = (context != nil) ? context! : self.mainContext
        innerContext.perform {
            var isUpdated = false
            if let fetched = try? innerContext.existingObject(with: objectId) {
                for (key, value) in properties {
                    fetched.setValue(value, forKey: key)
                }
                isUpdated = true
            }
            let saveMain = { (completion: @escaping (Bool) -> Void) in
                self.saveMainContext(isSync: false, completion: { (isSuccess) in
                    completion(isSuccess && isUpdated)
                })
            }
            let saveBG = { (completion: @escaping (Bool) -> Void) in
                self.saveBGContext(context: innerContext, isSync: true, completion: { (isSuccess) in
                    completion(isSuccess && isUpdated)
                })
            }
            let mainCaller = { (updateResult: Bool) in
                self.mainContext.perform {
                    completion(updateResult)
                }
            }
            let bgCaller = { (updateResult: Bool) in
                completion(updateResult)
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            //It's main context and no main thread callback
            case (false, false, false): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, false): debugPrint("\(tuple)"); fallthrough
                
            //It's bg context and no main thread callback
            case (false, true, false):
                bgCaller(isUpdated)
            //It's main context and no main thread callback
            case (false, false, true): debugPrint("\(tuple)"); fallthrough
            //It's main context and main thread callback
            case (true, false, true):
                saveMain({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
            //It's bg context and no main thread callback
            case (false, true, true):
                saveBG({ (isSuccess: Bool) in
                    bgCaller(isSuccess)
                })
                
            //It's bg context and main thread callback
            case (true, true, false):
                mainCaller(isUpdated)
            //It's bg context and main thread callback
            case (true, true, true):
                saveBG({ (isSuccess: Bool) in
                    mainCaller(isSuccess)
                })
            }
        }
    }
    // MARK: - Update all
    final public func updateAllAsyncOf<M: NSManagedObject>
        (type: M.Type,
         context: NSManagedObjectContext? = nil,
         properties: [AnyHashable: Any],
         predicate: NSPredicate? = nil,
         shouldSave: Bool,
         completion: @escaping (Bool) -> Void,
         completionOnMainThread: Bool) {
        
        let innerContext: NSManagedObjectContext = (context != nil) ? context! : self.mainContext
        
        //Local function
        func sqliteBlock() -> Bool {
            var sqliteResult = false
            guard let entityDesc =
                NSEntityDescription.entity(forEntityName: String(describing: type),
                                           in: innerContext) else {
                                            return false
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
                                                        into: [innerContext, self.mainContext])
                    sqliteResult = true
                }
            } catch let error {
                debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
            }
            return sqliteResult
        }
        //Local function
        func nonSqliteBlock() -> Bool {
            var nonSqliteResult = false
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.predicate = predicate
            do {
                if let fetchedObjects = try innerContext.fetch(fetchRequest) as? [M] {
                    for object in fetchedObjects {
                        for (key, value) in properties {
                            //if key is String {
                            object.setValue(value, forKey: "\(key)")
                            //}
                        }
                    }
                    nonSqliteResult = true
                }
            } catch let error {
                debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
            }
            return nonSqliteResult
        }
        let updateAllBlock = { () -> Bool in
            var updateResult = false
            if self.storeType == .sqlite && shouldSave {
                updateResult = sqliteBlock()
            } else {
                updateResult = nonSqliteBlock()
            }
            return updateResult
        }
        innerContext.perform {
            
            let isUpdated = updateAllBlock()
            
            let saveMain = { (completion: @escaping (Bool) -> Void) in
                if self.storeType != .sqlite {
                    self.saveMainContext(isSync: false, completion: { (isSuccess) in
                        completion(isSuccess && isUpdated)
                    })
                } else {
                    completion(isUpdated)
                }
            }
            let saveBG = { (completion: @escaping (Bool) -> Void) in
                if self.storeType != .sqlite {
                    self.saveBGContext(context: innerContext, isSync: true, completion: { (isSuccess) in
                        completion(isSuccess && isUpdated)
                    })
                } else {
                    completion(isUpdated)
                }
            }
            let mainCaller = { (updateResult: Bool) in
                self.mainContext.perform {
                    completion(updateResult)
                }
            }
            let bgCaller = { (updateResult: Bool) in
                completion(updateResult)
            }
            let tuple = (completionOnMainThread, (context != nil), shouldSave)
            switch tuple {
            //It's main context and no main thread callback
            case (false, false, false): debugPrint("\(tuple)"); fallthrough
                
            //It's bg context and no main thread callback
            case (false, true, false): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, false):
                bgCaller(isUpdated)
                
            //It's main context and no main thread callback
            case (false, false, true): debugPrint("\(tuple)"); fallthrough
                
            //It's main context and main thread callback
            case (true, false, true):
                saveMain({ (updateResult) in
                    bgCaller(updateResult)
                })
                
            //It's bg context and no main thread callback
            case (false, true, true):
                saveBG({ (updateResult) in
                    bgCaller(updateResult)
                })
                
            //It's bg context and main thread callback
            case (true, true, false):
                mainCaller(isUpdated)
                
            //It's bg context and main thread callback
            case (true, true, true):
                saveBG({ (updateResult) in
                    mainCaller(updateResult)
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
                case .count: debugPrint("\(operation)"); fallthrough
                case .min:   debugPrint("\(operation)"); fallthrough
                case .max:   debugPrint("\(operation)"); fallthrough
                case .sum:
                    expressionResultType = .integer64AttributeType
                    
                case .average:
                    expressionResultType = .doubleAttributeType
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
