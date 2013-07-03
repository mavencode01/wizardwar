//
//  User.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "User.h"

@implementation User

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:@(self.friendCount) forKey:@"friendCount"];
    [encoder encodeObject:self.deviceToken forKey:@"deviceToken"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.userId = [decoder decodeObjectForKey:@"userId"];
        self.friendCount = [[decoder decodeObjectForKey:@"friendCount"] intValue];
        self.deviceToken = [decoder decodeObjectForKey:@"deviceToken"];
    }
    return self;
}

-(NSDictionary*)toObject {
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryWithValuesForKeys:@[@"name", @"userId", @"deviceToken"]]];
    if (self.location.coordinate.latitude && self.location.coordinate.longitude) {
        dict[@"location"] = @{
            @"latitude": @(self.location.coordinate.latitude),
            @"longitude": @(self.location.coordinate.longitude)
        };
    }
    return dict;
};

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    NSMutableDictionary * values = [NSMutableDictionary dictionaryWithDictionary:keyedValues];
    NSDictionary * location = values[@"location"];
    [values removeObjectForKey:@"location"];
    [super setValuesForKeysWithDictionary:values];
    self.location = [[CLLocation alloc] initWithLatitude:[location[@"latitude"] doubleValue] longitude:[location[@"longitude"] doubleValue]];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ name:%@ count:%i", super.description, self.name, self.friendCount];
}

@end
