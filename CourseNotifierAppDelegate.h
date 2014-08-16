//
//  CourseNotifierAppDelegate.h
//  CourseNotifier
//
//  Created by Ben Landes on 3/5/11.
//  Copyright 2011 Ben Landes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "HTMLParser.h"
#import "ClassNode.h"
#import "ClassChecker.h"
#import "Message.h"



#define CHECKING_CONNECTION 0
#define ACTIVATION 1
#define IN_APP 2
#define STATIC 3


@interface CourseNotifierAppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource> {

    NSWindow *window;
	IBOutlet NSWindow *messageCenter;
	IBOutlet NSWindow *advancedSettings;
	IBOutlet NSTableView *messageTableView;
	IBOutlet NSTextView *messageTextView;
	
	BOOL quiteWithoutDialoge;
	
	//UI 1
	IBOutlet NSPopUpButton *classChoice1;
	IBOutlet NSPopUpButton *sectionChoice1;
	IBOutlet NSButton *runButton1;
	IBOutlet NSProgressIndicator *runIndicator1;
	IBOutlet NSTextField *lastCheck1;
	IBOutlet NSTextField *status1;
	IBOutlet NSButton *updateButton1;
	IBOutlet NSButton *removeButton1;
	IBOutlet NSButton *autoRegister1;
	IBOutlet NSTextField *subCode1;

	//UI 2
	IBOutlet NSPopUpButton *classChoice2;
	IBOutlet NSPopUpButton *sectionChoice2;
	IBOutlet NSButton *runButton2;
	IBOutlet NSProgressIndicator *runIndicator2;
	IBOutlet NSTextField *lastCheck2;
	IBOutlet NSTextField *status2;
	IBOutlet NSButton *updateButton2;
	IBOutlet NSButton *removeButton2;
	IBOutlet NSButton *autoRegister2;
	IBOutlet NSTextField *subCode2;
	
	//UI 3
	IBOutlet NSPopUpButton *classChoice3;
	IBOutlet NSPopUpButton *sectionChoice3;
	IBOutlet NSButton *runButton3;
	IBOutlet NSProgressIndicator *runIndicator3;
	IBOutlet NSTextField *lastCheck3;
	IBOutlet NSTextField *status3;
	IBOutlet NSButton *updateButton3;
	IBOutlet NSButton *removeButton3;
	IBOutlet NSButton *autoRegister3;
	IBOutlet NSTextField *subCode3;
	
	//Advanced Settings
	NSMutableDictionary *advancedDropClasses;
	ClassChecker *advancedChecker;
	IBOutlet NSTextField *cellPhone;
	IBOutlet NSTextField *email;
	IBOutlet NSButton *sendText;
	IBOutlet NSButton *sendEmail;
	IBOutlet NSPopUpButton *carrier;
	IBOutlet NSTableView *dropClasses;
	
	//For checking time out
	double actLastTimeTickWasCalled;
	double actTimeSpentWaiting;
	double actChangeInTime;
	
	NSMutableArray *connectionQueue;
	//Checkers
	NSMutableArray *checkerArray;
	ClassChecker *checker1;
	ClassChecker *checker2;
	ClassChecker *checker3;
	
	//Current Registration Information
	NSMutableArray *currentClasses;
	NSMutableArray *messages;
	
	//Userinfo
	NSString* username;
	NSString* password;

	//Main Web View
	WebView* updateWebView;
	IBOutlet WebView* webView;
	IBOutlet NSProgressIndicator* mainIndicator;
	BOOL hasLoggedIn;
	
	//SNL Field
	IBOutlet NSTextView *availableSLNs;
	
	//Login attempts
	int loginAttempts;
	
	//Timer
	NSTimer * timer;
	NSTimer * activationTimer;
	double lastRequest;
	
	//Speech Synthesizer
	NSSpeechSynthesizer* speechSynth;
    
    //Randomize wait time
    int queueWaitTime;
}
@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet WebView* webView;
-(int)indexInWait:(ClassChecker*)checker;
-(IBAction)listButtonPressed:(id)sender;
-(IBAction)updateButtonPressed:(id)sender;
-(IBAction)removeSectionPressed:(id)sender;
-(IBAction)classSelectionChange:(id)sender;
-(IBAction)runButtonPressed:(id)sender;
-(IBAction)homeButtonPressd:(id)sender;
-(IBAction)showHideMessageCenter:(id)sender;
-(IBAction)messageClearButtonPressed:(id)sender;

//Advanced Settings
-(IBAction)configureAdvancedSettingsPressed:(id)sender;
-(IBAction)saveAndClosePressed:(id)sender;
-(IBAction)cancelPressed:(id)sender;
-(IBAction)setAllNotificationPressed:(id)sender;



-(void)loadRequestForChecker:(ClassChecker*)currentChecker;
-(NSString*)getFirstEnteredSLN;
-(void)uncheckBoxes;
-(NSString*)getSLNforClassNumber:(int) i;
-(void)restoreDefaultNotification;
-(void)clearSLNs;
-(void)getCurrentClassSchedule;
-(void)storeLogin;
-(void)updateSLNOutput;
-(void)fillSLNTextBox:(NSString *)str;
-(void)addClassNamesToPopup:(ClassChecker *)currentChecker;
-(void)addSectionNamesToPopup:(ClassChecker *)currentChecker;
-(void)checkLoad:(ClassChecker *)currentChecker;
-(void)attemptLoginInView:(WebView *)view;
@end
