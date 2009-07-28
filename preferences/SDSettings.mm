#import "SDSettings.h"

/*
 * BIG DISCLAIMER
 * IF YOU IGNORE THIS I WILL STAB YOU
 * I AM NOT PROUD OF THIS
 * THIS IS A "MAKE IT FRIGGIN WORK" IMPLEMENTATION
 * IT WILL GET CLEANED UP LATER
 * BWA HA AND HA. heh.
 * - DHowett
 */

#define SD_PREFS @"/var/mobile/Library/Preferences/net.howett.safaridownloader.plist"

@interface SDSettingsFiletypeListController : PSListController {
	int _type;
	NSMutableSet *_disabledItems;
}
- (id)initForContentSize:(CGSize)size;
- (void)dealloc;
- (void)suspend;
- (id)specifiers;
@end

@implementation SDSettingsFiletypeListController
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		_type = [[self.specifier propertyForKey:@"type"] isEqualToString:@"ext"] ? 0 : 1;
		NSLog(@"Type is %d...", _type);
		NSArray *disabledItemsArray = [[NSDictionary dictionaryWithContentsOfFile:SD_PREFS] objectForKey:[@"Disabled" stringByAppendingString:(_type==0 ? @"Extensions" : @"Mimetypes")]] ?: [NSArray array];
		_disabledItems = [[NSMutableSet alloc] initWithArray:disabledItemsArray];
	}
	return self;
}

- (void)dealloc {
	[_disabledItems release];
	[super dealloc];
}

- (void)suspend {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:SD_PREFS] ?: [NSMutableDictionary dictionary];
	[dict setObject:[_disabledItems allObjects] forKey:[@"Disabled" stringByAppendingString:(_type==0 ? @"Extensions" : @"Mimetypes")]];
	[dict writeToFile:SD_PREFS atomically:NO];
	[super suspend];
}

- (id)specifiers {
	NSMutableArray *specs = [NSMutableArray array];
	int c = [PSTableCell cellTypeFromString:@"PSSwitchCell"];
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/Downloader/FileTypes.plist"];
	for(NSArray *a in [[d objectForKey:(_type==0 ? @"Extensions" : @"Mimetypes")] allValues]) {
		NSLog(@"%@", a);
		for(NSString *s in a) {
			PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:s
									target:self
									   set:@selector(set:spec:)
									get:@selector(get:)
									detail:nil
									cell:c
									edit:nil];
			[spec setProperty:s forKey:@"id"];
			[specs addObject:spec];
		}
	}
	return specs;
}

- (CFBooleanRef)get:(PSSpecifier *)spec {
	if([_disabledItems containsObject:spec.identifier]) {
		return kCFBooleanFalse;
	} else {
		return kCFBooleanTrue;
	}
}

- (void)set:(CFBooleanRef)enabled spec:(PSSpecifier *)spec {
	if(enabled == kCFBooleanTrue) {
		[_disabledItems removeObject:spec.identifier];
	} else {
		[_disabledItems addObject:spec.identifier];
	}
}
@end

@implementation SDSettingsController

static NSMutableArray *extraSpecs;

- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
//		extraSpecs = [NSMutableArray array];
//		[extraSpecs addObject:spec];
	}
	return self;
}

- (id)specifiers {
	id specifiers = [self localizedSpecifiersWithSpecifiers:[self loadSpecifiersFromPlistName:@"SafariDownloader" target:self]];
//	[specifiers addObjectsFromArray:extraSpecs];
	return specifiers;
}

@end
