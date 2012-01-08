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

NSString *MKiCloudSyncDidUpdateNotification = @"MKiCloudSyncDidUpdateNotification";

#import "MKiCloudSync.h"

@interface MKiCloudSync ()

+ (void) pullFromICloud: (NSNotification *) note;
+ (void) pushToICloud;

@end

@implementation MKiCloudSync

+ (BOOL) start
{
	if ([NSUbiquitousKeyValueStore class] && [NSUbiquitousKeyValueStore defaultStore])
	{
		// Force push
		[MKiCloudSync pushToICloud];
		
		// Force pull
		NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
		NSDictionary *dict = [store dictionaryRepresentation];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[dict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
			[userDefaults setObject: obj forKey: key];
		}];
		[userDefaults synchronize];
		
		NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
		
		// Post notification
		[dnc postNotificationName: MKiCloudSyncDidUpdateNotification object: self];
		
		// Add self as observer
		[dnc addObserver: self selector: @selector(pullFromICloud:) name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification object: store];
		[dnc addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
		
#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Updating from iCloud");
#endif
		
		return YES;
	}
	
	return NO;
}

+ (NSMutableSet *) ignoredKeys
{
	static NSMutableSet *ignoredKeys;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		ignoredKeys = [NSMutableSet new];
	});
	
	return ignoredKeys;
}

+ (void) cleanUbiquitousStore
{
	[self stop];
	
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	NSDictionary *dict = [store dictionaryRepresentation];
	
	NSMutableSet *keys = [NSMutableSet setWithArray: [dict allKeys]];
	[keys minusSet: [self ignoredKeys]];
	
	[keys enumerateObjectsUsingBlock: ^(NSString *key, BOOL *stop) {
		[store removeObjectForKey: key];
	}];
	
	[store synchronize];
	
#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Cleaned ubiquitous store");
#endif
}
+ (void) pullFromICloud: (NSNotification *) note
{
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	[dnc removeObserver: self name: NSUserDefaultsDidChangeNotification object: nil];
	
	NSUbiquitousKeyValueStore *store = note.object;
	NSArray *changedKeys = [note.userInfo objectForKey: NSUbiquitousKeyValueStoreChangedKeysKey];

#if MKiCloudSyncDebug
		NSLog(@"MKiCloudSync: Pulled from iCloud");
#endif
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[changedKeys enumerateObjectsUsingBlock: ^(NSString *key, NSUInteger idx, BOOL *stop) {
		id obj = [store objectForKey: key];
		[userDefaults setObject: obj forKey: key];
	}];
	[userDefaults synchronize];
	
	[dnc addObserver: self selector: @selector(pushToICloud) name: NSUserDefaultsDidChangeNotification object: nil];
	[dnc postNotificationName: MKiCloudSyncDidUpdateNotification object: nil];
}
+ (void) pushToICloud
{
	NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
	
	NSMutableDictionary *persistentDomain = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: identifier] mutableCopy];
	
	NSArray *ignoredKeys = [[self ignoredKeys] allObjects];
	[persistentDomain removeObjectsForKeys: ignoredKeys];
	
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	[persistentDomain enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
		[store setObject: obj forKey: key];
	}];
	[store synchronize];
	
#if MKiCloudSyncDebug
	NSLog(@"MKiCloudSync: Pushed to iCloud");
#endif
}
+ (void) stop
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
