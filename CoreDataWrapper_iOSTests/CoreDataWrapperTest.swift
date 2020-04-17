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

class CoreDataWrapperTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResetChangesInContext() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .inMemory)
        XCTAssertNotNil(coreDataWrapper)
        
        let car = coreDataWrapper.addOf(type: Car.self)
        XCTAssertNotNil(car)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.resetChangesIn(context: coreDataWrapper.mainContext) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        let fetched = coreDataWrapper.fetchBy(objectId: car!.objectID)
        XCTAssertNil(fetched)
    }
    
    func testRollbackInContext() {
        let coreDataWrapper = CoreDataWrapper.init(modelFileName: "CoreDataWrapper",
                                                   databaseFileName: "CoreDataWrapper",
                                                   bundle: Bundle(for: SyncOperationsTests.self),
                                                   storeType: .sqlite)
        XCTAssertNotNil(coreDataWrapper)
        
        let _ = coreDataWrapper.deleteAllOf(type: Car.self, shouldSave: true)
        
        let car = coreDataWrapper.addOf(type: Car.self)
        XCTAssertNotNil(car)
        
        coreDataWrapper.saveMainContext(isSync: true, completion: { (isSuccess) in
            XCTAssert(isSuccess)
        })
        
        let car1 = coreDataWrapper.addOf(type: Car.self, properties: ["model": "dp", "regNo": 3], shouldSave: false)
        XCTAssertNotNil(car1)
        
        let expectation = XCTestExpectation.init(description: "\(#file)\(#line)")
        coreDataWrapper.revertChangesIn(context: coreDataWrapper.mainContext) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let fetched = coreDataWrapper.fetchAllOf(type: Car.self)
        XCTAssertEqual(fetched?.count, 1)
    }
}
