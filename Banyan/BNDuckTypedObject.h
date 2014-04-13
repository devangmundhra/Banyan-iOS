//
//  BNDuckTypedObject.h
//  Banyan
//
//  Created by Devang Mundhra on 11/3/13.
//  Copied from FBGraphObject
//

#import <Foundation/Foundation.h>

@protocol BNDuckTypedObject<NSObject>
/*!
 @method
 @abstract
 Returns the number of properties on this `BNDuckTypedObject`.
 */
- (NSUInteger)count;
/*!
 @method
 @abstract
 Returns a property on this `BNDuckTypedObject`.
 
 @param aKey        name of the property to return
 */
- (id)objectForKey:(id)aKey;
/*!
 @method
 @abstract
 Returns an enumerator of the property naems on this `BNDuckTypedObject`.
 */
- (NSEnumerator *)keyEnumerator;
/*!
 @method
 @abstract
 Removes a property on this `BNDuckTypedObject`.
 
 @param aKey        name of the property to remove
 */
- (void)removeObjectForKey:(id)aKey;
/*!
 @method
 @abstract
 Sets the value of a property on this `BNDuckTypedObject`.
 
 @param anObject    the new value of the property
 @param aKey        name of the property to set
 */
- (void)setObject:(id)anObject forKey:(id)aKey;

@end

/*!
 @class
 
 @abstract
 Static class with helpers for use with duck-typed objects
 */
@interface BNDuckTypedObject : NSMutableDictionary<BNDuckTypedObject>

/*!
 @method
 @abstract
 Used to create a graph object, usually for use in posting a new graph object or action.
 */
+ (NSMutableDictionary<BNDuckTypedObject>*)duckTypedObject;

/*!
 @method
 @abstract
 Used to wrap an existing dictionary with a `BNDuckTypedObject` facade
 
 @param jsonDictionary              the dictionary representing the underlying object to wrap
 */
+ (NSMutableDictionary<BNDuckTypedObject>*)duckTypedObjectWrappingDictionary:(NSDictionary*)jsonDictionary;

/*!
 @method
 @abstract
 Used to compare two `BNDuckTypedObject`s to determine if represent the same object. We do not overload
 the concept of equality as there are various types of equality that may be important for an `BNDuckTypedObject`
 (for instance, two different `BNDuckTypedObject`s could represent the same object, but contain different
 subsets of fields).
 
 @param anObject          an `BNDuckTypedObject` to test
 
 @param anotherObject     the `BNDuckTypedObject` to compare it against
 */
+ (BOOL)isDuckTypedObjectID:(id<BNDuckTypedObject>)anObject sameAs:(id<BNDuckTypedObject>)anotherObject;


@end
