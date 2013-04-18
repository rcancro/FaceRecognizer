//
//  NSManagedObjectContext+Fetch.h
//  photoApp
//
//  Created by ricky cancro on 12/17/12.
//  Copyright (c) 2012 ricky cancro. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext(Fetch)

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName requestProperties:(NSArray *)properties distinct:(BOOL)distinct withPredicate:(NSPredicate *)predicate;

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate *)predicate;
- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName fetchLimit:(int)limit withPredicate:(NSPredicate *)predicate;
- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName fetchLimit:(int)limit withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)descriptors;

- (id)fetchObjectForEntityName:(NSString *)newEntityName  withPredicate:(NSPredicate *)predicate;
@end
