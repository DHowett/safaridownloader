#import "../extension/SDMCommon.h"
#import "SDUserSettings.h"

const NSString * const kSDUserSettingsReloadedNotification = @"kSDUserSettingsReloadedNotification";

@implementation SDUserSettings
static SDUserSettings *_sharedSettings;
+ (id)sharedInstance {
	return _sharedSettings ?: _sharedSettings = [[self alloc] init];
}

static NSString *_preferencesPath;
+ (NSString *)preferencesPath {
	return _preferencesPath ?: _preferencesPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/net.howett.safaridownloader.plist"] retain];
}

- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; }
- (void)release { }
- (id)autorelease { return self; }

- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue {
	NSNumber *b = [_settings objectForKey:key];
	if(!b) return defaultValue;
	return [b boolValue];
}

- (NSInteger)integerForKey:(NSString *)key default:(NSInteger)defaultValue {
	NSNumber *b = [_settings objectForKey:key];
	if(!b) return defaultValue;
	return [b integerValue];
}

- (NSObject *)objectForKey:(NSObject *)key default:(NSObject *)defaultValue {
	NSObject *b = [_settings objectForKey:key];
	if(!b) return defaultValue;
	return b;
}

- (float)floatForKey:(NSString *)key default:(float)defaultValue {
	NSNumber *b = [_settings objectForKey:key];
	if(!b) return defaultValue;
	return [b floatValue];
}

- (NSArray *)arrayForKey:(NSString *)key {
	return [_settings objectForKey:key];
}

- (void)setObject:(NSObject *)object forKey:(NSString *)key {
	[_settings setObject:object forKey:key];
}

- (void)reloadSettings {
	if(_settings) [_settings release];
	_settings = [[NSMutableDictionary dictionaryWithContentsOfFile:[[self class] preferencesPath]] retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:kSDUserSettingsReloadedNotification object:self];
}

- (void)commit {
	[_settings writeToFile:[[self class] preferencesPath] atomically:YES];
	[self reloadSettings];
}

- (NSArray *)disabledItemNames {
	return [_settings objectForKey:@"DisabledItems"];
}

- (NSDictionary *)customFileTypes {
	return [_settings objectForKey:@"CustomItems"];
}
@end
