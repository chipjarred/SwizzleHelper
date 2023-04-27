import XCTest
import SwizzleHelper
import ObjectiveC

// -------------------------------------
final class Swizzling_Tests: XCTestCase
{
    // -------------------------------------
    func test_swizzled_method_is_called()
    {
        var result: String = ""
        
        class Swizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
            
            @objc func foo() { resultSetter("Unswizzled") }
            @objc func fooReplacement() { resultSetter("Swizzled") }
        }
        
        Swizzled.replaceMethod(
            #selector(Swizzled.foo),
            with: #selector(Swizzled.fooReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        swizzled.perform(#selector(Swizzled.foo))
        
        XCTAssertEqual(result, "Swizzled")
    }
    
    // -------------------------------------
    func test_swizzled_method_can_forward_to_previous_implementation()
    {
        var result: String = ""
        
        class Swizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
            
            @objc func foo() { resultSetter("Unswizzled") }
            @objc func fooReplacement()
            {
                resultSetter("Swizzled")
                callReplacedMethod(for: #selector(Self.foo))
            }
        }
        
        Swizzled.replaceMethod(
            #selector(Swizzled.foo),
            with: #selector(Swizzled.fooReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        swizzled.perform(#selector(Swizzled.foo))
        
        XCTAssertEqual(result, "SwizzledUnswizzled")
    }
    
    // -------------------------------------
    func test_swizzled_method_can_forward_to_super_when_super_implements_swizzled_method()
    {
        var result: String = ""
        
        class Unswizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
            
            @objc func foo() { resultSetter("Unswizzled") }
        }
        
        class Swizzled: Unswizzled
        {
            @objc func fooReplacement()
            {
                resultSetter("Swizzled")
                callReplacedMethod(for: #selector(Self.foo))
            }
        }
        
        Swizzled.replaceMethod(
            #selector(Swizzled.foo),
            with: #selector(Swizzled.fooReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        
        swizzled.perform(#selector(Unswizzled.foo))
        
        XCTAssertEqual(result, "SwizzledUnswizzled")
    }
    
    // -------------------------------------
    func test_swizzled_method_can_forward_to_super_when_super_doesnt_implement_swizzled_method()
    {
        var result: String = ""
        
        class Unswizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
            
            @objc func foo() { resultSetter("Unswizzled") }
        }
        
        class UnswizzledInBetween: Unswizzled { }
        
        class Swizzled: UnswizzledInBetween
        {
            @objc func fooReplacement()
            {
                resultSetter("Swizzled")
                callReplacedMethod(for: #selector(Self.foo))
            }
        }

        Swizzled.replaceMethod(
            #selector(Swizzled.foo),
            with: #selector(Swizzled.fooReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        swizzled.perform(#selector(Swizzled.foo))
        
        XCTAssertEqual(result, "SwizzledUnswizzled")
    }
    
    // -------------------------------------
    func test_can_swizzle_property_getter()
    {
        var result: String = ""
        
        class Swizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            @objc var foo: String = "Unswizzled"
            
            @objc func fooGetterReplacement() -> String
            {
                resultSetter("Swizzled")
                return callReplacedMethodReturningObject(
                    for: #selector(getter: Swizzled.foo)
                ) as! String
            }

            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
        }
        
        
        Swizzled.replaceMethod(
            #selector(getter: Swizzled.foo),
            with: #selector(Swizzled.fooGetterReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        let foo = swizzled.perform(#selector(getter: Swizzled.foo))!
            .takeUnretainedValue() as! String
        
        XCTAssertEqual(result, "Swizzled")
        XCTAssertEqual(foo, "Unswizzled")
    }
    
    // -------------------------------------
    func test_can_swizzle_property_setter()
    {
        var result: String = ""
        
        class Swizzled: NSObject
        {
            let resultSetter: (String) -> Void
            
            @objc var foo: String = ""
            
            @objc func fooSetterReplacement(newValue: String)
            {
                resultSetter("Swizzled")
                callReplacedStringMethod(
                    for: #selector(setter: Swizzled.foo),
                    with: newValue as NSString
                )
            }

            init(_ setter: @escaping (String) -> Void) {
                self.resultSetter = setter
            }
        }
        
        
        Swizzled.replaceMethod(
            #selector(setter: Swizzled.foo),
            with: #selector(Swizzled.fooSetterReplacement)
        )
        
        let swizzled = Swizzled { result += $0 }
        swizzled.perform(#selector(setter: Swizzled.foo), with: "Unswizzled")
        
        XCTAssertEqual(result, "Swizzled")
        XCTAssertEqual(swizzled.foo, "Unswizzled")
    }
}
