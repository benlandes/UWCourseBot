//
//  ClassChecker.m
//  CourseNotifier
//
//  Created by Ben Landes on 3/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClassChecker.h"


@implementation ClassChecker
@synthesize enrollmentSummary, openSLNField, classChoice, sectionChoice, runButton, runIndicator, lastCheck, status, classParser,
			isRunning, allClasses, searchCourse, searchSections, courseClasses, lastTimeTickWasCalled, timeSpentWaiting, changeInTime,
			webView, updateButton, removeButton, courseSections, snlOutput, sectionsToSearch, autoRegister, subCode, urlString,
			shouldSendText, shouldSendEmail, phoneNumber, email, carrier, notificationSent, dropClasses, lastAttempt, badCombinations,
			inWait, waitTill;
-(id)init{
	if (self = [super init]) {
		badCombinations = [[NSMutableArray alloc] init];
		dropClasses = [[NSMutableDictionary alloc] init];
		phoneNumber = @"";
		email = @"";
		carrier = @"";
	}
	return self;
}
- (void)dealloc {
	[webView release];
	[super dealloc];
}

@end
