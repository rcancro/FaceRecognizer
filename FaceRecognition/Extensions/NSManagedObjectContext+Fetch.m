//
//  NSManagedObjectContext+Fetch.m
//  photoApp
//
//  Created by ricky cancro on 12/17/12.
//  Copyright (c) 2012 ricky cancro. All rights reserved.
//

#import "NSManagedObjectContext+Fetch.h"
#import <CoreData/CoreData.h>

@implementation NSManagedObjectContext(Fetch)

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName requestProperties:(NSArray *)properties distinct:(BOOL)distinct
                             withPredicate:(NSPredicate *)predicate
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:newEntityName inManagedObjectContext:self];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.resultType = NSDictionaryResultType;
    request.returnsDistinctResults = distinct;
    [request setEntity:entity];
    request.propertiesToFetch = properties;
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [self executeFetchRequest:request error:&error];
    if (error != nil)
    {
        [NSException raise:NSGenericException format:@"%@",[error localizedDescription]];
    }
    
    return [NSSet setWithArray:results];}


- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                       withPredicate:(NSPredicate *)predicate
{
    return [self fetchObjectsForEntityName:newEntityName fetchLimit:0 withPredicate:predicate];
}

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName fetchLimit:(int)limit withPredicate:(NSPredicate *)predicate
{
    return [NSSet setWithArray:[self fetchObjectsForEntityName:newEntityName fetchLimit:limit withPredicate:predicate sortDescriptors:nil]];
}

- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName fetchLimit:(int)limit withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)descriptors
{
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:newEntityName inManagedObjectContext:self];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setFetchLimit:limit];
    [request setPredicate:predicate];
    
    if (descriptors)
        [request setSortDescriptors:descriptors];
    
    NSError *error = nil;
    NSArray *results = [self executeFetchRequest:request error:&error];
    if (error != nil)
    {
        [NSException raise:NSGenericException format:@"%@",[error localizedDescription]];
    }
    
    return results;
}

- (id)fetchObjectForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate *)predicate
{
    NSSet *set = [self fetchObjectsForEntityName:newEntityName fetchLimit:1 withPredicate:predicate];
    if ([set count])
    {
        return [set anyObject];
    }
    return [NSNull null];
}

@end
