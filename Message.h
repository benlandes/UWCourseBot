//
//  Message.h
//  CourseNotifier
//
//  Created by Ben Landes on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Message : NSObject {
	NSString *date;
	NSString *message;
	NSString *title;
}
@property (nonatomic, retain)NSString *date;
@property (nonatomic, retain)NSString *message;
@property (nonatomic, retain)NSString *title;
@end
