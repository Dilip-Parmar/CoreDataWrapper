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

@available(iOS 12.0, macOS 10.13, *)
public enum MathOperation: String {
    case sum
    case count
    case min
    case max
    case average
}

@available(iOS 12.0, macOS 10.13, *)
extension CoreDataWrapper {
    
    // MARK: - Add
    final public func addOf<M: NSManagedObject>(type: M.Type) -> M? {
        
        var entity: M?
        self.mainContext.performAndWait {
            guard let entityDesc = NSEntityDescription.entity(forEntityName: String(describing: type),
                                                              in: self.mainContext) else {
                                                                return
            }
            entity = NSManagedObject.init(entity: entityDesc, insertInto: self.mainContext) as? M
            try? self.mainContext.obtainPermanentIDs(for: Array(self.mainContext.insertedObjects))
        }
        return entity
    }
    // MARK: - Add with properties
    final public func addOf<M: NSManagedObject>(type: M.Type,
                                                properties: [String: Any],
                                                shouldSave: Bool) -> M? {
        var entity: M?
        
        self.mainContext.performAndWait {
            guard let entityDesc = NSEntityDescription.entity(forEntityName: String(describing: type),
                                                              in: self.mainContext) else {
                                                                return
            }
            entity = NSManagedObject.init(entity: entityDesc, insertInto: self.mainContext) as? M
            try? self.mainContext.obtainPermanentIDs(for: Array(self.mainContext.insertedObjects))
            for (key, value) in properties {
                entity?.setValue(value, forKey: key)
            }
            if shouldSave {
                self.saveMainContext(isSync: true, completion: nil)
            }
        }
        return entity
    }
    // MARK: - Fetch
    final public func fetchBy(objectId: NSManagedObjectID) -> NSManagedObject? {
        var existingObject: NSManagedObject?
        
        self.mainContext.performAndWait {
            existingObject = try? self.mainContext.existingObject(with: objectId)
        }
        return existingObject
    }
    // MARK: - Fetch all entities
    final public func fetchAllOf<M: NSManagedObject>(type: M.Type,
                                                     predicate: NSPredicate? = nil,
                                                     sortBy: [String: Bool]? = nil) -> [M]? {
        var fetched: [M]?
        self.mainContext.performAndWait {
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
            let request = NSFetchRequest<M>.init(entityName: String(describing: type))
            request.predicate = predicate
            request.sortDescriptors = sortByBlock()
            request.returnsObjectsAsFaults = false
            fetched = try? self.mainContext.fetch(request)
        }
        return fetched
    }
    // MARK: - Fetch Properties
    final public func fetchPropertiesOf<M: NSManagedObject>
        (type: M.Type,
         propertiesToFetch: [String],
         predicate: NSPredicate? = nil,
         sortBy: [String: Bool]? = nil,
         needDistinctResults: Bool = false) -> [[String: AnyObject]]? {
        
        var properties: [[String: AnyObject]]?
        
        self.mainContext.performAndWait {
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
            let request = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            request.predicate = predicate
            request.propertiesToFetch = propertiesToFetch
            request.returnsObjectsAsFaults = false
            request.resultType = .dictionaryResultType
            request.returnsDistinctResults = needDistinctResults
            request.sortDescriptors = sortByBlock()
            properties = try? self.mainContext.fetch(request) as? [[String: AnyObject]]
        }
        return properties
    }
    // MARK: - Delete
    final public func deleteBy(objectId: NSManagedObjectID,
                               shouldSave: Bool) -> Bool {
        guard let managedObject = self.fetchBy(objectId: objectId),
            !managedObject.isDeleted else {
                return false
        }
        var result = false
        self.mainContext.performAndWait {
            self.mainContext.delete(managedObject)
            if shouldSave {
                self.saveMainContext(isSync: true, completion: { (isSuccess) in
                    result = isSuccess
                })
            }
        }
        return result
    }
    // MARK: - Delete all
    final public func deleteAllOf<M: NSManagedObject>(type: M.Type,
                                                      predicate: NSPredicate? = nil,
                                                      shouldSave: Bool) {
        let sqliteDeleteAll = {
            let request = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
            request.predicate = predicate
            let batchDeleteRequest = NSBatchDeleteRequest.init(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            do {
                let batchResult = try self.mainContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                let ids = batchResult?.result as? [NSManagedObjectID]
                if let ids = ids, ids.count > 0 {
                    let deletedObjects = [NSDeletedObjectsKey: ids]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: deletedObjects as [AnyHashable: Any],
                                                        into: [self.mainContext])
                }
            } catch let error {
                debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
            }
        }
        let nonSqliteDeleteAll = {
            guard let fetched = self.fetchAllOf(type: type, predicate: predicate, sortBy: nil) else {
                return
            }
            self.mainContext.performAndWait {
                for object in fetched where object.isDeleted == false {
                    //if !object.isDeleted {
                    self.mainContext.delete(object)
                    //}
                }
                if shouldSave {
                    self.saveMainContext(isSync: true, completion: nil)
                }
            }
        }
        if self.storeType == .sqlite && shouldSave {
            sqliteDeleteAll()
        } else {
            nonSqliteDeleteAll()
        }
    }
    // MARK: - Update
    final public func updateBy(objectId: NSManagedObjectID,
                               properties: [String: Any],
                               shouldSave: Bool) {
        
        let fetched = self.fetchBy(objectId: objectId)
        self.mainContext.performAndWait {
            for (key, value) in properties {
                fetched?.setValue(value, forKey: key)
            }
            if shouldSave {
                self.saveMainContext(isSync: true, completion: nil)
            }
        }
    }
    // MARK: - Update all
    final public func updateAllOf<M: NSManagedObject>
        (type: M.Type,
         properties: [AnyHashable: Any],
         predicate: NSPredicate? = nil,
         shouldSave: Bool) -> Bool {
        
        var result = false
        let sqliteUpdateAll = { () -> Bool in
            var result = false
            guard let entityDesc = NSEntityDescription.entity(forEntityName: String(describing: type),
                                                              in: self.mainContext) else {
                                                                return false
            }
            let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDesc)
            batchUpdateRequest.resultType = .updatedObjectIDsResultType
            batchUpdateRequest.propertiesToUpdate = properties as [AnyHashable: Any]
            batchUpdateRequest.predicate = predicate
            do {
                let batchUpdateResult = try self.mainContext.execute(batchUpdateRequest) as? NSBatchUpdateResult
                let ids = batchUpdateResult?.result as? [NSManagedObjectID]
                
                if let ids = ids, ids.count > 0 {
                    let updatedObjects = [NSUpdatedObjectsKey: ids] as [AnyHashable: Any]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: updatedObjects, into: [self.mainContext])
                    result = true
                }
            } catch let error {
                debugPrint("Error in \(#file) \(#function) \(#line) -- Error = \(error)")
                result = false
            }
            return result
        }
        let nonSqliteUpdateAll = { () -> Bool in
            
            guard let fetched = self.fetchAllOf(type: type, predicate: predicate, sortBy: nil) else {
                return false
            }
            self.mainContext.performAndWait {
                for object in fetched {
                    for (key, value) in properties {
                        //if key is String {
                        object.setValue(value, forKey: "\(key)")
                        //}
                    }
                }
                if shouldSave {
                    self.saveMainContext(isSync: true, completion: nil)
                }
            }
            return true
        }
        if self.storeType == .sqlite && shouldSave {
            self.mainContext.performAndWait {
                result = sqliteUpdateAll()
            }
        } else {
            result = nonSqliteUpdateAll()
        }
        return result
    }
    // MARK: - Count
    final public func countOf<M: NSManagedObject>(type: M.Type,
                                                  predicate: NSPredicate? = nil) -> Int {
        var count = 0
        
        self.mainContext.performAndWait {
            let request = NSFetchRequest<M>.init(entityName: String(describing: type))
            request.predicate = predicate
            count = (try? self.mainContext.count(for: request)) ?? -1
        }
        return count
    }
    // MARK: - Math Operation
    public final func performOperation<M: NSManagedObject>
        (operation: MathOperation,
         type: M.Type,
         propertyName: String,
         predicate: NSPredicate? = nil) -> [[String: AnyObject]]? {
        
        var properties: [[String: AnyObject]]?
        
        if self.storeType == .sqlite {
            self.mainContext.performAndWait {
                
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
                
                let request = NSFetchRequest<NSFetchRequestResult>.init(entityName: String(describing: type))
                request.returnsObjectsAsFaults = false
                request.propertiesToFetch = [expressionDesc]
                request.resultType = .dictionaryResultType
                request.predicate = predicate
                properties = try? self.mainContext.fetch(request) as? [[String: AnyObject]]
            }
        } else {
            assertionFailure("Not available other than Sqlite")
        }
        return properties
    }
}
