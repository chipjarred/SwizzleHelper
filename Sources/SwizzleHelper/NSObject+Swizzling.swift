import AppKit
@_exported import SwizzleHelperObjC

// MARK:- NSObject extension
// -------------------------------------
public extension NSObject
{
    // -------------------------------------
    /**
     Get the previous implementation for `selector` or `nil` if `selector` has
     no previous implementation (possible it wasn't swizzled).
     */
    static func implementation(for selector: Selector) -> IMP? {
        return Self.associatedValues[selector.description] as? IMP
    }
    
    // MARK:- Swizzled method forwarding
    // -------------------------------------
    /**
     Call the old implementation that takes no parameters, if it exists for a
     `selector` that has been replaced by swizzling.
     
     - Parameter selector: The `selector` whose previous implementation is to
        be called
     */
    func callReplacedMethod(for selector: Selector)
    {
        if let imp = Self.implementation(for: selector) {
            callIMP(imp, self, selector)
        }
    }
    
    // -------------------------------------
    /**
     Call the old implementation that takes no parameters and returns an
        `NSObject?`, if it exists for a `selector` that has been replaced by
        swizzling.
     
     - Parameter selector: The `selector` whose previous implementation is to
        be called
     - Returns: The `NSObject?` returned by the original implementation of
        `selector`.
     */
    func callReplacedMethodReturningObject(for selector: Selector) -> NSObject?
    {
        if let imp = Self.implementation(for: selector) {
            return callIMP_returningObject(imp, self, selector)
        }
        return nil
    }
    
    // -------------------------------------
    /**
     Call the old implementation that takes an `NSObject` parameter, if it
     exists for a `selector` that has been replaced by swizzling.
     
     - Parameters:
        - selector: The `selector` whose previous implementation is to be called
        - event: The `NSObject` to be forwarded to the previous implementation.
     */
    func callReplacedObjectMethod(
        for selector: Selector,
        with object: NSObject)
    {
        if let imp = Self.implementation(for: selector) {
            callIMP_withObject(imp, self, selector, object)
        }
    }
    
    // -------------------------------------
    /**
     Call the old implementation that takes an `NSEvent` parameter, if it
     exists for a `selector` that has been replaced by swizzling.
     
     - Parameters:
        - selector: The `selector` whose previous implementation is to be called
        - event: The `NSEvent` to be forwarded to the previous implementation.
     */
    func callReplacedEventMethod(
        for selector: Selector,
        with event: NSEvent)
    {
        callReplacedObjectMethod(for: selector, with: event)
    }
    
    // -------------------------------------
    /**
     Call the old implementation that takes an `NSString` parameter, if it
     exists for a `selector` that has been replaced by swizzling.
     
     - Parameters:
        - selector: The `selector` whose previous implementation is to be called
        - event: The `NSEvent` to be forwarded to the previous implementation.
     */
    func callReplacedStringMethod(
        for selector: Selector,
        with string: NSString)
    {
        callReplacedObjectMethod(for: selector, with: string)
    }

    // -------------------------------------
    /**
     Call the old implementation that takes an `NSObject` parameter, if it
     exists for a `selector` that has been replaced by swizzling.
     
     - Parameters:
        - selector: The `selector` whose previous implementation is to be called
        - closure: closure taking  asingle `Any` parameter  to be passed to
            the previous implementation ..
     */
    func callReplacedClosureMethod(
        for selector: Selector,
        with closure: @escaping (Any) -> Void)
    {
        if let imp = Self.implementation(for: selector) {
            callIMP_withClosure(imp, self, selector, closure)
        }
    }
    

    // -------------------------------------
    /**
     Replace the implementation of `oldSelector` with the implementation of
     `newSelector`.  It's up to the new implementation to forward to the old
     one.
     
     If `oldSelector` is not implemented,, it will be added using
     `newSelector`'s implementation.
     
     - Parameters:
        - oldSelector: `Selector` for existing method whose implementation is
            to be replaced.
        - newSelector: `Selector` of the method whose implementaton will be
            used to replace `oldSelector`'s implementation.
     */
    static func replaceMethod(
        _ oldSelector: Selector,
        with newSelector: Selector)
    {
        guard let newMethod = instanceMethod(for: newSelector) else {
            fatalError("Failed to get implementation for \(newSelector)")
        }
        
        let newImp = method_getImplementation(newMethod)
        if let oldImp = replaceSelectorImplementation(
            selector: oldSelector,
            newImplementation: newImp)
        {
            Self.associatedValues[oldSelector.description] = oldImp
        }
    }
    
    // -------------------------------------
    /**
     Replaces the implementation of the method specified by `Selector` in the
     receiving `class` with `newImplementation`.
     
     - Note: `IMP` is an Objective-C runtime type.  It is an `OpaquePointer` to
        a C function.
     
     - Parameters:
        - selector: The `Selector` whose corresponding method's implementation
            will be replaced by `newImplementation`.
        - newImplementation: The implmenetation, specified as an `IMP`, to
            replace the implementation for `Selector`.
     - Returns: The previous implementation of `Selector` or `nil` if there
        isn't one.
     */
    private static func replaceSelectorImplementation(
        selector: Selector,
        newImplementation: IMP) -> IMP?
    {
        #if DEBUG
        print("Swizzling \(Self.self).\(selector)")
        #endif
        
        guard self.superclass() != nil else {
            fatalError("Swizzling NSObject itself - don't do that")
        }
        
        guard let method = instanceMethod(for: selector) else {
            fatalError("Failed to get implementation for \(selector)")
        }
        
        /*
         If the method already exists, we can just replace it, because we'll
         chain to its old implementaton.  If it doesn't exist, then we need to
         add one to call super first
         */
        let types = method_getTypeEncoding(method)
        addMethodThatCallsSuper(Self.self, selector, types)
        let oldImp = class_replaceMethod(
            Self.self,
            selector,
            newImplementation,
            types
        )

        return oldImp
    }
    
    // -------------------------------------
    /**
     Convenience function for obtaining the `METHOD` associated with `selector` for the receiving class.
     
     - Parameter selector: The `Selector` whose `METHOD` is to be returned.
     - Returns: A `METHOD` for `selector` when applied to the receiving class,
        or `nil` if that `selector` is not implemented.
     - Note: `METHOD` is an opaque Objective-C runtime type representing a
        method definition.
     */
    private static func instanceMethod(for selector: Selector) -> Method? {
        return class_getInstanceMethod(Self.self, selector)
    }
}
