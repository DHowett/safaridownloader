#import "SDFileType.h"
#import "SDUserSettings.h"
#import "SDResources.h"

static NSMutableDictionary *_MIMEMapping;
static NSMutableDictionary *_extensionMapping;
#if SDFILETYPE_MAP_CATEGORIES == 1
static NSMutableDictionary *_categoryMapping;
#endif

#ifndef SDFILETYPE_NO_CUSTOM
static NSMutableDictionary *_customMIMEMapping;
static NSMutableDictionary *_customExtensionMapping;

@interface _SDCustomFileType: SDFileType
@end
@implementation _SDCustomFileType
- (BOOL)forceExtensionUse { return YES; }
@end
#endif

@interface SDFileType ()
@property (nonatomic, copy) NSArray *MIMETypes;
@property (nonatomic, copy) NSArray *extensions;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *genericType;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, assign) BOOL forceExtensionUse;
@property (nonatomic, assign) SDFileTypeAction defaultAction;
@property (nonatomic, assign) BOOL hidden;
+ (void)_registerFileType:(SDFileType *)fileType;
@end

@implementation SDFileType
@synthesize MIMETypes = _MIMETypes, extensions = _extensions, name = _name, genericType = _genericType, category = _category, forceExtensionUse = _forceExtensionUse, defaultAction = _defaultAction, hidden = _hidden;

+ (void)loadAllFileTypes {
	_MIMEMapping = [[NSMutableDictionary alloc] init];
	_extensionMapping = [[NSMutableDictionary alloc] init];
#if SDFILETYPE_MAP_CATEGORIES == 1
	_categoryMapping = [[NSMutableDictionary alloc] init];
#endif

	NSDictionary *fileTypeMaster = [NSDictionary dictionaryWithContentsOfFile:[[SDResources supportBundle] pathForResource:@"FileTypes" ofType:@"plist"]];
	for(NSString *fileTypeName in [fileTypeMaster allKeys]) {
		SDFileType *fileType = [[self alloc] initWithName:SDLocalizedStringInTable(fileTypeName, @"FileTypes") dictionary:[fileTypeMaster objectForKey:fileTypeName]];
		[self _registerFileType:fileType];
		[fileType release];
	}
}

#ifndef SDFILETYPE_NO_CUSTOM
+ (void)reloadCustomFileTypes {
	if(_customMIMEMapping) [_customMIMEMapping release];
	if(_customExtensionMapping) [_customExtensionMapping release];
	_customMIMEMapping = [[NSMutableDictionary alloc] init];
	_customExtensionMapping = [[NSMutableDictionary alloc] init];
	NSDictionary *fileTypeMaster = [[SDUserSettings sharedInstance] customFileTypes];
	for(NSString *fileTypeName in fileTypeMaster) {
		SDFileType *fileType = [[_SDCustomFileType alloc] initWithName:fileTypeName dictionary:[fileTypeMaster objectForKey:fileTypeName]];
		[self _registerFileType:fileType];
		[fileType release];
	}
}
#endif

+ (void)_registerFileType:(SDFileType *)fileType {
	NSMutableDictionary *mimeMap = _MIMEMapping;
	NSMutableDictionary *extMap = _extensionMapping;
#ifndef SDFILETYPE_NO_CUSTOM
	if(__builtin_expect([fileType isKindOfClass:[_SDCustomFileType class]], 0)) {
		mimeMap = _customMIMEMapping;
		extMap = _customExtensionMapping;
	}
#endif

	for(NSString *MIMEType in fileType.MIMETypes) {
		[mimeMap setObject:fileType forKey:MIMEType];
	}
	for(NSString *extension in fileType.extensions) {
		[extMap setObject:fileType forKey:extension];
	}
#if SDFILETYPE_MAP_CATEGORIES == 1
	NSMutableArray *_categoryArray = (NSMutableArray *)[_categoryMapping objectForKey:fileType.category];
	if(!_categoryArray) {
		_categoryArray = [NSMutableArray array];
		[_categoryMapping setObject:_categoryArray forKey:fileType.category];
	}
	[_categoryArray addObject:fileType];
#endif
}

+ (void)unloadAllFileTypes {
	[_MIMEMapping release];
	[_extensionMapping release];
#if SDFILETYPE_MAP_CATEGORIES == 1
	[_categoryMapping release];
#endif
#ifndef SDFILETYPE_NO_CUSTOM
	[_customMIMEMapping release];
	[_customExtensionMapping release];
#endif
}

#ifndef SDFILETYPE_NO_CUSTOM
+ (SDFileType *)fileTypeForMIMEType:(NSString *)MIMEType {
	return [_customMIMEMapping objectForKey:MIMEType] ?: [_MIMEMapping objectForKey:MIMEType];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension {
	return [_customExtensionMapping objectForKey:extension] ?: [_extensionMapping objectForKey:extension];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension orMIMEType:(NSString *)MIMEType {
	return ([_customExtensionMapping objectForKey:extension] ?: [_extensionMapping objectForKey:extension])
	    ?: ([_customMIMEMapping objectForKey:MIMEType] ?: [_MIMEMapping objectForKey:MIMEType]);
}
#else
+ (SDFileType *)fileTypeForMIMEType:(NSString *)MIMEType {
	return [_MIMEMapping objectForKey:MIMEType];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension {
	return [_extensionMapping objectForKey:extension];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension orMIMEType:(NSString *)MIMEType {
	return [_extensionMapping objectForKey:extension] ?: [_MIMEMapping objectForKey:MIMEType];
}
#endif

#if SDFILETYPE_MAP_CATEGORIES == 1
+ (NSDictionary *)allCategories {
	return _categoryMapping;
}
#endif

- (id)initWithName:(NSString *)name dictionary:(NSDictionary *)dictionary {
	if((self = [super init]) != nil) {
		self.name = name;
		self.MIMETypes = [dictionary objectForKey:@"Mimetypes"];
		self.extensions = [dictionary objectForKey:@"Extensions"];
		self.genericType = [dictionary objectForKey:@"GenericType"];
		self.category = [dictionary objectForKey:@"Category"];
		self.forceExtensionUse = [[dictionary objectForKey:@"ForceExtension"] boolValue];
		self.defaultAction = (SDFileTypeAction)[[dictionary objectForKey:@"DefaultAction"] intValue];
		self.hidden = [[dictionary objectForKey:@"Hidden"] boolValue];
	} return self;
}

- (void)dealloc {
	[_MIMETypes release];
	[_extensions release];
	[_name release];
	[_genericType release];
	[_category release];
	[super dealloc];
}

- (NSString *)primaryMIMEType {
	return _MIMETypes.count == 0 ? nil : [_MIMETypes objectAtIndex:0];
}
@end
