Pod::Spec.new do |spec|

  spec.name         = "CoreDataWrapper"
  spec.version      = "3.0.1"
  spec.summary      = "A simple library with core data stack and helper functions (Core Data Wrapper)"

  spec.description  = <<-DESC

- Singleton free
- No external dependencies
- Multi-threaded per se
- Multiple instances possbile with different model files
- Supports SQLITE, Binary and In-Memory Store types
- Main context Synchronous helper functions
- Main context Asynchronous helper functions
- Background context Asynchronous helper functions
- Free

  DESC

  spec.homepage     = "https://github.com/Dilip-Parmar/CoreDataWrapper"
  spec.license      = "MIT"
  spec.author       = { "Dilip Parmar" => "dp.sgsits@gmail.com" }

  spec.ios.deployment_target = "12.0"
  spec.osx.deployment_target = "10.13"
  spec.watchos.deployment_target = "5.0"
  spec.tvos.deployment_target = "12.0"

  spec.source       = { :git => "https://github.com/Dilip-Parmar/CoreDataWrapper.git", :tag => spec.version }

  spec.source_files  = "Sources", "Sources/**/*.swift"
  spec.source_files  = "Sources", "Sources/**/**/*.swift"

  #spec.exclude_files = "Classes/Exclude"

  spec.public_header_files = "*.h"
  spec.requires_arc = true

end
