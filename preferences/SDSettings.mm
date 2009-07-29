#import "SDSettings.h"
#import "../DownloaderCommon.h"

static id resourceBundle = nil;
static id fileTypesDict = nil;

@interface SDSettingsFileTypeListController : PSListController {
	int _type;
	NSMutableSet *_disabledItems;
}
- (id)initForContentSize:(CGSize)size;
- (void)dealloc;
- (void)suspend;
- (id)specifiers;
@end

@implementation SDSettingsFileTypeListController
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		NSArray *disabledItemsArray = [[NSDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] objectForKey:@"DisabledItems"] ?: [NSArray array];
		_disabledItems = [[NSMutableSet alloc] initWithArray:disabledItemsArray];
	}
	return self;
}

- (void)dealloc {
	[_disabledItems release];
	[super dealloc];
}

- (void)suspend {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] ?: [NSMutableDictionary dictionary];
	[dict setObject:[_disabledItems allObjects] forKey:@"DisabledItems"];
	[dict writeToFile:PREFERENCES_FILE atomically:NO];
	[super suspend];
}

- (id)specifiers {
	NSMutableArray *specs = [NSMutableArray array];
	NSString *fileClass = [self.specifier propertyForKey:@"class"];
	int c = [PSTableCell cellTypeFromString:@"PSSwitchCell"];
	for(NSString *fileType in [fileTypesDict objectForKey:fileClass]) {
		PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:fileType
								   target:self
								      set:@selector(set:spec:)
								      get:@selector(get:)
								   detail:nil
								     cell:c
								     edit:nil];
		[spec setProperty:fileType forKey:@"id"];
		[specs addObject:spec];
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

@interface SDSettingsFileClassListController : PSListController {
}
//- (id)initForContentSize:(CGSize)size;
//- (void)dealloc;
//- (void)suspend;
- (id)specifiers;
@end

@implementation SDSettingsFileClassListController : PSListController
- (id)specifiers {
	id specs = [NSMutableArray array];
	int c = [PSTableCell cellTypeFromString:@"PSLinkCell"];
	for(NSString *fileClass in fileTypesDict) {
		PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:fileClass
								   target:self
								      set:nil
								      get:nil
								   detail:[SDSettingsFileTypeListController class]
								     cell:c
								     edit:nil];
		[spec setProperty:fileClass forKey:@"class"];
		[specs addObject:spec];
	}
	return specs;
}
@end

@implementation SDSettingsController

static NSMutableArray *extraSpecs;

- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
//		extraSpecs = [NSMutableArray array];
//		[extraSpecs addObject:spec];
		resourceBundle = [[NSBundle alloc] initWithPath:SUPPORT_BUNDLE_PATH];
		fileTypesDict = [[NSDictionary alloc] initWithContentsOfFile:[resourceBundle pathForResource:@"FileTypes" ofType:@"plist"]];

	}
	return self;
}

- (id)specifiers {
	NSString *plist = [self.specifier propertyForKey:@"plist"] ?: @"SafariDownloader";
	id specifiers = [self localizedSpecifiersWithSpecifiers:[self loadSpecifiersFromPlistName:plist target:self]];
//	[specifiers addObjectsFromArray:extraSpecs];
	NSLog(@"%@", specifiers);
	return specifiers;
}

@end
