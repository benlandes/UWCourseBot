//
//  ClassNode.h
//  CourseNotifier
//
//  Created by Ben Landes on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ClassNode : NSObject {
	NSString *className;
	NSString *section;
	NSString *type;
	NSString *sln;
	NSString *openSpots;	
}
@property (nonatomic, retain) NSString *className;
@property (nonatomic, retain) NSString *section;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *sln;
@property (nonatomic, retain) NSString *openSpots;
-(NSString *)singleLetterSection;
@end
