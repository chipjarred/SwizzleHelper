#ifdef OBJC_OLD_DISPATCH_PROTOTYPES
#undef OBJC_OLD_DISPATCH_PROTOTYPES
#endif
#define OBJC_OLD_DISPATCH_PROTOTYPES 0

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "include/swizzleHelper.h"
#import <objc/message.h>

/*
 All of the callIMP_... functions are implemented in Objective-C instead of
 Swift because I could not get Swift to properly cast them `IMP` to the correct
 type of function, resulting in crashing when calling them.
 
 The same is true for forwardToSuperFromSwizzle, but it had the additional
 problem that when making the objc_super structure, the Swift *compiler* would
 crash trying to assign its `receiver` member field, which translates to Swift
 as an Unmanaged<AnyObject>.  That seems to have been a problem in a @_cdecl
 context.

 In addition the call to objc_msgSendSuper in forwardToSuperFromSwizzle can't
 be done at all in Swift, because it's simply not available... at all.  The
 only way to call it is from Objective-C.
 */

// -------------------------------------
void callIMP(
     IMP _Nonnull imp,
     _Nonnull __unsafe_unretained id receiver,
     _Nonnull SEL selector)
{
    typedef void (*funcPtr)(__unsafe_unretained id, SEL);
    ((funcPtr)imp)(receiver, selector);
}

// -------------------------------------
void callIMP_withObject(
     IMP _Nonnull imp,
     __unsafe_unretained id _Nonnull receiver,
     _Nonnull SEL selector,
     NSObject* _Nullable param)
{
    callIMP_withPointer(
        imp,
        receiver,
        selector,
        (const void*) CFBridgingRetain(param)
    );
}

// -------------------------------------
void callIMP_withPointer(
     IMP _Nonnull imp,
     __unsafe_unretained id _Nonnull receiver,
     _Nonnull SEL selector,
     const void * _Nullable param)
{
    typedef void (*funcPtr)(__unsafe_unretained id, SEL, const void *param);
    ((funcPtr)imp)(receiver, selector, param);
}

#define USE_MSGSENDSUPER2 1
// -------------------------------------
id forwardToSuperFromSwizzle(
   _Nonnull __unsafe_unretained id receiver,
    SEL selector,
    va_list args)
{
    typedef id (*funcPtr)(struct objc_super *, SEL, va_list);
    
    if (receiver == NULL) return NULL;
    if (selector == NULL) return NULL;

#if USE_MSGSENDSUPER2
    struct objc_super superInfo = {
        .receiver = receiver,
        .super_class = object_getClass(receiver)
    };
    
    OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

    return ((funcPtr)objc_msgSendSuper2)(&superInfo, selector, args);
#else
    typedef id (*funcPtr)(struct objc_super *, SEL, va_list);
    struct objc_super superInfo = {
        .receiver = receiver,
        .super_class = class_getSuperclass(object_getClass(receiver))
    };

    return ((funcPtr)objc_msgSendSuper)(&superInfo, selector, args);
#endif
}


// -------------------------------------
BOOL addMethodThatCallsSuper(
     Class  _Nonnull __unsafe_unretained cls,
     SEL _Nonnull selector,
     const char* _Nullable types)
{
    return class_addMethod(cls, selector, (IMP)forwardToSuperFromSwizzle, types);
}
