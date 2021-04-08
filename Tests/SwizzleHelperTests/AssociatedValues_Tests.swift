import Foundation
import XCTest
import SwizzleHelper

// -------------------------------------
class AssociatedValues_Tests: XCTestCase
{
    // -------------------------------------
    func test_can_set_and_retrieve_associated_values_for_object()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj: NSObject { }
        
        let obj = Obj()
        let numTests = 100
        for value in 0..<numTests {
            obj.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests
        {
            let value = obj.associatedValues[key(for: expected)] as? Int
            
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, expected)
        }
    }
    
    // -------------------------------------
    func test_can_set_and_retrieve_associated_values_for_object_polymorphicly()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj: NSObject { }
        class Sub: Obj { }
        
        let obj = Sub()
        let numTests = 100
        for value in 0..<numTests {
            (obj as Obj).associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests
        {
            let value = obj.associatedValues[key(for: expected)] as? Int
            
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, expected)
        }
    }
    
    // -------------------------------------
    func test_associated_values_are_associated_with_specfic_object()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj: NSObject { }
        class Sub: Obj { }
        
        let obj1 = Obj()
        let obj2 = Obj()
        let numTests = 100
        for value in 0..<numTests {
            obj1.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests {
            XCTAssertNil(obj2.associatedValues[key(for: expected)])
        }
    }
    
    // -------------------------------------
    func test_associated_values_for_class_can_be_set_and_retrieved()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj: NSObject { }
        
        let numTests = 100
        for value in 0..<numTests {
            Obj.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests
        {
            let value = Obj.associatedValues[key(for: expected)] as? Int
            
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, expected)
        }
    }
    
    // -------------------------------------
    func test_associated_values_for_a_class_cannot_be_retrieved_by_parallel_class()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj1: NSObject { }
        class Obj2: NSObject { }

        let numTests = 100
        for value in 0..<numTests {
            Obj1.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests {
            XCTAssertNil(Obj2.associatedValues[key(for: expected)] as? Int)
        }
    }
    
    // -------------------------------------
    func test_associated_values_for_a_class_cannot_be_retrieved_by_subclass()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj1: NSObject { }
        class Obj2: Obj1 { }

        let numTests = 100
        for value in 0..<numTests {
            Obj1.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests {
            XCTAssertNil(Obj2.associatedValues[key(for: expected)] as? Int)
        }
    }
    
    // -------------------------------------
    func test_associated_values_for_a_class_cannot_be_retrieved_by_superclass()
    {
        func key(for value: Int) -> String { "\(#function)_\(value)" }
        
        class Obj1: NSObject { }
        class Obj2: Obj1 { }

        let numTests = 100
        for value in 0..<numTests {
            Obj2.associatedValues[key(for: value)] = value
        }
        
        for expected in 0..<numTests {
            XCTAssertNil(Obj1.associatedValues[key(for: expected)] as? Int)
        }
    }
}
