//
//  MKiCloudSync.m
//
//  Created by Mugunth Kumar on 11/20//11.
//  Modified by Alexsander Akers on 1/4/12.
//  
//  Copyright (C) 2011-2020 by Steinlogic
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "MKiCloudSync.h"

@interface MKiCloudSync ()

+ (void) pushToICloud;
+ (void) pullFromICloud: (NSNotification *) note;
+ (void) clean;

@end

@implementation MKiCloudSync

+ (BOOL) start
{
	if ([NSUbiquitousKeyValueStore class] && [NSUbiquitousKeyValueStore defaultStore])
	{
        //  FORCE PUSH
        [MKiCloudSync pushToICloud];
        //
        
        //  FORCE PULL
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        
        NSDictionary *dict = [store dictionaryRepresentation];
        NSLog(@"!!! UPDATING FROM ICLOUD !!! %@", dict);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [dict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
            [userDefaults setObject: obj forKey: key];
        }];
        
        [userDefaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: kMKiCloudSyncNotification object: nil];
        //
        
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pullFromICloud:) name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification object: store];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
		
		return YES;
	}
	
	return NO;
}
+ (void) stop
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

+ (void) pushToICloud
{
	NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
	NSMutableDictionary *persistentDomain = [NSMutableDictionary dictionaryWithDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName: identifier]];
        
        //  EXCL. SPECIAL KEYS LIKE DEVICE-SPECIFIC ONES
    [persistentDomain removeObjectsForKeys: [NSArray arrayWithObjects: @"iCloudSync", nil]];
        //
        
    NSLog(@"!!! UPDATING TO ICLOUD !!! %@", persistentDomain);
	
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	[persistentDomain enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
		[store setObject: obj forKey: key];
	}];
	
	[store synchronize];
}
+ (void) pullFromICloud: (NSNotification *) note
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSUserDefaultsDidChangeNotification object: nil];
	
	NSUbiquitousKeyValueStore *store = note.object;
	
	NSArray *changedKeys = [note.userInfo objectForKey: NSUbiquitousKeyValueStoreChangedKeysKey];
    NSLog(@"!!! UPDATING FROM ICLOUD !!! %@", changedKeys);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[changedKeys enumerateObjectsUsingBlock: ^(NSString *key, NSUInteger idx, BOOL *stop) {
		id obj = [store objectForKey: key];
		[userDefaults setObject: obj forKey: key];
	}];
	
	[userDefaults synchronize];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: kMKiCloudSyncNotification object: nil];
}

+ (void) clean {
    [self stop];
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
	NSDictionary *dict = [store dictionaryRepresentation];
    [dict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        //  NON-NIL TO KEEP KEY
		[store setObject: @"" forKey: key];
	}];
    
    [store synchronize];
    NSLog(@"!!! CLEANING ICLOUD !!! %@", [store dictionaryRepresentation]);
}

+ (void)dealloc {
        //  DOES ANYONE KNOW HOW LONG THIS IS KEPT ALIVE?
        //  SOMETIMES I FELT LIKE THE CLASS STOPPED WORKING,
        //  HOWEVER AFTER IMPLEMENTING THIS,
        //  THE LOG NEVER APPEARED FOR ME.
    NSLog(@"!!! FOR DEBUGGING PURPOSES ONLY !!!");
    [super dealloc];
        //
}

@end
