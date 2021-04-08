# SwizzleHelper

SwizzleHelper is a Swift Package that helps make swizzling (aka "monkey patching") Objective-C methods easier in Swift, and now it includes support for attaching key-value pairs to an Objective-C `class` or instance of a `class`.

## Swizzling
Swizzling is a practice that is sometimes used in Objective-C to change out the implementations of methods with another to hook functionality into classes that didn't provide for them.  Normally the replacement implementation calls the previous one, either before or after doing it's own thing, in order to preserve the existing functionality.  It's generally not done in Swift, and is kind of an extreme method even in Objective-C, but it can be a useful and powerful tool.  For example, I used it in combination with an extenson on `NSView` in my CustomToolTip package to add the ability to attach to any `NSView`  customized tool tips that can contain any `NSView` as its content without the need to subclass anything or wrap existing objects in a special "tool tippable" object.  The effect is you can just assign the tool tip view to a `customToolTip` property just like you assign a `String` to the standard `toolTip` that `NSView` supports out of the box.  I couldn't have made it so simple to use without swizzling.

This only works for `@objc` methods, which means you can't swizzle Swift-native methods (well, you kind of can, but that involves some especially wicked and tricky manipulation involving the dynamic linker).  Another thing to note is that when you call a method directly in Swift, it might not go through the Obj-C messaging mechanism, which means that if you swizzle `foo`'s implementation with another method called `bar`, when you call `foo` in Objective-C, it will actually call the implementation that you wrote for `bar`, because you replaced `foo`'s implementation with it.  When you call `foo` in Swift though, it might very well call the original `foo` anyway.   That's because the compiler often can resolve the exact method that should be called at compile time, but swizzling is a runtime thing.  To guarantee same behavior in Swift that you get in Objective-C, you'd have to use `NSObject`'s `performSelector` methods.  Because of this I think it's a good idea to limit swizzling to methods that are called by AppKit or UIKit rather than directly by your code, for example methods of `NSResponder` or `NSView` that are called to repond to events or changes in layout.  For example, CustomToolTip swizzles `updateTrackingAreas`, `mouseEntered`, `mouseExited` and `mouseMoved`.  Everything else it does is done in pure native Swift methods.

I dont want to encourage anyone to go to swizzling as a first solution, because you are messing with the "natural order" of things when you do this.  It's easy to break things in a way that's hard to debug.  I may provide more of a "how to" section here at some point in the future, but for now the code is pretty thoroughly documented with doc comments.  So if as a last resort, or just out of personal interest, you decide to give it a try, I'll point you to the `replaceMethod(_:with:)` and `callReplacedMethod(for:)` methods in the `NSObject+Swizzling.swift` file.  Before you do, spend some time reading the various articles on-line about swizzling, which generally are all about Objective-C, but the principle is exactly the same.  Also understand that most wide-spread way to do it also subtly wrong.  I recommend putting this [blog](https://blog.newrelic.com/engineering/right-way-to-swizzle/) on your reading list to understand why.

The current state of this package is pretty much just what I needed for CustomToolTip.  It only handles forwarding to replaced method implementations that take either no parameters or a single `NSObject` parameter and that don't return anything.  I'll expand that as I have need.

If this repo helps you get your swizzling to work, and you find that for your use case you had to add forwarding calls or anything else directly related to swizzling, please consider contributing that part of your code to help the next programmer.  While we shouldn't promote swizzling as a "go to" solution, for those who must, we can at least assemble what's needed to do it correctly and reliably in Swift, and in the process make the world a bit less buggy.

## Associated Values
Associated values are values you can associate wtih a particular subclass of `NSObject` or with an instance of any `NSObject`.  They work as key-value pairs, using a `String` as the key.  In cases where you can use a property instead, you probably should.  However, Swift `extension`s cannot have stored properties, which is where associated values come in handy, because you can use a computed property that sets and gets an associated value to behave as though you did have a stored property. 

You do this through the `associatedValues` instance property:

```swift
extension MyView
{
    var shouldBlurContents: Bool
    {
        get { associatedValues["shouldBlurContents"] as? Bool ?? false }
        set { associatedValues["shouldBlurContents"] = newValue }
    }
}
```

You can also use associated values on the class; however, they do *not* behave polymorphically.

```swift
class BaseClass: NSObject { }
class Subclass: BaseClass { }

BaseClass.associatedValues["animal"] = "dog"
BaseClass.associatedValues["plant"] = "hibiscus"
Subclass.associatedValues["animal"] = "cat"
Subclass.associatedValues["protozoa"] = "amoeba"

// prints "dog"
print("\(BaseClass.associatedValues["animal"] as? String ?? "nil")")

// prints "hibiscus"
print("\(BaseClass.associatedValues["plant"] as? String ?? "nil")")

// prints "nil"
print("\(BaseClass.associatedValues["protozoa"] as? String  ?? "nil")")

// prints "cat"
print("\(Subclass.associatedValues["animal"] as? String  ?? "nil")")

// prints "nil"
print("\(Subclass.associatedValues["plant"] as? String  ?? "nil")")

// prints "amoeba"
print("\(Subclass.associatedValues["protozoa"] as? String  ?? "nil")")

// class associated values must be retrieved by the class, not an instance of it.
let object = Subclass()

// All of these print "nil"
print("\(object.associatedValues["animal"] as? String  ?? "nil")")
print("\(object.associatedValues["plant"] as? String  ?? "nil")")
print("\(object.associatedValues["protozoa"] as? String  ?? "nil")")
```
If you want polymorphic behavior for `static`/`class` properties, you can implement it yourself by using `super.associatedValues` in subclasses. 
