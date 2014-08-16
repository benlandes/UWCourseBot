//
//  CourseNotifierAppDelegate.m
//  CourseNotifier
//
//  Created by Ben Landes on 3/5/11.
//  Copyright 2011 Ben Landes. All rights reserved.
//

#import "CourseNotifierAppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <Carbon/Carbon.h>
#import <IOKit/IOBSD.h>
#include <stdlib.h>


@implementation CourseNotifierAppDelegate

@synthesize window, webView;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
	if (quiteWithoutDialoge) {
		return YES;
	}
    for(ClassChecker *currentChecker in checkerArray){
		if (currentChecker.isRunning == YES) {
            int returnValue = NSRunAlertPanel(@"Quit", @"UW Course Bot is currently checking for open slots are you sure you want to quit?", @"No", @"Yes", nil);
            if (returnValue == 1) {
                return NO;
            }
            else {
                //Delete All Cookies so login information is cleared
                NSEnumerator*   enumerator;
                NSHTTPCookie*   cookie;
                enumerator = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] objectEnumerator];
                while (cookie = [enumerator nextObject]) {
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
                }
                [enumerator release];
                [cookie release];
                
                return YES;
            }
        }
    }
    return NO;
}
				   
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	
	//Coneection Queue Intialization
	connectionQueue = [[NSMutableArray alloc] init];
	
	//Create three checker objects and an array to hold them
	checkerArray = [[NSMutableArray alloc] init];
	checker1 = [[ClassChecker alloc] init];
	checker2 = [[ClassChecker alloc] init];
	checker3 = [[ClassChecker alloc] init];
	[checkerArray addObject:checker1];
	[checkerArray addObject:checker2];
	[checkerArray addObject:checker3];
	
	
	//Pass interface objects to the three checker objects
	checker1.classChoice =  classChoice1;
	checker1.sectionChoice =  sectionChoice1;
	checker1.runButton = runButton1;
	checker1.runIndicator = runIndicator1;
	checker1.lastCheck = lastCheck1;
	checker1.status = status1;
	checker1.updateButton = updateButton1;
	checker1.removeButton = removeButton1;
	checker1.subCode = subCode1;
	checker1.autoRegister = autoRegister1;
	
	checker2.classChoice =  classChoice2;
	checker2.sectionChoice =  sectionChoice2;
	checker2.runButton = runButton2;
	checker2.runIndicator = runIndicator2;
	checker2.lastCheck = lastCheck2;
	checker2.status = status2;
	checker2.updateButton = updateButton2;
	checker2.removeButton = removeButton2;
	checker2.subCode = subCode2;
	checker2.autoRegister = autoRegister2;
	
	checker3.classChoice =  classChoice3;
	checker3.sectionChoice =  sectionChoice3;
	checker3.runButton = runButton3;
	checker3.runIndicator = runIndicator3;
	checker3.lastCheck = lastCheck3;
	checker3.status = status3;
	checker3.updateButton = updateButton3;
	checker3.removeButton = removeButton3;
	checker3.subCode = subCode3;
	checker3.autoRegister = autoRegister3;
	
	//Set web view delegate
	[webView setFrameLoadDelegate:self];
	
	for(ClassChecker *temp in checkerArray){
		// Insert code here to initialize your application 
		temp.allClasses = [[NSMutableArray alloc] init];
		temp.searchSections = [[NSMutableArray alloc] init];
		temp.sectionsToSearch = [[NSMutableDictionary alloc] init];
		temp.courseClasses = [[NSMutableDictionary alloc] init];
		temp.courseSections = [[NSMutableDictionary alloc] init];
		[temp.sectionChoice removeAllItems];
		[temp.classChoice removeAllItems];
		
	}
	
	//Setup Timers For checkers and to make sure connections don't time out and to update last check time.
	timer = [NSTimer scheduledTimerWithTimeInterval:.25 target:self selector:@selector(tick) userInfo:nil repeats:YES]; //Retains target in this case it is gamemode
	
		


	// Random setting of delegates
	[webView setFrameLoadDelegate:self];
	[webView setResourceLoadDelegate:self];
	[window setDelegate:self];
	[messageCenter setDelegate:self];
	
	
	//Create an array of messages for the message center
	messages = [[NSMutableArray alloc] init];
	
	//Create an array to use to hold the droped classes for the advanced settings window
	//until they are saved to the disignated checker
	advancedDropClasses = [[NSMutableDictionary alloc] init];
	
	//Initialize speech synthesizer to notify user of class Openings
	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	
	//Bring up login window so user can login.
	NSURL *registrationURL = [[NSURL alloc] initWithString:@"https://sdb.admin.washington.edu/students/uwnetid/register.asp"];
	NSURLRequest *registrationRequest = [[NSURLRequest alloc] initWithURL:registrationURL];
	[[webView mainFrame] loadRequest:registrationRequest];
	[registrationURL release];
	[registrationRequest release];
	
	//Startup indicators
	[mainIndicator setIndeterminate:NO];
	[mainIndicator startAnimation:self];
	
	//Check for updates
    //Endpoint No Longer Active
    /*
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *urlToAuthPage = [[NSString alloc] initWithFormat:@"&version=%@", version];
	NSData *postData = [urlToAuthPage dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
	NSString *postLength = [NSString stringWithFormat:@"%d",[urlToAuthPage length]];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://benlandes.com/uwcoursebot/updatecheck.php"]]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	updateWebView = [[WebView alloc] init];
	[updateWebView setFrameLoadDelegate:self];
	[[updateWebView mainFrame] loadRequest:request];
	[urlToAuthPage release];
     */
}


//Called about every .25 second{
-(void)tick{
	
	
	//Show loading progress
	[mainIndicator setDoubleValue:[webView estimatedProgress]];
				  
	for(ClassChecker *currentChecker in checkerArray){
		
		// Do nothing if checker isn't running
		if (currentChecker.isRunning == YES) {
			
			//Update last Checked time in GUI
			[currentChecker.lastCheck setStringValue:[NSString stringWithFormat:@"%i seconds ago",(int)(currentChecker.timeSpentWaiting)]];
			
			double time = CFAbsoluteTimeGetCurrent(); // this gets the current time in milliseconds
			
			//TimeSpentWaiting is time spent waiting for a webpage to load
			//changeInTime is the change in time between ticks and is added each tick to TimeSpentWaiting
			
			// find how much time has passed since last tick
			if (currentChecker.lastTimeTickWasCalled == 0 ) {
				// 0 means its the first time this is called
				currentChecker.changeInTime = 0;
			}
			else {
				currentChecker.changeInTime = time - currentChecker.lastTimeTickWasCalled;
			}
			
			// add to our time that we have been waiting
			currentChecker.timeSpentWaiting += currentChecker.changeInTime;
			
			//Loading times out at 30 seconds stop load and reload if loading takes over 40.0 Seconds
			if ([self indexInWait:currentChecker] == -1 && currentChecker.timeSpentWaiting >= 30.0) {
				[connectionQueue addObject:currentChecker];
				[currentChecker.status setStringValue:@"Request Timed Out"];
			}
			
			//Set Last tick to current time
			currentChecker.lastTimeTickWasCalled = time;
		}
	}
	
	double time = CFAbsoluteTimeGetCurrent(); // this gets the current time in seconds
	
	//Manages Connection Queue
	if (time >= lastRequest + queueWaitTime && [connectionQueue count] >= 1) {
		ClassChecker *currentChecker = [connectionQueue objectAtIndex:0];
		[connectionQueue removeObjectAtIndex:0];
		currentChecker.inWait = NO;
		lastRequest = time;
		[self loadRequestForChecker:currentChecker];
        
        //Set a random wait time for the next request (1 - 10 minutes)
        //queueWaitTime = 15 + (10 * (arc4random() % 60));
        queueWaitTime = 10;
	}
	
}
- (void) someMethodDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertFirstButtonReturn)
	{

	}

}
#pragma mark Web View delegate methods
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
    
	//If page loading is log in screen attempt to remember password
	if ( [[[request URL] absoluteString] isEqualToString:@"https://weblogin.washington.edu/" ]) {
		[self storeLogin];
	}
    return request;
}

//Delegate method that is called once a webpage has finished loading
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{
	NSString *htmlText = [sender stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
	if (hasLoggedIn && [htmlText rangeOfString:@"Login gives you 8-hour access without repeat login to UW NetID-protected Web resources." options: 
		 NSCaseInsensitiveSearch].length != 0) {
		
		[self attemptLoginInView:sender];
		return;
		
	}
	if(sender ==updateWebView){
		//Get HTML of page and create a parser to check results
		//NSError * error = nil;
		HTMLParser *parser = [(HTMLParser*)[HTMLParser alloc] initWithString:htmlText error:nil];
		HTMLNode *bodyNode = [parser body];
		
		//Store results in strings
		NSString *message = [[bodyNode findChildTag:@"message"] contents];
		NSString *result = [[bodyNode findChildTag:@"result"] contents];
		NSString *downloadUrl = [[bodyNode findChildTag:@"url"] contents];
		
		
		if ([result isEqualToString:@"YES"]) {
			int returnValue = NSRunAlertPanel(@"New Version Available", message, @"Update Now", @"Later", nil);
			if (returnValue == 1) {
				
				NSURL *url = [ [ NSURL alloc ] initWithString: downloadUrl];
				[[NSWorkspace sharedWorkspace] openURL:url];
				[url release];
			}
		}
		[parser release];
	}
	else if (sender == webView) {
		//Abort if not registration page
		if ([[[[[[sender mainFrame]dataSource]request] URL] absoluteString] isEqualToString:@"https://sdb.admin.washington.edu/students/uwnetid/register.asp" ]) {
			
			[self getCurrentClassSchedule];
			if ([currentClasses count] != 0) {
				hasLoggedIn = YES;
				
			}
            
			[dropClasses reloadData];
			
			if ([htmlText rangeOfString:@"Schedule updated." options: NSCaseInsensitiveSearch].length != 0) {
				for(ClassChecker *checker in checkerArray){
					if (checker.lastAttempt != nil) {
						NSArray *slns = [checker.lastAttempt componentsSeparatedByString:@":"];
						BOOL found = NO;
						
						
						for(int i = 0; i < [currentClasses count]; i++){
							if ([[[currentClasses objectAtIndex:i] sln]isEqualToString:[slns objectAtIndex:0]] ) {
								found = YES;
							}
						}
						if (found) {
							if (checker.isRunning) {
								[self runButtonPressed:checker.runButton];
							}
							[checker.status setStringValue:@"Successfully Registered"];
						
							Message *newMessage = [[Message alloc] init];
							newMessage.title = [NSString stringWithFormat:@"%@ successful registration",checker.searchCourse];
							newMessage.message = [NSString stringWithFormat:@"UW Course Bot successfully registered for %@ with sln(s): %@",checker.searchCourse, checker.lastAttempt];
							NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
							[formatter setDateFormat:@"HH:mm"];
							newMessage.date = [formatter stringFromDate:[NSDate date]];
							[formatter release];
							[messages addObject:newMessage];
							[newMessage release];
							[messageTableView reloadData];
							
							checker.lastAttempt = nil;
							break;
						}
					}
				}
			}
			else if ([htmlText rangeOfString:@"Schedule not updated." options: NSCaseInsensitiveSearch].length != 0) {
				for(ClassChecker *checker in checkerArray){
					NSString *firstSLN = [self getFirstEnteredSLN];
					if (checker.lastAttempt != nil) {
						NSArray *slns = [checker.lastAttempt componentsSeparatedByString:@":"];
						if ([firstSLN isEqualToString:[slns objectAtIndex:0]] ) {
							[checker.status setStringValue:@"Failed Registration"];
							[checker.badCombinations addObject:checker.lastAttempt];
							Message *newMessage = [[Message alloc] init];
							newMessage.title = [NSString stringWithFormat:@"%@ failed registration",checker.searchCourse];
							newMessage.message = [NSString stringWithFormat:@"UW Course Bot could not registered for %@ with sln(s): %@. This may be for a variety of reasons such as an add code being required, time conflict, software error, etc... The combination was added to a bad combination list and Course Bot will continue searching for a class combination that works.",checker.searchCourse, checker.lastAttempt];
							NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
							[formatter setDateFormat:@"HH:mm"];
							newMessage.date = [formatter stringFromDate:[NSDate date]];
							[formatter release];
							[messages addObject:newMessage];
							[newMessage release];
							[messageTableView reloadData];
							
							break;
						}
					}
				}
			}
		}
	}
	else if(sender == checker1.webView || sender == checker2.webView || sender == checker3.webView){
				
		ClassChecker *currentChecker;
		if (checker1.webView == sender) {
			currentChecker = checker1;
		}
		else if (checker2.webView == sender){
			currentChecker = checker2;
		}
		else {
			currentChecker = checker3;
		}

		//NSError * error = nil;
		if(currentChecker.classParser != nil) {
			[currentChecker.classParser release];
			currentChecker.classParser = nil;
		}
		currentChecker.classParser = [(HTMLParser*)[HTMLParser alloc] initWithString:htmlText error:nil];
		
		HTMLNode * bodyNode = [currentChecker.classParser body];
		NSArray *tableNodes = [bodyNode findChildTags:@"table"]; //Course Information should be in 5th table
		
		
		
		if ([tableNodes count] == 7) { // To avoid redirect Pages
			NSArray *tableRows = [[tableNodes objectAtIndex:4] findChildTags:@"tr"];
			
			
			for(HTMLNode *node in tableRows){
				NSArray *children = [node children];
				if ([children count] > 20) {
					
					//If checker is running use setup data to filter out unwanted data
					if (currentChecker.isRunning) {
						
						//Make sure the user left the section to be searched
						
						if ([[[children objectAtIndex:2] contents] isEqualToString:currentChecker.searchCourse] && 
							[currentChecker.sectionsToSearch objectForKey:[[children objectAtIndex:4] contents]] != nil ) {
							
							ClassNode *temp = [[ClassNode alloc] init];
							NSArray *slnA = [[children objectAtIndex:0] children];
							temp.sln = [[slnA objectAtIndex:0] contents];//SLN
							temp.className = [[children objectAtIndex:2] contents]; //course
							temp.section = [[children objectAtIndex:4] contents];//Section
							temp.type = [[children objectAtIndex:6] contents]; //Type
							temp.openSpots = [[[children objectAtIndex:16] contents] stringByTrimmingCharactersInSet:
											  [NSCharacterSet whitespaceAndNewlineCharacterSet]]; 
							NSMutableDictionary *tempDict = [currentChecker.courseSections objectForKey:[temp singleLetterSection]];
							NSMutableArray *tempArray = [tempDict objectForKey:temp.type];
							[tempArray addObject:temp];
							[temp release];
							temp = nil;
						}
						
					}
					else {
						ClassNode *temp = [[ClassNode alloc] init];
						NSArray *slnA = [[children objectAtIndex:0] children];
						temp.sln = [[slnA objectAtIndex:0] contents];//SLN
						temp.className = [[children objectAtIndex:2] contents]; //course
						temp.section = [[children objectAtIndex:4] contents];//Section
						temp.type = [[children objectAtIndex:6] contents]; //Type
						temp.openSpots = [[children objectAtIndex:16] contents]; //Space Avaliable
						[currentChecker.allClasses addObject:temp];
						[temp release];
						temp = nil;
					}
				}
			}
			
			//If checker is still running check for open classes and reload the page to check again
			if (currentChecker.isRunning) {
				
				//Check Results of Load
				
				[self checkLoad:currentChecker];
				
				//Load web request
				//NSLog(@"Index:%i",[self indexInWait:currentChecker]);
				if ([self indexInWait:currentChecker]==-1) {
					[connectionQueue addObject:currentChecker];
				}
				
			}
			else {
				[self addClassNamesToPopup:currentChecker];
			}
		}
	}
}
#pragma mark TableView Methods
- (void) tableViewSelectionDidChange: (NSNotification *) notification
{	
	if ([notification object] == messageTableView) {
		if ([messageTableView selectedRow] >= 0) {
			[messageTextView setString:[[messages objectAtIndex:[messageTableView selectedRow]]message]];
		}
		else {
			[messageTextView setString:@""];
		}
	}
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == messageTableView) {
		return [messages count];
	}
	else {
		return [currentClasses count];
	}

    
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == messageTableView) {
		if ([[aTableColumn identifier] isEqualToString:@"Title"]) {
			return [[messages objectAtIndex:rowIndex] title];
		}
		else if ([[aTableColumn identifier] isEqualToString:@"Message"]) {
			return [[messages objectAtIndex:rowIndex] message];
		}
		else {
			return [[messages objectAtIndex:rowIndex] date];
		}
	}
	else {
		if ([[aTableColumn identifier] isEqualToString:@"Class"]) {
			return [[currentClasses objectAtIndex:rowIndex] className];
		}
		else {
			BOOL value = (nil != [advancedDropClasses objectForKey:[[currentClasses objectAtIndex:rowIndex] sln]]);
			return [NSNumber numberWithInteger:(value ? NSOnState : NSOffState)];
		}

	}

}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row {  
	if (![[column identifier] isEqualToString:@"Class"]) {
		BOOL val = [value boolValue];
		if (val) {
			
			[advancedDropClasses setObject:[currentClasses objectAtIndex:row] forKey:[[currentClasses objectAtIndex:row] sln]];
		}
		else {
			if ([advancedDropClasses objectForKey:[[currentClasses objectAtIndex:row] sln]] != nil) {
				[advancedDropClasses removeObjectForKey:[[currentClasses objectAtIndex:row] sln]];
			}
		}

	}
	
}


#pragma mark Javascript Methods
//Unchecks all Drop class check boxes
-(void)uncheckBoxes{
	[self getCurrentClassSchedule];
	for(int i = 1; i <= [currentClasses count]; i++){
		[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"function f(){var name; var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name == \"action%i\" && inputArray[i].value == 'D'){inputArray[i].checked = false;} }  return name; } f();",i]];
	}
}

//returns the sln for the the row that the class is placed in on the registration page
-(NSString*)getSLNforClassNumber:(int) i{
	NSString *valueName = [NSString stringWithFormat:@"sln%i",i];
	return [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"function f(){var name; var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name == \"%@\"){name = inputArray[i].value;} }  return name; } f();",valueName]];
}

//Get first entered sln number
-(NSString*)getFirstEnteredSLN{
	[self getCurrentClassSchedule];
	NSString *valueName = [NSString stringWithFormat:@"sln%i",[currentClasses count] + 1];
	return [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"function f(){var name; var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name == \"%@\"){name = inputArray[i].value;} }  return name; } f();",valueName]];
}

//Checks the drop box for the designated sln passed in
-(void)checkBoxWithSLN:(NSString *)string{
	[self getCurrentClassSchedule];
	int classNumber = 0;
	for(int i = 1; i <= [currentClasses count]; i++){
		if ([[[currentClasses objectAtIndex:i-1] sln] isEqualToString:string]) {
			classNumber = i;
		}
	}
	NSString *checkBoxName = [NSString stringWithFormat:@"action%i",classNumber];
	[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"function f(){var name; var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name == \"%@\" && inputArray[i].value == 'D'){inputArray[i].checked = true;} }  return name; } f();",checkBoxName]];
}

//This method will fill the next avaliable snl text box with the passed SLN
-(void)fillSLNTextBox:(NSString *)str{
	NSString *string = [NSString stringWithFormat:@"var tags = document.getElementsByTagName('input'); for (var i = 0; i<tags.length; i++){if(tags[i].name.indexOf(\"sln\")==0 && tags[i].value ==\"\"){tags[i].value=\"%@\"; break;}}",str];
	[webView stringByEvaluatingJavaScriptFromString:string];
	
}
//This method clears all sln fields
-(void)clearSLNs{
	[self getCurrentClassSchedule];
	int numOfClasses = [currentClasses count];
	NSString *string = [NSString stringWithFormat:@"var tags = document.getElementsByTagName('input');var count = 0; for (var i = 0; i<tags.length; i++){if(tags[i].name.indexOf(\"sln\")==0){count++;if(count > %i){tags[i].value=\"\";}}}",numOfClasses];
	[webView stringByEvaluatingJavaScriptFromString:string];
}

//Myuw will automatically log an user out after a period of time.  This method stores the password so if course bot is logged out it can automatically log back in.
-(void)storeLogin{
	NSString *user = [NSString stringWithFormat:@"%@",[self.webView stringByEvaluatingJavaScriptFromString:@"function f(){var name ;var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name =='user'){name = inputArray[i].value;}}  return name; } f();"]];
	NSString *pass = [NSString stringWithFormat:@"%@",[self.webView stringByEvaluatingJavaScriptFromString:@"function f(){var name ;var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name =='pass'){name = inputArray[i].value;}}  return name; } f();"]];
	NSString *htmlText = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
	if ([htmlText rangeOfString:@"Login gives you 8-hour access without repeat login to UW NetID-protected Web resources." options: 
		 NSCaseInsensitiveSearch].length != 0 && ![user isEqualToString:@""]) {
		
		if (username != nil) {
			[username release];
			[password release];
			username = nil;
			password = nil;
		}
		username = [[NSString alloc] initWithString: user];
		password = [[NSString alloc] initWithString: pass];
	}
}
-(void)attemptLoginInView:(WebView *)view{
	if (loginAttempts >= 100) {
		Message *newMessage = [[Message alloc] init];
		newMessage.title = @"Auto Login Shut Off";
		newMessage.message = @"After 10 auto login attempts the autologin feature has been shut off.";
		[messages addObject:newMessage];
		[newMessage release];
		hasLoggedIn = NO;
		username = nil;
		password = nil;
		loginAttempts = 0;
		return;
	}
	else if([username isEqualToString:@"NULL"]) {
		username = nil;
		password = nil;
	}
	else {

		[view stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"function f(){var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name =='user'){inputArray[i].value = '%@'; }}  } f();",username]];
		[view stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"function f(){var inputArray = document.getElementsByTagName('input'); for (var i = 0; i<inputArray.length; i++){if(inputArray[i].name =='pass'){inputArray[i].value = '%@'; }}  } f();",password]];
		
		//Press submit button
		NSString *string = [NSString stringWithFormat:@"var divArray = document.getElementsByTagName('input'); for (var i = 0; i<divArray.length; i++){if(divArray[i].value=='Log in'){divArray[i].click();}}"];
		[view stringByEvaluatingJavaScriptFromString:string];
		
		//Add message to message center
		Message *newMessage = [[Message alloc] init];
		newMessage.title = @"Auto Login Attempted";
		newMessage.message = @"UW Course Bot was logged out while searching for classes and tried to log it self back in.";
		
		//Get date
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"HH:mm"];
		newMessage.date = [formatter stringFromDate:[NSDate date]];
		[formatter release];
		
		//Add message
		[messages addObject:newMessage];
		[newMessage release];
		[messageTableView reloadData];
		loginAttempts++;
	}	
}

#pragma mark Helper Methods
-(int)indexInWait:(ClassChecker*)checker{
	for(int i = 0; i < [connectionQueue count]; i++){
		if (checker == [connectionQueue objectAtIndex:i]) {
			return i;
		}
	}
	return -1;

}
-(void)loadRequestForChecker:(ClassChecker*)currentChecker{
	
	[currentChecker.webView stopLoading:self];
	
	currentChecker.timeSpentWaiting = 0.0;
	currentChecker.changeInTime = 0.0;
	currentChecker.lastTimeTickWasCalled = 0.0;
	
	NSURL *enrollmentURL = [[NSURL alloc] initWithString:currentChecker.urlString];
	NSURLRequest *enrollmentRequest = [[NSURLRequest alloc] initWithURL:enrollmentURL];
	[[currentChecker.webView mainFrame] loadRequest:enrollmentRequest];
	[enrollmentURL release];
	[enrollmentRequest release];
	
}
-(void)restoreDefaultNotification{
	//Load user defaults and check for a activation code
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	
	for(ClassChecker *checker in checkerArray){
		checker.email = [defaults stringForKey:@"email"];
		checker.phoneNumber = [defaults stringForKey:@"phoneNumber"];
		checker.carrier = [defaults stringForKey:@"carrier"];
		checker.shouldSendEmail = (BOOL)[defaults integerForKey:@"sendEmail"];
		checker.shouldSendText = (BOOL)[defaults integerForKey:@"sendText"];
	}
}
-(void)sendEmailBody:(NSString *)body withSubject:(NSString *)subject toAddress:(NSString *)address{
	
    /*
     //Endpoint is no longer active
	 NSString *urlToAuthPage = [[NSString alloc] initWithFormat:@"&email=%@&subject=%@&body=%@", address,subject,body];
	 NSData *postData = [urlToAuthPage dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
	 NSString *postLength = [NSString stringWithFormat:@"%d",[urlToAuthPage length]];
	 NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	 [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://benlandes.com/uwcoursebot/sendnotification.php"]]];
	 [request setHTTPMethod:@"POST"];
	 [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	 [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	 [request setHTTPBody:postData];
	 [[[NSURLConnection alloc]initWithRequest:request delegate:self]autorelease];
	[urlToAuthPage release];
     */
}
-(void)getCurrentClassSchedule{
	if ([[[[[[webView mainFrame]dataSource]request] URL] absoluteString] isEqualToString:@"https://sdb.admin.washington.edu/students/uwnetid/register.asp" ]) {
		int classCounter = 1;
		//Initialize Array if needed
		if (currentClasses == nil) {
			currentClasses = [[NSMutableArray alloc] init];
		}
		[currentClasses removeAllObjects];
		
		//Get Page Source
		NSString *htmlText = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
		
		//Create a html parser
		//NSError * error = nil;
		HTMLParser *parser = [(HTMLParser*)[HTMLParser alloc] initWithString:htmlText error:nil];
		
		//Find Table Row Tags
		HTMLNode * bodyNode = [parser body];
		NSArray *tableNodes = [bodyNode findChildTags:@"table"];
		
		for(HTMLNode *table in tableNodes){
			NSArray *tableRows = [table findChildTags:@"tr"];
			
			for(HTMLNode *node in tableRows){
				NSArray *tableColumns = [node findChildTags:@"td"];
				
				//For each class the drop box is named "action#" and has a value of D
				//If the row fits the criteria the class is added to the list of current classes
				NSString *checkName;
				NSString *checkValue;
				if ([tableColumns count] >=1) {
					
					checkName = [(HTMLNode*)[[tableColumns objectAtIndex:0] firstChild] getAttributeNamed:@"name"];
					checkValue = [(HTMLNode*)[[tableColumns objectAtIndex:0] firstChild] getAttributeNamed:@"value"];
					
					if ([checkName rangeOfString:@"action" options: NSCaseInsensitiveSearch].length != 0 && [checkValue isEqualToString:@"D"]) {
						
						//Adds class to list
						ClassNode *node = [[ClassNode alloc] init];
						node.className = [(HTMLNode*)[[tableColumns objectAtIndex:2]firstChild]contents];
						node.sln = [self getSLNforClassNumber:classCounter];
						/*node.sln = [[(HTMLNode*)[[tableColumns objectAtIndex:1]firstChild]contents]stringByTrimmingCharactersInSet:
						 [NSCharacterSet whitespaceAndNewlineCharacterSet]];*/					
						[currentClasses addObject:node ];
						[node release];
						
						classCounter++;
					}
				}
			}
		}
		
		[parser release];	
	}
}
-(void)checkLoad:(ClassChecker *)currentChecker{

	NSString *newOutput = [NSString stringWithFormat:@"%@\n",currentChecker.searchCourse];
	
	//Keep track of if class has open spots
	BOOL classHasOpenSlots = NO;
	
	//Complete List of Open Classes
	NSMutableArray * goodCombinations = [[NSMutableArray alloc] init];

	//For Each Course Section
	for(NSString *key1 in currentChecker.courseSections){
		
		BOOL hasOpenSlots = YES;
		
		//Contains types of classes for each section Ex. LC, LB, QZ
		NSMutableDictionary *sectionDictionary = [currentChecker.courseSections objectForKey:key1];
		
		//Gets any key as the base key to create combinations loop goes through once then breaks out
		//of loop.
		NSMutableArray *combinationArray = [[NSMutableArray alloc] init]; //Array of open class combinations
		for(NSString *baseKey in sectionDictionary){
			
			
			//If array is empty than there isn't a class open for the disignated section. 
			NSMutableArray *tempBaseArray = [sectionDictionary objectForKey:baseKey];
			
			if ([tempBaseArray count] == 0) {
				hasOpenSlots = NO;
				//break;
			}
			else {
				BOOL sectionHasOpen = NO;
				for(ClassNode *node in tempBaseArray){
					if ((![[node openSpots] isEqualToString:@"0"]) && (![[node openSpots] isEqualToString:@"--"])&&
						![[node openSpots] isEqualToString:@""]) {
							[combinationArray addObject:node.sln];
							sectionHasOpen = YES;
					}
				}
				if (sectionHasOpen == NO) {
					hasOpenSlots = NO;
					//break;
				}
			}
			[tempBaseArray removeAllObjects];
			
			
			//For all the other keys append open sln strings to each previous section 
			for(NSString *key in sectionDictionary){
				if (key != baseKey) {
					
					//If array is empty than there isn't a class open for the disignated section. 
					NSMutableArray *tempChildrenArray = [sectionDictionary objectForKey:key];
					if ([tempChildrenArray count] == 0) {
						hasOpenSlots = NO;
						//break;
					}
					else {
						
						//Go through current combination strings and for each one add remove it and add it again
						//with all possible next combinations.
						for(int i = [combinationArray count] - 1; i >=0; i--){
							BOOL sectionHasOpen = NO;
							NSString *tempCombo = [combinationArray objectAtIndex:i];
							[combinationArray removeObjectAtIndex:i];
							for(ClassNode *node in tempChildrenArray){
								if ((![[node openSpots] isEqualToString:@"0"]) && (![[node openSpots] isEqualToString:@"--"]) &&
									![[node openSpots] isEqualToString:@""] ) {
									[combinationArray insertObject:[NSString stringWithFormat:@"%@:%@",tempCombo,node.sln] atIndex:i];
									sectionHasOpen = YES;
								}
							}
							if (sectionHasOpen == NO) {
								hasOpenSlots = NO;
								//break;
							}
						}
					}
					[tempChildrenArray removeAllObjects];
				}
			}
			break;
		}
		
		for(int i = 0; i < [combinationArray count]; i++){
			BOOL good = YES;
			for(NSString *badCombo in currentChecker.badCombinations){
				if ([badCombo isEqualToString:[combinationArray objectAtIndex:i]]) {
					NSString *newString = [NSString stringWithFormat:@"%@ Bad Combo", badCombo];
					[combinationArray removeObjectAtIndex:i];
					[combinationArray insertObject:newString atIndex:i];
					good = NO;
				}
			}
			if (good) {
				[goodCombinations addObject:[combinationArray objectAtIndex:i]];
			}
		}
		
		
		if (hasOpenSlots) {
			newOutput =  [NSString stringWithFormat:@"%@Section %@: Open combinations!\n",newOutput,key1];
			classHasOpenSlots = YES;
			for(NSString *string in combinationArray){
				newOutput =  [NSString stringWithFormat:@"%@   %@\n",newOutput,string];
			}
			
		}
		else {
			newOutput =  [NSString stringWithFormat:@"%@Section %@: No open combinations\n",newOutput,key1];
		}
	
		[combinationArray release];
		combinationArray = nil;
	}
	
	
	
	//If class has open slots notify user
	if (classHasOpenSlots) {
		
		//Automatically register for classes is auto register is checked
		//If schedule update successful "Schedule updated." should appear in the html code
		if ([currentChecker.autoRegister state] == 1 && [goodCombinations count] >= 1) {
			
			//clear any entered slns if any
			[self clearSLNs];
			
			NSArray *slns = [[goodCombinations objectAtIndex:0] componentsSeparatedByString:@":"];
			currentChecker.lastAttempt = [goodCombinations objectAtIndex:0];
			
			
			//For each sln in compination fill a sln textbox
			for(int i = 0; i < [slns count]; i++){
				[self fillSLNTextBox:[slns objectAtIndex:i]];
				//NSLog(@"Fill SLN Textbox:%@ lastAttempt:%@",[slns objectAtIndex:i],currentChecker.lastAttempt);
			}
			
			//uncheck any dropped class checkboxes
			[self uncheckBoxes];
			
			//check boxes for user specified classes
			if ([slns count] != 0) {
				for(NSString *key in currentChecker.dropClasses){
					[self checkBoxWithSLN:key];
				}
			}
			
			//Press update button
			NSString *string = [NSString stringWithFormat:@"function f(){var result = 'No';var divArray = document.getElementsByTagName('input'); for (var i = 0; i<divArray.length; i++){if(divArray[i].value==' Update Schedule '){divArray[i].click();result='Yes';}}return result;}f();"];
			NSString *result = [webView stringByEvaluatingJavaScriptFromString:string];
			
			//If no update button that means the webview is on another page or the registration period hasn't started yet
			//The page should be reloaded
			if ([result isEqualToString:@"No"]) {
				[self homeButtonPressd:nil];
			}
		}

		
		[currentChecker.status setStringValue:@"Found open slots!"];
		
		if (![newOutput isEqualToString:currentChecker.snlOutput]) {
			[speechSynth startSpeakingString:[NSString stringWithFormat:@"A class has an opening."]];
			
			//Add message to message center
			Message *newMessage = [[Message alloc] init];
			newMessage.title = [NSString stringWithFormat:@"Open slots found in %@",currentChecker.searchCourse];
			newMessage.message = newOutput;
			
			//Get date
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"HH:mm"];
			newMessage.date = [formatter stringFromDate:[NSDate date]];
			[formatter release];
			
			//Add message
			[messages addObject:newMessage];
			[newMessage release];
			[messageTableView reloadData];
		}

		//Send a notification if one has not already been sent
		if (currentChecker.notificationSent == NO) {
			
			if (currentChecker.shouldSendText) {
				currentChecker.notificationSent = YES;
				NSString *fullAddress = @"";
				
				if ([currentChecker.carrier isEqualToString:@"Verizon"]) 
					fullAddress = [NSString stringWithFormat:@"%@@vtext.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"AT&T"])
					fullAddress = [NSString stringWithFormat:@"%@@txt.att.net",currentChecker.phoneNumber];	
				else if ([currentChecker.carrier isEqualToString:@"T-Mobile"])
					fullAddress = [NSString stringWithFormat:@"%@@tmomail.net",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Qwest"])
					fullAddress = [NSString stringWithFormat:@"%@@qwestmp.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Sprint"])
					fullAddress = [NSString stringWithFormat:@"%@@messaging.sprintpcs.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Virgin Mobile"])
					fullAddress = [NSString stringWithFormat:@"%@@vmobl.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Nextel"])
					fullAddress = [NSString stringWithFormat:@"%@@messaging.nextel.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Alltel"])
					fullAddress = [NSString stringWithFormat:@"%@@message.alltel.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Metro PCS"])
					fullAddress = [NSString stringWithFormat:@"%@@mymetropcs.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Powertel"])
					fullAddress = [NSString stringWithFormat:@"%@@ptel.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"Suncom"])
					fullAddress = [NSString stringWithFormat:@"%@@tms.suncom.com",currentChecker.phoneNumber];
				else if ([currentChecker.carrier isEqualToString:@"U.S. Cellular"])
					fullAddress = [NSString stringWithFormat:@"%@@email.uscc.net",currentChecker.phoneNumber];
				[self sendEmailBody:[NSString stringWithFormat:@"UW Course Bot has found an open slot(s) in %@.",currentChecker.searchCourse] 
						withSubject:[NSString stringWithFormat:@"%@ Opening.",currentChecker.searchCourse] toAddress:fullAddress];
			}
			if (currentChecker.shouldSendEmail) {
				currentChecker.notificationSent = YES;
				[self sendEmailBody:[NSString stringWithFormat:@"UW Course Bot has found an open slot(s) in %@.",currentChecker.searchCourse] 
						withSubject:[NSString stringWithFormat:@"%@ Opening.",currentChecker.searchCourse] toAddress:currentChecker.email];
			}
		}
	}
	else {
		[currentChecker.status setStringValue:@"No open slots yet"];
	}
	currentChecker.snlOutput = newOutput;
	[self updateSLNOutput];
	
	[goodCombinations release];
	goodCombinations = nil;
}

-(void)updateSLNOutput{
	NSString *output = [NSString stringWithFormat:@""];
	for(ClassChecker *temp in checkerArray){
		if (temp.snlOutput != nil) {
			output = [NSString stringWithFormat:@"%@%@",output,temp.snlOutput];
		}
	}
	[availableSLNs setString:output];
}
-(void)addClassNamesToPopup:(ClassChecker *)currentChecker{

	[currentChecker.classChoice removeAllItems];
	for(ClassNode *node in currentChecker.allClasses){
		
		if ([currentChecker.classChoice itemWithTitle:node.className] == nil) {
			[currentChecker.classChoice addItemWithTitle:node.className];
		}
	}
	[self addSectionNamesToPopup: currentChecker];
}
-(void)addSectionNamesToPopup:(ClassChecker *)currentChecker{
	[currentChecker.sectionChoice removeAllItems];
	//[currentChecker.searchSections removeAllObjects];
	[currentChecker.sectionsToSearch removeAllObjects];
	currentChecker.searchCourse = [currentChecker.classChoice titleOfSelectedItem];
	for(ClassNode *node in currentChecker.allClasses){
		if ([node.className compare:[currentChecker.classChoice titleOfSelectedItem]] == NSOrderedSame) {
			[currentChecker.sectionChoice addItemWithTitle:[NSString stringWithFormat:@"%@", node.section, node.type]];
			[currentChecker.sectionsToSearch setObject:node forKey:node.section];
		}
	}
}
#pragma mark UI Selection Change 
-(IBAction)classSelectionChange:(id)sender{
	ClassChecker *currentChecker;
	if (checker1.classChoice == sender) {
		currentChecker = checker1;
	}
	else if (checker2.classChoice == sender){
		currentChecker = checker2;
	}
	else {
		currentChecker = checker3;
	}
	[self addSectionNamesToPopup:currentChecker];
}
#pragma mark Window Control
-(IBAction)showHideMessageCenter:(id)sender{
	[messageCenter makeKeyAndOrderFront:self];
	if ([messages count]>=1) {
		[messageTableView selectRow:0 byExtendingSelection:NO];
	}
}
- (BOOL)windowShouldClose:(id)sender{
	if (sender == window) {
		
		[NSApp terminate:self];
		return NO;

	}
	return YES;
}
#pragma mark Advance Settings Window

- (void)controlTextDidChange:(NSNotification*)notification {
	NSTextField* textField = [notification object];
	if (textField == cellPhone) {
		[sendText setState:YES];
	}
	else if(textField == email){
		[sendEmail setState:YES];
	}
	
}



-(IBAction)configureAdvancedSettingsPressed:(id)sender{
	[carrier removeAllItems];
	[carrier addItemWithTitle:@"Verizon"];
	[carrier addItemWithTitle:@"AT&T"];
	[carrier addItemWithTitle:@"Qwest"];
	[carrier addItemWithTitle:@"T-Mobile"];
	[carrier addItemWithTitle:@"Sprint"];
	[carrier addItemWithTitle:@"Virgin Mobile"];
	[carrier addItemWithTitle:@"Nextel"];
	[carrier addItemWithTitle:@"Alltel"];
	[carrier addItemWithTitle:@"Metro PCS"];
	[carrier addItemWithTitle:@"Powertel"];
	[carrier addItemWithTitle:@"U.S. Cellular"];
	[carrier addItemWithTitle:@"Suncom"];
	[advancedSettings makeKeyAndOrderFront:self];
	
	if ([sender tag] == 1) 
		advancedChecker = checker1;
	else if([sender tag] == 2)
		advancedChecker = checker2;
	else 
		advancedChecker = checker3;
	
	//Add drop settings into temporary drop classes array
	[advancedDropClasses removeAllObjects];
	for(NSString *key in advancedChecker.dropClasses){
		[advancedDropClasses setObject:[advancedChecker.dropClasses objectForKey:key] forKey:key];
	}
	
	//Set Window Title
	if ([advancedChecker searchCourse] == nil) {
		[advancedSettings setTitle:[NSString stringWithFormat:@"Advanced Settings for Class %i",[sender tag]]];
	}
	else {
		[advancedSettings setTitle:[NSString stringWithFormat:@"Advanced Settings for %@",[advancedChecker searchCourse]]];
	}

	[sendEmail setState:[advancedChecker shouldSendEmail]];
	[sendText setState:[advancedChecker shouldSendText]];
	[cellPhone setStringValue:[advancedChecker phoneNumber]];
	[email setStringValue:[advancedChecker email]];
	if ([carrier indexOfItemWithTitle:[advancedChecker carrier]] >= 0) {
		[carrier selectItemWithTitle:[advancedChecker carrier]];
	}
	
	[dropClasses reloadData];

}
-(IBAction)saveAndClosePressed:(id)sender{
	
	if ([sendText state] && [[cellPhone stringValue] length] != 10) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Incorrect Phone Number"];
		[alert setInformativeText:@"Please enter the cell phone number in the form ##########"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:advancedSettings modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}
	else {
		
		//Save drop classes to checker drop classes
		[advancedChecker.dropClasses removeAllObjects];
		for(NSString *key in advancedDropClasses){
			[advancedChecker.dropClasses setObject:[advancedDropClasses objectForKey:key] forKey:key];
		}
		
		advancedChecker.email = [email stringValue];
		advancedChecker.phoneNumber = [cellPhone stringValue];
		advancedChecker.carrier = [carrier titleOfSelectedItem];
		advancedChecker.shouldSendText = [sendText state];
		advancedChecker.shouldSendEmail = [sendEmail state];
		
		[advancedSettings close];
	}
}
-(IBAction)cancelPressed:(id)sender{
	[advancedSettings close];
}
-(IBAction)setAllNotificationPressed:(id)sender{
	if ([sendText state] && [[cellPhone stringValue] length] != 10) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Incorrect Phone Number"];
		[alert setInformativeText:@"Please enter the cell phone number in the form ##########"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:advancedSettings modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}
	else {
		//load default preferences for the user
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		//Save notification details to userdefaults
		[defaults setInteger:[sendText state] forKey:@"sendText"];
		[defaults setInteger:[sendEmail state] forKey:@"sendEmail"];
		[defaults setObject:[cellPhone stringValue] forKey:@"phoneNumber"];
		[defaults setObject:[email stringValue] forKey:@"email"];
		[defaults setObject:[carrier titleOfSelectedItem] forKey:@"carrier"];
		[defaults synchronize];
		
		[self restoreDefaultNotification];
	}
	
}
#pragma mark UI Buttons
-(IBAction)messageClearButtonPressed:(id)sender{
	[messages removeAllObjects];
	[messageTableView reloadData];
}
-(IBAction)listButtonPressed:(id)sender{
/*
	//Should open link
	//http://www.washington.edu/students/reg/curricabbr.html
	
	//Delete All Cookies
	NSEnumerator*   enumerator;
	NSHTTPCookie*   cookie;
	enumerator = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] objectEnumerator];
	while (cookie = [enumerator nextObject]) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
	[enumerator release];
	[cookie release];
*/
	
	NSURL *url = [ [ NSURL alloc ] initWithString: @"http://www.washington.edu/students/reg/curricabbr.html"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[url release];
	 
}
-(IBAction)removeSectionPressed:(id)sender{
	ClassChecker *currentChecker;
	if (checker1.removeButton == sender) {
		currentChecker = checker1;
	}
	else if (checker2.removeButton == sender){
		currentChecker = checker2;
	}
	else {
		currentChecker = checker3;
	}
	int index = [currentChecker.sectionChoice indexOfSelectedItem];
	if (index == -1) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"No sections loaded"];
		[alert setInformativeText:@"There are no sections in the search to remove."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}
	[currentChecker.sectionsToSearch removeObjectForKey:[currentChecker.sectionChoice titleOfSelectedItem]];
	[currentChecker.sectionChoice removeItemWithTitle:[currentChecker.sectionChoice titleOfSelectedItem]];
	
	//Set selection choice to next title in list if there is one
	if ([currentChecker.sectionChoice indexOfItem:[currentChecker.sectionChoice lastItem]] >= index) {
		[currentChecker.sectionChoice selectItemAtIndex:index];
	}
	
}
//Method is called when the load classes button is pressed. It creates a new url
-(IBAction)updateButtonPressed:(id)sender{
	
	//Set last Request to time to prevent another request jamming the connection
	lastRequest = CFAbsoluteTimeGetCurrent();
	
	//Set current checker based on what input was received
	ClassChecker *currentChecker;
	if (checker1.updateButton == sender) {
		currentChecker = checker1;
	}
	else if (checker2.updateButton == sender){
		currentChecker = checker2;
	}
	else {
		currentChecker = checker3;
	}
	
	if (currentChecker.isRunning) {
		return;
	}

	NSString *htmlText = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
	NSString *quarter;
	if ([htmlText rangeOfString:@"registration - autumn" options: NSCaseInsensitiveSearch].length != 0) {
		quarter = @"AUT";
	}
	else if([htmlText rangeOfString:@"registration - winter" options: NSCaseInsensitiveSearch].length != 0){
		quarter = @"WIN";
	}
	else if([htmlText rangeOfString:@"registration - spring" options: NSCaseInsensitiveSearch].length != 0){
		quarter = @"SPR";
	}
	else if([htmlText rangeOfString:@"registration - summer" options: NSCaseInsensitiveSearch].length != 0){
		quarter = @"SUM";
	}
	else{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Could not verify login"];
		[alert setInformativeText:@"In order to load classes please first login.  If you already logged make sure the registration page is visible by selecting the \"Home\" button."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}
	
	//The information in the class information section is used to make up the url
	//multi word subject codes are slit up and "+" are used in place
	NSString *wholeChunk = [[currentChecker.subCode stringValue] uppercaseString];
	if ([wholeChunk isEqualToString: @""]) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Subject code blank"];
		[alert setInformativeText:@"Please enter a subject code first."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}
	NSArray *chunks = [wholeChunk componentsSeparatedByString:@" "];
	NSDateComponents *yearComponent = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	NSDateComponents *monthComponent = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:[NSDate date]];
	NSInteger year = [yearComponent year];
	NSInteger month = [monthComponent month];
	
	//Winter quarter url needs to have correct year
	if ([quarter isEqualToString:@"WIN"] && month >= 4) {
		year++;
	}
	
	NSString *url = [NSString stringWithFormat:@"https://sdb.admin.washington.edu/timeschd/uwnetid/tsstat.asp?QTRYR=%@+%i&CURRIC=",quarter,year];
    
	url = [url stringByAppendingString:[chunks objectAtIndex:0]]; 
	for(int i = 1; i < [chunks count]; i++){
		url = [url stringByAppendingFormat:@"+%@",[chunks objectAtIndex:i]];
	}
    NSLog(@"%@", url);
	currentChecker.urlString = url;
	//Clear pop up buttons and add a title that says "loading..."
	[currentChecker.classChoice removeAllItems];
	[currentChecker.classChoice addItemWithTitle:@"Loading..."];
	[currentChecker.allClasses removeAllObjects];
	[currentChecker.sectionChoice removeAllItems];

	//Create webview for loading if it doesn't exist yet
	if (currentChecker.webView == nil) {
		currentChecker.webView= [[WebView alloc] init];
		[currentChecker.webView setFrameLoadDelegate:self];
	}
	
	//Load webpage with content
	[self loadRequestForChecker:currentChecker];
	//[connectionQueue addObject:currentChecker];
}

-(IBAction)homeButtonPressd:(id)sender{
	NSURL *registrationURL = [[NSURL alloc] initWithString:@"https://sdb.admin.washington.edu/students/uwnetid/register.asp"];
	NSURLRequest *registrationRequest = [[NSURLRequest alloc] initWithURL:registrationURL];
	[[webView mainFrame] loadRequest:registrationRequest];
	[registrationURL release];
	[registrationRequest release];
}
-(IBAction)runButtonPressed:(id)sender{
	ClassChecker *currentChecker;
	if (checker1.runButton == sender) {
		currentChecker = checker1;
	}
	else if (checker2.runButton == sender){
		currentChecker = checker2;
	}
	else {
		currentChecker = checker3;
	}
	
	if (currentChecker.isRunning) {
		currentChecker.inWait = NO;
		[currentChecker.webView stopLoading:self];
		currentChecker.isRunning = NO;
		[currentChecker.runButton setTitle:@"Run"];
		[currentChecker.runIndicator stopAnimation:self];
		[currentChecker.classChoice setEnabled:YES];
		[currentChecker.sectionChoice setEnabled:YES];
		[currentChecker.updateButton setEnabled:YES];
		[currentChecker.removeButton setEnabled:YES];
		[currentChecker.subCode setEnabled:YES];
	}
	else {
		
		if (currentChecker.urlString == nil) {
			
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"No classes loaded"];
			[alert setInformativeText:@"Before you can check for open slots you must first click the \"Load Classes\" button and selected a class."];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(someMethodDidEnd:returnCode:contextInfo:) contextInfo:nil];
			return;
		}
		
		[currentChecker.classChoice setEnabled:NO];
		[currentChecker.sectionChoice setEnabled:NO];
		[currentChecker.updateButton setEnabled:NO];
		[currentChecker.removeButton setEnabled:NO];
		[currentChecker.subCode setEnabled:NO];
		[currentChecker.badCombinations removeAllObjects];
		
		//Set notification sent to no
		currentChecker.notificationSent = NO;
		
		//This process basically prepares for data structures for the classes
		//to be downloaded into.  They are setup in a way so it can be easily checked
		//to make sure all the proper sections are open of a certain class before the
		//user is notified.
		
		//CLear dictionary to hold different Sections
		[currentChecker.courseSections removeAllObjects];
		
		
		//For each section that should be searched
		for(ClassNode *key in currentChecker.sectionsToSearch){
			ClassNode *node = [currentChecker.sectionsToSearch objectForKey:key];
			
			//If a section dictionary does not exist create one and then create an array for the type
			if ([currentChecker.courseSections objectForKey:[node singleLetterSection]] == nil) {
				
				//Create dictionary for section 
				NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
				[currentChecker.courseSections setObject:tempDict forKey:[node singleLetterSection]];
				
				//Create an empty array and add it to section dictionary to hold class when they are downloaded
				NSMutableArray *tempArray = [[NSMutableArray alloc] init];
				[tempDict setObject:tempArray forKey:node.type];
				[tempArray release];
				[tempDict release];
				
			}
			//Else there is already a dictionary for the section and it should be checked to see if there is a proper
			//type key setup for the type of the section.
			else {
				NSMutableDictionary *tempDict = [currentChecker.courseSections objectForKey:[node singleLetterSection]];
				
				//If a array for the type does not exist create one.
				if ([tempDict objectForKey:node.type] == nil) {
					NSMutableArray *tempArray = [[NSMutableArray alloc] init];
					[tempDict setObject:tempArray forKey:node.type];
					[tempArray release];
				}
				
			}

		}
		
		currentChecker.timeSpentWaiting = 0.0;
		currentChecker.changeInTime = 0.0;
		currentChecker.lastTimeTickWasCalled = 0.0;
		currentChecker.isRunning = YES;
		[currentChecker.runButton setTitle:@"Stop"];
		[currentChecker.runIndicator startAnimation:self];
		
		//Load web request
		if ([self indexInWait:currentChecker]==-1) {
			[connectionQueue addObject:currentChecker];
		}
	}
}
#pragma mark Other
- (void)dealloc {
	[webView release];
	[checker1 release];
	[checker2 release];
	[checker3 release];
	[checkerArray release];
	[super dealloc];
}
@end


