import Foundation

fileprivate var associatedValuesKey = "\(#filePath)_associatedValues"

// -------------------------------------
public extension NSObject
{
    /**
     Key-value pairs associated with a specific class or a specific instance
     of a class.
     */
    typealias AssociatedValues = [String: Any]
    
    // -------------------------------------
    /**
     `AssociatedValues` for a class are *non-polymorphically* associated with
     that class, which is to say that if you set associated values to a class,
     those values cannot be retrieved via a subclass or superclass.  They be
     can only retrieved by that exact class.
     
     In addition they cannot be obtained through an instance of the class, but
     rather must be obtained from the class itself.
     
     ```
     class BaseClass: NSObject { }
     class Subclass: BaseClass { }
     
     BaseClass.associatedValues["animal"] = "dog"
     BaseClass.associatedValues["plant"] = "hibiscus"
     Subclass.associatedValues["animal"] = "cat"
     Subclass.associatedValues["protozoa"] = "amoeba"
     
     // prints "dog"
     print("\(BaseClass.associatedValues["animal"] as? String  ?? "nil")")
     
     // prints "hibiscus"
     print("\(BaseClass.associatedValues["plant"] as? String  ?? "nil")")
     
     // prints "nil"
     print("\(BaseClass.associatedValues["protozoa"] as? String  ?? "nil")")
     
     // prints "cat"
     print("\(Subclass.associatedValues["animal"] as? String  ?? "nil")")
     
     // prints "nil"
     print("\(Subclass.associatedValues["plant"] as? String  ?? "nil")")
     
     // prints "amoeba"
     print("\(Subclass.associatedValues["protozoa"] as? String  ?? "nil")")
     
     let object = Subclass()
     
     // All of these print "nil"
     print("\(object.associatedValues["animal"] as? String  ?? "nil")")
     print("\(object.associatedValues["plant"] as? String ?? "nil")")
     print("\(object.associatedValues["protozoa"] as? String  ?? "nil")")
     ```
     */
    static var associatedValues: AssociatedValues
    {
        get
        {
            return objc_getAssociatedObject(Self.self, &associatedValuesKey)
                as? AssociatedValues ?? [:]
        }
        set
        {
            objc_setAssociatedObject(
                Self.self,
                &associatedValuesKey,
                newValue as NSDictionary,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
    
    // -------------------------------------
    /*
     `AssociatedValues` for instances are associated with that specific
     instance.
     */
    var associatedValues: AssociatedValues
    {
        get
        {
            return objc_getAssociatedObject(self, &associatedValuesKey)
                as? AssociatedValues ?? [:]
        }
        set
        {
            objc_setAssociatedObject(
                self,
                &associatedValuesKey,
                newValue as NSDictionary,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}
