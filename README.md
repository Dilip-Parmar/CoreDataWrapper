# CoreDataWrapper
A simple core data wrapper with synchronous and asynchronous helper functions. It supports SQLite, Binary and In-Memory configuration.

<div>
<a href="https://guides.cocoapods.org/">
<img src="https://img.shields.io/badge/Pod1.6.1-Compatible-brightgreen.svg" />
</a>
<a href="https://github.com/Carthage/Carthage">
<img src="https://img.shields.io/badge/Carthage-Compatible-orange.svg" />
</a>
<a href="https://swift.org/">
<img src="https://img.shields.io/badge/Swift5.0-Compatible-brightgreen.svg" />
</a>
<a href="https://swift.org/package-manager">
<img src="https://img.shields.io/badge/swift--package--manager-Compatible-yellow.svg" />
</a>
</div>

## Table of Contents

* [Features](#Features)
* [Requirements](#Requirements)
* [Installation](#Installation)
* [How to use](#How-to-use)
    * [Initialization](#Initialization)
    * [Main context synchronous operations](#Main-context-synchronous-operations)
        * [Add synchronous operation](#Add-synchronous-operation)
        * [Add with properties - synchronous operation](#Add-with-properties-synchronous-operation)
        * [Fetch synchronous operation](#Fetch-synchronous-operation)
        * [Fetch all entities synchronous operation](#Fetch-all-entities-synchronous-operation)
        * [Delete synchronous operation](#Delete-synchronous-operation)
        * [Delete all entities synchronous operation](#Delete-all-entities-synchronous-operation)
        * [Update synchronous operation](#Update-synchronous-operation)
        * [Update all entities synchronous operation](#Update-all-entities-synchronous-operation)
        * [Count synchronous operation](#Count-synchronous-operation)
        * [Fetch properties synchronously](#Fetch-properties-synchronously)
        * [Math operation synchronously](#Math-operation-synchronously)
    * [Main context asynchronous operations](#Main-context-asynchronous-operations)
        * [Add asynchronous operation](#Add-asynchronous-operation)
        * [Add with properties - asynchronous operation](#Add-with-properties-asynchronous-operation)
        * [Fetch asynchronous operation](#Fetch-asynchronous-operation)
        * [Fetch all entities asynchronous operation](#Fetch-all-entities-asynchronous-operation)
        * [Delete asynchronous operation](#Delete-asynchronous-operation)
        * [Delete all entities asynchronous operation](#Delete-all-entities-asynchronous-operation)
        * [Update asynchronous operation](#Update-asynchronous-operation)
        * [Update all entities asynchronous operation](#Update-all-entities-asynchronous-operation)
        * [Count asynchronous operation](#Count-asynchronous-operation)
        * [Fetch properties asynchronously](#Fetch-properties-asynchronously)
        * [Math operation asynchronously](#Math-operation-asynchronously)
    * [Background context asynchronous operations](#Background-context-asynchronous-operations)
    * [Save main context](#Save-main-context)
    * [Save background context](#Save-background-context)
* [Author](#Author)
* [License](#License)

## Features
- Singleton free
- No external dependencies
- Multi-threaded per se
- Multiple instances possbile with different model files
- Supports SQLITE, Binary and In-Memory store types
- Main context synchronous helper functions
- Main context asynchronous helper functions
- Background context asynchronous helper functions
- Free

## Requirements

- iOS 12.0+ / macOS 10.14+ / tvOS 12.0+ / watchOS 5.0+
- Xcode 10.2+
- Swift 5+

## Installation

**CoreDataWrapper** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'CoreDataWrapper', :git => 'https://github.com/Dilip-Parmar/CoreDataWrapper'
```

**CoreDataWrapper** is also available through [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your Cartfile:

```ruby
github "Dilip-Parmar/CoreDataWrapper"  "1.0.0" //always use latest release version
```

**CoreDataWrapper** is also available through [Swift Package Manager](https://swift.org/package-manager/). To install it, simply enter given URL into "Enter Package Repository URL" search field of Xcode.

```ruby
https://github.com/Dilip-Parmar/CoreDataWrapper
```
## How to use
## Initialization

```ruby
let bundle = Bundle(identifier: "com.myBundleId")
let coreDataWrapper = CoreDataWrapper.init(modelFileName: "Model", bundle: bundle, storeType: StoreType.sqlite)
coreDataWrapper.loadStore(completionBlock: { (isSuccess, error) in

})
```

## Main context synchronous operations
## Add synchronous operation
```ruby
let person = coreDataWrapper.addOf(type: Person.self)
```

## Add with properties synchronous operation
```ruby
let person = coreDataWrapper.addOf(type: Person.self, properties: ["fname" : "Dilip", ...], shouldSave: true)
```

## Fetch synchronous operation
```ruby
let existingPerson = coreDataWrapper.fetchBy(objectId: person.objectID)
```

## Fetch all entities synchronous operation
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
let sortBy = ["fname" : true]
let allFetchedEntities = coreDataWrapper.fetchAllOf(type: Person.self, predicate: predicate, sortBy: sortBy)
```
## Delete synchronous operation
```ruby
coreDataWrapper.deleteBy(objectId: person.objectID, shouldSave: true)
```

## Delete all entities synchronous operation
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
coreDataWrapper.deleteAllOf(type: Person.self, predicate: predicate, shouldSave: true)
```

## Update synchronous operation
```ruby
coreDataWrapper.updateBy(objectId: person.objectID, properties: ["fname" : "Dilip", ...], shouldSave: true)
```

## Update all entities synchronous operation
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
coreDataWrapper.updateAllOf(type: Person.self, properties: ["fname" : "Dilip", ...], predicate: predicate, shouldSave: true)
```

## Count synchronous operation
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
let count = coreDataWrapper.countOf(type: Person.self, predicate: predicate)
```

## Fetch properties synchronously
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
let sortBy = ["fname" : true]
let properties = coreDataWrapper.fetchPropertiesOf(type: Person.self, propertiesToFetch: ["fname, "lname"...], predicate: predicate, sortBy: sortBy, needDistinctResults: true)
```

## Math operation synchronously
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
let properties = coreDataWrapper.performOperation(operation: .sum, type: Person.self, propertyName: "age", predicate: predicate)
```

## Main context asynchronous operations

## Add asynchronous operation
```ruby
coreDataWrapper.addAsyncOf(type: Person.self, completion: {
    (person) in 
})
```

## Add with properties asynchronous operation
```ruby
coreDataWrapper.addAsyncOf(type: Person.self, properties: ["fname" : "Dilip", ...], shouldSave: true, completion: {
    (person) in 

}, completionOnMainThread: false)
```

## Fetch asynchronous operation
```ruby
let person = coreDataWrapper.fetchAsyncBy(objectId: person.objectID, completion: {
    (person) in 

}, completionOnMainThread: false)
```

## Fetch all entities asynchronous operation
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
let sortBy = ["fname" : true]
let fetchedEntities = coreDataWrapper.fetchAllAsyncOf(type: Person.self, predicate: predicate, sortBy: sortBy, completion: {
    (persons) in 

}, completionOnMainThread: false))
```

## Delete asynchronous operation
```ruby
coreDataWrapper.deleteAsyncBy(objectId: person.objectID, shouldSave: true, completion: {
    
}, completionOnMainThread: false)
```

## Delete all entities asynchronous operation
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
coreDataWrapper.deleteAllAsyncOf(type: Person.self, predicate: predicate, shouldSave: true, completion: {

}, completionOnMainThread: false)
```

## Update asynchronous operation
```ruby
coreDataWrapper.updateAsyncBy(objectId: person.objectID, properties: ["fname" : "Dilip", ...], shouldSave: true, completion: {

}, completionOnMainThread: false)
```

## Update all entities asynchronous operation
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
coreDataWrapper.updateAllAsyncOf(type: Person.self, properties: ["fname" : "Dilip", ...], predicate: predicate, shouldSave: true, completion: {

}, completionOnMainThread: false)
```

## Count asynchronous operation
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
coreDataWrapper.countAsyncOf(type: Person.self, predicate: predicate, completion: {
    (count) in
}, completionOnMainThread: false)
```

## Fetch properties asynchronously
```ruby
let predicate = NSPredicate.init(format: "fname == ", argumentArray: ["Dilip"])
let sortBy = ["fname" : true]
let properties = coreDataWrapper.fetchPropertiesOf(type: Person.self, propertiesToFetch: ["fname, "lname"...], predicate: predicate, sortBy: sortBy, needDistinctResults: true, completion: {
    (properties) in
}, completionOnMainThread: false)
```

## Math operation asynchronously
```ruby
let predicate = NSPredicate.init(format: "age >= ", argumentArray: ["30"])
coreDataWrapper.performOperationAsync(operation: .sum, type: Person.self, propertyName: "age", predicate: predicate, completion: {
    (result) in
}, completionOnMainThread: false)
```

## Background context asynchronous operations
Background context asynchronous operations are **same** as main context asynchronous operations provided background context is passed to function. eg.
```ruby
let newBgContext = coreDataWrapper.newBgContext
coreDataWrapper.addAsyncOf(type: Person.self, context: newBgContext, completion: {
(person) in 
})
```

## Save main context
```ruby
coreDataWrapper.saveMainContext(isSync: false, completion: {

})
```

## Save background context
```ruby
coreDataWrapper.saveBGContext(context: bgContext, isSync: false, completion: {

})
```

## Author

[Dilip Parmar](https://github.com/Dilip-Parmar)

## License

CoreDataWrapper is released under the MIT license. [See LICENSE](https://github.com/Dilip-Parmar/CoreDataWrapper/blob/master/LICENSE) for details.
