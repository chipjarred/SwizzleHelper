#ifdef OBJC_OLD_DISPATCH_PROTOTYPES
#undef OBJC_OLD_DISPATCH_PROTOTYPES
#endif
#define OBJC_OLD_DISPATCH_PROTOTYPES 0

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "include/swizzleHelper.h"
#import <objc/message.h>

// objc_msgSendSuper2 is in runtime but not in objc/message.h
OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

#define USE_MSGSENDSUPER2 1

/*
 All of the callIMP_... functions are implemented in Objective-C instead of
 Swift because I could not get Swift to properly cast them `IMP` to the correct
 type of function, resulting in crashing when calling them.
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
NSObject* _Nullable callIMP_returningObject(
     IMP _Nonnull imp,
     _Nonnull __unsafe_unretained id receiver,
     _Nonnull SEL selector)
{
    typedef NSObject* (*funcPtr)(__unsafe_unretained id, SEL);
    NSObject* obj = ((funcPtr)imp)(receiver, selector);
    return obj;
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

// -------------------------------------
/*!
 @abstract Call the functoin specified by `imp` passing the `receiver`,
 `selector`, and a void pointer
 @param imp the implementation function to be called
 @param receiver the receiver of the implementatoin call
 @param selector the selector to be used for the implemenation call.
 @param param An Objective-C block to be passed as the parameter.
 */
void callIMP_withClosure(
    IMP _Nonnull imp,
    __unsafe_unretained id _Nonnull receiver,
    _Nonnull SEL selector,
    void (^param)(id _Nonnull))
{
    typedef void (*funcPtr)(__unsafe_unretained id, SEL, id param);
    ((funcPtr)imp)(receiver, selector, param);
}


// -------------------------------------
BOOL addMethodThatCallsSuper(
    Class  _Nonnull __unsafe_unretained cls,
    SEL _Nonnull selector,
    const char* _Nullable types)
{
    typedef id (*funcPtr)(struct objc_super *, SEL, va_list);
    class_addMethod(
        cls,
        selector,
        imp_implementationWithBlock(
            ^(__unsafe_unretained id self, va_list argp)
            {
#if USE_MSGSENDSUPER2
                struct objc_super super = {self, cls};
                return ((funcPtr)objc_msgSendSuper2)(&super, selector, argp);
#else
                struct objc_super super = {self, class_getSuperclass(cls)};
                return ((funcPtr)objc_msgSendSuper)(&super, selector, argp);
#endif
            }
        ),
        types
    );
}
