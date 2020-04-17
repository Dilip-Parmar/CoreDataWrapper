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

class SyncOperationsTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitialization() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
    }
    
    func testAddObj() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self)
        XCTAssertNotNil(car)
    }
    
    func testAddObjWidProps() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car)
        
        XCTAssertEqual(car?.model, "Audi")
        XCTAssertEqual(car?.regNo, 30)
    }
    
    func testFetchObj() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car)
        
        let fetched = coreDataWrapper.fetchBy(objectId: car!.objectID) as? Car
        XCTAssertNotNil(car)
        
        XCTAssertEqual(fetched?.model, "Audi")
        XCTAssertEqual(fetched?.regNo, 30)
    }
    
    func testDeleteObj() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car)
        
        let isDeleted = coreDataWrapper.deleteBy(objectId: car!.objectID, shouldSave: true)
        XCTAssert(isDeleted)
        
        let fetched = coreDataWrapper.fetchBy(objectId: car!.objectID) as? Car
        XCTAssertNil(fetched)
    }
    
    func testFetchAll() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car3)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertNotNil(fetched)
        
        XCTAssertEqual(fetched?.count, 3)
    }
    
    func testDeleteAll() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car3)
        
        let deleted = coreDataWrapper.deleteAllOf(type: Car.self, shouldSave: false)
        XCTAssert(deleted)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertEqual(fetched?.count, 0)
    }
    
    func testUpdateObj() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: false)
        XCTAssertNotNil(car)
        
        let updated = coreDataWrapper.updateBy(objectId: car!.objectID, properties: ["model": "dp1", "regNo": 40], shouldSave: true)
        
        XCTAssert(updated)
        XCTAssertEqual(car?.model, "dp1")
        XCTAssertEqual(car?.regNo, 40)
    }
    
    func testUpdateAll() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: false)
        XCTAssertNotNil(car3)
        
        let updated = coreDataWrapper.updateAllOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: false)
        
        XCTAssert(updated)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertEqual(fetched?.count, 3)
        
        let filtered = fetched!.filter { (car) -> Bool in
            car.model == "Audi" && car.regNo == 30
        }
        XCTAssertEqual(filtered.count, 3)
    }
    
    func testCount() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: false)
        XCTAssertNotNil(car3)
        
        let count = coreDataWrapper.countOf(type: Car.self)
        XCTAssertEqual(count, 3)
    }
    
    func testFetchProperties() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let properties = coreDataWrapper.fetchPropertiesOf(type: Car.self, propertiesToFetch: ["model", "regNo"], sortBy: ["model": true])
        XCTAssertNotNil(properties)
        
        XCTAssertEqual(properties?.count, 3)
    }
    
    func testPerformOperation() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let sum = coreDataWrapper.performOperation(operation: .sum, type: Car.self, propertyName: "regNo")
        XCTAssertNotNil(sum)
        
        XCTAssertEqual(sum!.first!["regNo"] as! Int, 70)
        
        coreDataWrapper.purgeStore()
    }
    
    func testUpdateAllSqlite() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let updated = coreDataWrapper.updateAllOf(type: Car.self, properties: ["model": "Audi", "regNo": 30], shouldSave: true)
        XCTAssert(updated)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: ["model" : true])
        XCTAssertEqual(fetched?.count, 3)
        
        let filtered = fetched!.filter { (car) -> Bool in
            car.model == "Audi" && car.regNo == 30
        }
        XCTAssertEqual(filtered.count, 3)
        
        coreDataWrapper.purgeStore()
    }
    
    func testDeleteAllSqlite() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp1", "regNo": 10], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let car2 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp2", "regNo": 20], shouldSave: false)
        XCTAssertNotNil(car2)
        
        let car3 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp3", "regNo": 40], shouldSave: true)
        XCTAssertNotNil(car3)
        
        let deleted = coreDataWrapper.deleteAllOf(type: Car.self, shouldSave: true)
        XCTAssert(deleted)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self, sortBy: nil)
        XCTAssertEqual(fetched?.count, 0)
        
        coreDataWrapper.purgeStore()
    }
}
