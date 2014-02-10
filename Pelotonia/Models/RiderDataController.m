//
//  RiderDataController.m
//  Pelotonia
//
//  Created by Mark Harris on 7/13/12.
//  Copyright (c) 2012 Sandlot Software, LLC. All rights reserved.
//

#import "RiderDataController.h"
#import "PelotoniaWeb.h"

@implementation RiderDataController

@synthesize favoriteRider = _favoriteRider;

- (void)initializeDefaultList {
    NSMutableArray *defaultList = [[NSMutableArray alloc] initWithCapacity:1];
    _riderList = defaultList;
}


- (id)init 
{
    if (self = [super init]) {
        [self initializeDefaultList];
        return self;
    }
    return nil;
}

- (Rider *)favoriteRider
{
    Rider *r = [[Rider alloc] initWithName:@"Mark Harris" andId:@"MH0015"];
    r.profileUrl = @"https://www.mypelotonia.org/riders_profile.jsp?MemberID=4111";
    return r;
}


- (NSArray *)allRiders
{
    return _riderList;
}

- (unsigned)count
{
    return [_riderList count];
}

- (Rider *)objectAtIndex:(NSUInteger)index
{
    return [_riderList objectAtIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_riderList removeObjectAtIndex:index];
}

- (void)removeObject:(Rider *)object
{
    if ([object.riderId length] > 0) {
        [_riderList filterUsingPredicate:[NSPredicate predicateWithFormat:@"not riderId like %@", object.riderId]];
    }
    else {
        // it's a peloton, and they don't have riderId's, so we have to use the name
        [_riderList filterUsingPredicate:[NSPredicate predicateWithFormat:@"not name like %@", object.name]];
    }
}

- (BOOL)containsRider:(Rider *)object
{
    NSArray *filtered = nil;
    if ([object.riderId length] > 0) {
        filtered = [_riderList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"riderId like %@", object.riderId]];
    }
    else {
        // it's a peloton, and they don't have riderId's, so we have to use the name
        filtered = [_riderList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name like %@", object.name]];
    }
    return [filtered count] > 0;
}

- (void)addObject:(Rider *)object
{
        [_riderList addObject:object];
}

- (void)insertObject:(Rider *)object atIndex:(NSUInteger)index
{
    [_riderList insertObject:object atIndex:index];
}

- (void)sortRidersUsingDescriptors:(NSArray *)descriptors
{
    [_riderList sortUsingDescriptors:descriptors];
}

// Archive methods
#pragma mark -- Archive methods
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_riderList forKey:@"rider_list"];
    [aCoder encodeObject:_favoriteRider forKey:@"favorite_rider"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    // for each archived instance variable, we decode it
    // and pass it to the setters.
    if (self = [super init]) {
        _riderList = [aDecoder decodeObjectForKey:@"rider_list"];
        _favoriteRider = [aDecoder decodeObjectForKey:@"favorite_rider"];
    }
    
    return self;
}


@end
