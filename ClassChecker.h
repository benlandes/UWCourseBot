//
//  ClassChecker.h
//  CourseNotifier
//
//  Created by Ben Landes on 3/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "HTMLParser.h"

@interface ClassChecker : NSObject {
	
	//GUI Variables
	NSButton *autoRegister;
	NSTextField *subCode;
	NSTextField *enrollmentSummary;
	NSTextField *openSLNField;
	NSPopUpButton *classChoice;
	NSPopUpButton *sectionChoice;
	NSButton *runButton;
	NSButton *updateButton;
	NSButton *removeButton;
	NSProgressIndicator *runIndicator;
	NSTextField *lastCheck;
	NSTextField *status;
	WebView* webView;
	
	//Other Stuff
	HTMLParser *classParser;
	BOOL isRunning;
	NSString *snlOutput;
	NSString *urlString;
	
	//For checker setup
	NSMutableArray *allClasses;
	NSString *searchCourse;
	NSMutableArray *searchSections;
	NSMutableDictionary *sectionsToSearch;
	
	//For checker runner
	NSMutableDictionary *courseSections;
	NSMutableDictionary *courseClasses;
	
	//For dropping classes
	NSMutableDictionary *dropClasses;
	
	//Notification
	BOOL notificationSent;
	BOOL shouldSendText;
	BOOL shouldSendEmail;
	NSString *phoneNumber;
	NSString *carrier;
	NSString *email;
	
	//Tick Variables
	BOOL inWait;
	float waitTill;
	double lastTimeTickWasCalled;
	double timeSpentWaiting;
	double changeInTime;
	
	//Registration Attempt variables
	NSString *lastAttempt;
	NSMutableArray *badCombinations;
	
}
@property (nonatomic, retain) NSTextField *enrollmentSummary;
@property (nonatomic, retain) NSTextField *openSLNField;
@property (nonatomic, retain) NSPopUpButton *classChoice;
@property (nonatomic, retain) NSPopUpButton *sectionChoice;
@property (nonatomic, retain) NSButton *runButton;
@property (nonatomic, retain) NSProgressIndicator *runIndicator;
@property (nonatomic, retain) NSTextField *lastCheck;
@property (nonatomic, retain) NSTextField *status;
@property (nonatomic, retain) HTMLParser *classParser;
@property (nonatomic, retain) NSMutableArray *allClasses;
@property (nonatomic, retain) NSString *searchCourse;
@property (nonatomic, retain) NSMutableArray *searchSections;
@property (nonatomic, retain) NSMutableDictionary *courseClasses;
@property (nonatomic, retain) NSMutableDictionary *courseSections;
@property (nonatomic, retain) NSMutableDictionary *sectionsToSearch;
@property (nonatomic, retain) WebView* webView;
@property (nonatomic, retain) NSButton *updateButton;
@property (nonatomic, retain) NSButton *removeButton;
@property (nonatomic, retain) NSString *snlOutput;
@property (nonatomic, retain) NSButton *autoRegister;
@property (nonatomic, retain) NSTextField *subCode;
@property (nonatomic, retain) NSString *urlString;
@property (nonatomic, retain) NSMutableDictionary *dropClasses;
@property BOOL isRunning;
@property BOOL inWait;
@property float waitTill;
@property double lastTimeTickWasCalled;
@property double timeSpentWaiting;
@property double changeInTime;
@property BOOL shouldSendText;
@property BOOL shouldSendEmail;
@property (nonatomic, retain) NSString *phoneNumber;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *carrier;
@property BOOL notificationSent;
@property (nonatomic, retain) NSString *lastAttempt;
@property (nonatomic, retain) NSMutableArray *badCombinations;

//temporary
-(NSDictionary*)getCheckerDictionary;
-(void)setCheckerDictionary:(NSDictionary*)dict;




@end
