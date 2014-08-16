//
//  ClassNode.m
//  CourseNotifier
//
//  Created by Ben Landes on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClassNode.h"


@implementation ClassNode
@synthesize className, type, sln, section, openSpots;
-(NSString *)singleLetterSection{
	return [section substringToIndex:1];
}
- (BOOL)isEqual:(id)anObject{
	if ([sln isEqualToString:[anObject sln]]) {
		return YES;
	}
	else {
		return NO;
	}
}
- (NSUInteger)hash{
	return [sln intValue];
}
- (void)dealloc {
	[className release];
	className = nil;
	[type release];
	type = nil;
	[sln release];
	sln = nil;
	[section release];
	section = nil;
	[openSpots release];
	openSpots = nil;
	[super dealloc];
}
@end
