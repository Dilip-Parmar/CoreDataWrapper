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
@testable import CoreDataWrapper_iOS
import XCTest
import CoreData

class AsyncOperationBlockingTests: XCTestCase {
    
    private var shouldInitializeCoreData: Bool = true
    private var coreDataWrapper: CoreDataWrapper!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if shouldInitializeCoreData == true {
            self.coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                        databaseFileName: "CoreDataWrapper",
                                                        bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                        storeType: .inMemory)
            
            let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
            self.coreDataWrapper.loadStore { (isSuccess, error) in
                XCTAssert(isSuccess)
                XCTAssertNil(error)
                loadExpectation.fulfill()
            }
            wait(for: [loadExpectation], timeout: 5.0)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.coreDataWrapper.purgeStore()
    }
    
    func testInitializationAsyncBlocking() {
        XCTAssertNotNil(coreDataWrapper)
    }
    
    func testAddObjAsyncBlocking() {
        XCTAssertNotNil(coreDataWrapper)
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.addAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, isBlocking: true) { (car) in
            XCTAssertNotNil(car)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddObjWidPropsAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.addAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, properties: ["model": "Audi", "regNo": 30], shouldSave: false, isBlocking: true, completion: { (car) in
            
            XCTAssertNotNil(car)
            
            XCTAssertEqual(car?.model, "Audi")
            XCTAssertEqual(car?.regNo, 30)
            
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchObjAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.fetchAsyncBy(type: Car.self,
                                          objectId: car!.objectID,
                                          context: self.coreDataWrapper!.bgContext,
                                          isBlocking: true,
                                          completion: { (car) in
                                            XCTAssertNotNil(car)
                                            XCTAssertEqual(car!.model, "Audi")
                                            XCTAssertEqual(car!.regNo, 30)
                                            expectation.fulfill()
                                            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteObjAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        func managedObjectContextObjectsDidChange(notification: Notification) -> Bool {
            guard let userInfo = notification.userInfo else { return false }

            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
                return false
            }
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
                return false
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                if let deleted = deletes.first as? Car {
                    XCTAssertEqual(deleted.model, "Audi")
                    XCTAssertEqual(deleted.regNo, 30)
                    return true
                }
                return false
            }
            return false
        }
        let notificationExpectation = expectation(forNotification: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                         object: self.coreDataWrapper.bgContext,
                                                         handler: managedObjectContextObjectsDidChange)
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.deleteAsyncBy(objectId: car!.objectID, context: self.coreDataWrapper.bgContext, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            XCTAssert(isDeleted)
            expectation.fulfill()
        }, completionOnMainThread: false)
        wait(for: [notificationExpectation], timeout: 1.0)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetchAllAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.fetchAllAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, sortBy: ["model" : true], isBlocking: true, completion: { (fetched) in
            XCTAssertEqual(fetched?.count, 3)
            expectation.fulfill()
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteAllAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        
        self.coreDataWrapper.deleteAllAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = self.coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 0)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
        
    }
    
    func testUpdateObjAsyncBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car = coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        
        coreDataWrapper.updateAsyncBy(objectId: car!.objectID, context: coreDataWrapper.bgContext, properties: ["model": "dp1", "regNo": 40], shouldSave: true, isBlocking: true, completion: { (isUpdated) in
            
            XCTAssert(isUpdated)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
        
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        
        self.coreDataWrapper.updateAllAsyncOf(type: Car.self, context: self.coreDataWrapper!.newBgContext(), properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: false, completion: { (updated) in
            XCTAssert(updated)
            expectation.fulfill()
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
        
        let fetched = self.coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertEqual(fetched?.count, 3)
        
        let filtered = fetched!.filter { (car) -> Bool in
            car.model == "Audi" && car.regNo == 30
        }
        XCTAssertEqual(filtered.count, 3)
    }
    
    func testCountAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.countAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, predicate: nil, isBlocking: true, completion: { (count) in
            XCTAssertEqual(count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchPropertiesAsyncBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.fetchPropertiesAsyncOf(type: Car.self, context: self.coreDataWrapper!.bgContext, propertiesToFetch: ["model", "regNo"], isBlocking: true, completion: { (properties) in
            XCTAssertNotNil(properties)
            XCTAssertEqual(properties?.count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformOperationAsyncBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.performOperationAsync(operation: .sum, type: Car.self, context: coreDataWrapper.bgContext, propertyName: "regNo", isBlocking: true, completion: { (sum) in
            XCTAssertNotNil(sum)
            XCTAssertEqual(sum!.first!["regNo"] as! Int, 70)
            expectation.fulfill()
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllSqliteAsyncBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.updateAllAsyncOf(type: Car.self, context: coreDataWrapper.bgContext, properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: true, completion: { (updated) in
            
            XCTAssert(updated)
            
            let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 3)
            
            let filtered = fetched!.filter { (car) -> Bool in
                car.model == "Audi" && car.regNo == 30
            }
            XCTAssertEqual(filtered.count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllSqliteAsyncMainThreadBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.updateAllAsyncOf(type: Car.self, context: coreDataWrapper.bgContext, properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: true, completion: { (updated) in
            
            XCTAssert(updated)
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)

        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertEqual(fetched?.count, 3)
        
        let filtered = fetched!.filter { (car) -> Bool in
            car.model == "Audi" && car.regNo == 30
        }
        XCTAssertEqual(filtered.count, 3)
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllSqliteAsyncMainThreadBGContextBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let context = coreDataWrapper.newBgContext()
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.updateAllAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: false, isBlocking: true, completion: { (updated) in
            
            XCTAssert(updated)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    
    func testDeleteAllSqliteAsyncBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.deleteAllAsyncOf(type: Car.self, context: coreDataWrapper.bgContext, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: nil)
            XCTAssertEqual(fetched?.count, 0)
            
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
        
       coreDataWrapper.purgeStore()
    }
    
    // MARK: - BG Context Test cases
    func testAddObjAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.addAsyncOf(type: Car.self, context: context) { (car) in
            XCTAssertNotNil(car)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddObjWidPropsAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let context = self.coreDataWrapper.newBgContext()
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.addAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: false, isBlocking: true, completion: { (car) in
            
            XCTAssertNotNil(car)
            
            XCTAssertEqual(car?.model, "Audi")
            XCTAssertEqual(car?.regNo, 30)
            
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddObjWidPropsAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let context = self.coreDataWrapper.newBgContext()
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.addAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: false, isBlocking: true, completion: { (car) in
            
            XCTAssertNotNil(car)
            
            XCTAssertEqual(car?.model, "Audi")
            XCTAssertEqual(car?.regNo, 30)
            
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchObjAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchAsyncBy(type: Car.self, objectId: car!.objectID, context: context, isBlocking: true, completion: { (car) in
            XCTAssertNotNil(car)
            XCTAssertEqual(car!.model, "Audi")
            XCTAssertEqual(car!.regNo, 30)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchObjAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchAsyncBy(type: Car.self, objectId: car!.objectID, context: context, isBlocking: true, completion: { (car) in
            XCTAssertNotNil(car)
            XCTAssertEqual(car!.model, "Audi")
            XCTAssertEqual(car!.regNo, 30)
            expectation.fulfill()
            
            XCTAssert(Thread.isMainThread)
            
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteObjAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        
        self.coreDataWrapper.deleteAsyncBy(objectId: car!.objectID, context: context, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = self.coreDataWrapper.fetchBy(objectId: car!.objectID) as? Car
            XCTAssert(fetched!.isDeleted)
            
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteObjAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.deleteAsyncBy(objectId: car!.objectID, context: context, shouldSave: true, isBlocking: true, completion: {  (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = self.coreDataWrapper.fetchBy(objectId: car!.objectID) as? Car
            XCTAssert(fetched!.isDeleted)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchAllAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchAllAsyncOf(type: Car.self, context: context, sortBy: ["model" : true], isBlocking: true, completion: { (fetched) in
            XCTAssertEqual(fetched?.count, 3)
            
            expectation.fulfill()
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchAllAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchAllAsyncOf(type: Car.self, context: context, sortBy: ["model" : true], isBlocking: true, completion: { (fetched) in
            XCTAssertEqual(fetched?.count, 3)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteAllAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.deleteAllAsyncOf(type: Car.self, context: context, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = self.coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 0)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteAllAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.deleteAllAsyncOf(type: Car.self, context: context, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = self.coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 0)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateObjAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        XCTAssertEqual(car!.regNo, 30)
        XCTAssertEqual(car!.model, "Audi")
        
        func managedObjectContextObjectsDidChange(notification: Notification) -> Bool {
            guard let userInfo = notification.userInfo else { return false }
            
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
                return false
            }
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
                if let carFound = updates.first as? Car {
                    XCTAssertEqual(carFound.model, "dp1")
                    XCTAssertEqual(carFound.regNo, 40)
                    return true
                }
                return false
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                return false
            }
            return false
        }
        let context = self.coreDataWrapper.newBgContext()
        let notificationExpectation = expectation(forNotification: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: context,
                                                  handler: managedObjectContextObjectsDidChange)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.updateAsyncBy(objectId: car!.objectID, context: context, properties: ["model": "dp1", "regNo": 40], shouldSave: true, isBlocking: true, completion: { (isUpdated) in
            XCTAssert(isUpdated)
            expectation.fulfill()
        }, completionOnMainThread: false)
        wait(for: [notificationExpectation], timeout: 1.0)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateObjAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.updateAsyncBy(objectId: car!.objectID, context: context, properties: ["model": "dp1", "regNo": 40], shouldSave: true, isBlocking: true, completion: { (isUpdated) in
            
            XCTAssert(isUpdated)
            
            let car = self.coreDataWrapper.fetchBy(objectId: car!.objectID) as? Car
            XCTAssertEqual(car?.model, "dp1")
            XCTAssertEqual(car?.regNo, 40)
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateObjAsyncWidBGContextMainThreadSaveBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.updateAsyncBy(objectId: car!.objectID, context: context, properties: ["model": "dp1", "regNo": 40], shouldSave: false, isBlocking: true, completion: { (isUpdated) in
            
            XCTAssert(isUpdated)
            
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateAllAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        func managedObjectContextObjectsDidChange(notification: Notification) -> Bool {
            guard let userInfo = notification.userInfo else { return false }
            
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
                return false
            }
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
                XCTAssertEqual(updates.count, 3)
                return true
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                return false
            }
            return false
        }
        let context = self.coreDataWrapper.newBgContext()
        let notificationExpectation = expectation(forNotification: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: context,
                                                  handler: managedObjectContextObjectsDidChange)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        self.coreDataWrapper.updateAllAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: true, completion: { (updated) in
            XCTAssert(updated)
            expectation.fulfill()
        }, completionOnMainThread: false)
        wait(for: [notificationExpectation], timeout: 1.0)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateAllAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.updateAllAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: true, completion: { (updated) in
            
            XCTAssert(updated)
            
            let fetched = self.coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 3)
            
            let filtered = fetched!.filter { (car) -> Bool in
                car.model == "Audi" && car.regNo == 30
            }
            XCTAssertEqual(filtered.count, 3)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCountAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.countAsyncOf(type: Car.self, context: context, predicate: nil, isBlocking: true, completion: { (count) in
            XCTAssertEqual(count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCountAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.countAsyncOf(type: Car.self, context: context, predicate: nil, isBlocking: true, completion: { (count) in
            XCTAssertEqual(count, 3)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchPropertiesAsyncWidBGContextBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchPropertiesAsyncOf(type: Car.self, context: context, propertiesToFetch: ["model", "regNo"], isBlocking: true, completion: { (properties) in
            XCTAssertNotNil(properties)
            XCTAssertEqual(properties?.count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchPropertiesAsyncWidBGContextMainThreadBlocking() {
        
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = self.coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = self.coreDataWrapper.newBgContext()
        self.coreDataWrapper.fetchPropertiesAsyncOf(type: Car.self, context: context, propertiesToFetch: ["model", "regNo"], completion: { (properties) in
            XCTAssertNotNil(properties)
            XCTAssertEqual(properties?.count, 3)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformOperationAsyncWidBGContextBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = coreDataWrapper.newBgContext()
        coreDataWrapper.performOperationAsync(operation: .sum, type: Car.self, context: context, propertyName: "regNo", isBlocking: true, completion: { (sum) in
            XCTAssertNotNil(sum)
            XCTAssertEqual(sum!.first!["regNo"] as! Int, 70)
            expectation.fulfill()
        }, completionOnMainThread: false)
        
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    func testPerformOperationAsyncWidBGContextMainThreadBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = coreDataWrapper.newBgContext()
        coreDataWrapper.performOperationAsync(operation: .sum, type: Car.self, context: context, propertyName: "regNo", isBlocking: true, completion: { (sum) in
            XCTAssertNotNil(sum)
            XCTAssertEqual(sum!.first!["regNo"] as! Int, 70)
            XCTAssert(Thread.isMainThread)
            
            expectation.fulfill()
        }, completionOnMainThread: true)
        
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllSqliteAsyncWidBGContextBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = coreDataWrapper.newBgContext()
        coreDataWrapper.updateAllAsyncOf(type: Car.self, context: context, properties: ["model": "Audi", "regNo": 30], shouldSave: true, isBlocking: true, completion: { (updated) in
            
            XCTAssert(updated)
            
            let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
            XCTAssertEqual(fetched?.count, 3)
            
            let filtered = fetched!.filter { (car) -> Bool in
                car.model == "Audi" && car.regNo == 30
            }
            XCTAssertEqual(filtered.count, 3)
            expectation.fulfill()
            
        }, completionOnMainThread: true)
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
    
    func testDeleteAllSqliteAsyncWidBGContextBlocking() {
        self.shouldInitializeCoreData = false
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: AsyncOperationBlockingTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let loadExpectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.loadStore { (isSuccess, error) in
            XCTAssert(isSuccess)
            XCTAssertNil(error)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 5.0)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        let context = coreDataWrapper.newBgContext()
        coreDataWrapper.deleteAllAsyncOf(type: Car.self, context: context, shouldSave: true, isBlocking: true, completion: { (isDeleted) in
            
            XCTAssert(isDeleted)
            
            let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: nil)
            XCTAssertEqual(fetched?.count, 0)
            
            expectation.fulfill()
            
        }, completionOnMainThread: false)
        wait(for: [expectation], timeout: 1.0)
        
        coreDataWrapper.purgeStore()
    }
}
