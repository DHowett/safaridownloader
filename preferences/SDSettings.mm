#import "SDSettings.h"
#import <objc/runtime.h>
#import "../DownloaderCommon.h"

static id resourceBundle = nil;
static id fileTypesDict = nil;
static id fileClassController = nil;

@interface SDFileTypeSetupController : PSSetupController {
}
+ (BOOL)isOverlay;
- (void)navigationBar:(id)bar buttonClicked:(int)clicked;
@end

@interface SDSettingsCustomFileTypeController : PSListController {
	BOOL _deleted;
	BOOL _isNewType;
	NSString *_name;
	NSString *_originalName;
	NSDictionary *_customEntry;
	NSMutableArray *_extensions;
	NSMutableArray *_mimetypes;
	PSSpecifier *_nameSpec;
	PSSpecifier *_newExtSpec;
	PSSpecifier *_newMimeSpec;
	UIPreferencesDeleteTableCell *_deleteCell;
}
- (id)specifiers;
- (void)dealloc;
- (void)suspend;
- (void)updatePreferencesFile;
- (PSSpecifier *)newExtraItemSpecifierWithContents:(NSString *)contents isExtension:(BOOL)extension;
- (NSString *)getOrigItem:(PSSpecifier *)spec;
- (void)setNewItem:(NSString *)s forSpecifier:(PSSpecifier *)spec;
- (void)deleteButtonPressed:(id)object;
- (id)preferencesTable:(id)table cellForRow:(int)row inGroup:(int)group;
@end

@implementation SDFileTypeSetupController
+ (BOOL)isOverlay { return NO; }
- (void)navigationBar:(id)bar buttonClicked:(int)clicked {
	SDSettingsCustomFileTypeController *controller = [_controllers lastObject];
	if(clicked == 1) [controller updatePreferencesFile];
	[self dismiss];
	[fileClassController reloadSpecifiers];
}
@end

@implementation SDSettingsCustomFileTypeController
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		_deleted = NO;
		_deleteCell = [[UIPreferencesDeleteTableCell alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
		[[_deleteCell button] setTitle:@"Delete this File Type"];
		//[[_deleteCell button] addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (id)preferencesTable:(id)table cellForRow:(int)row inGroup:(int)group {
	static id deleteCell;
	if(group == 3) {
		[[_deleteCell button] setEnabled:YES];
		[[_deleteCell button] addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		return _deleteCell;
	}
	else return [super preferencesTable:table cellForRow:row inGroup:group];
}

- (void)dealloc {
	[_customEntry release];
	[_extensions release];
	[_mimetypes release];
	[_deleteCell release];
	[super dealloc];
}

- (void)suspend {
	[self updatePreferencesFile];
}

- (void)updatePreferencesFile {
	NSMutableDictionary *prefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE];
	NSMutableDictionary *customItems = [prefsDict objectForKey:@"CustomItems"] ?: [NSMutableDictionary dictionary];

	if(!_name) return;

	if(!_deleted) {
		[_customEntry setValue:_extensions forKey:@"Extensions"];
		[_customEntry setValue:_mimetypes forKey:@"Mimetypes"];

		[customItems setValue:_customEntry forKey:_name];
		if(!_isNewType && ![_name isEqualToString:_originalName]) [customItems removeObjectForKey:_originalName];
	} else {
		if(!_isNewType) {
			[customItems removeObjectForKey:_originalName];
		}
	}

	[prefsDict setValue:customItems forKey:@"CustomItems"];
	[prefsDict writeToFile:PREFERENCES_FILE atomically:NO];
	[fileClassController reloadSpecifiers];
}

- (void)postinit {
	_name = [self.specifier propertyForKey:@"typename"];
	_deleted = NO;
	if(!_name) {
		_isNewType = YES;
		_customEntry = [[NSMutableDictionary dictionary] retain];
		_extensions = [[NSMutableArray array] retain];
		_mimetypes = [[NSMutableArray array] retain];
	} else {
		_isNewType = NO;
		_originalName = [_name copy];
		_customEntry = [[[[NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] objectForKey:@"CustomItems"] objectForKey:_name] retain];
		_extensions = [[_customEntry objectForKey:@"Extensions"] retain];
		_mimetypes = [[_customEntry objectForKey:@"Mimetypes"] retain];
	}
}

- (void)loadExtraItemsAtIndex:(int)index extensions:(BOOL)extensions {
	NSMutableArray *workArray = extensions ? _extensions : _mimetypes;
	for(NSString *item in workArray) {
		[self insertSpecifier:[self newExtraItemSpecifierWithContents:item isExtension:extensions] atIndex:index];
	}
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"FileType" target:self] retain];
		[self postinit];
		int extIdx = 0, mimIdx = 0;
		_nameSpec = [self specifierForID:@"name"];
		_newExtSpec = [self specifierForID:@"newExt"];
		_newMimeSpec = [self specifierForID:@"newMime"];
		extIdx = [self indexOfSpecifier:_newExtSpec];
		mimIdx = [self indexOfSpecifier:_newMimeSpec];
		if(!_isNewType) {
			[self loadExtraItemsAtIndex:extIdx extensions:YES];
			[self loadExtraItemsAtIndex:mimIdx extensions:NO];
		}
		self.title = _isNewType ? @"New File Type" : _name;
	}
	if(_isNewType) {
		// remove the delete button and its group if we're a new type.
		[self removeLastSpecifier];
		[self removeLastSpecifier];
	}
	return _specifiers;
}

- (NSString *)getName:(PSSpecifier *)spec {
	return _name;
}

- (void)setName:(NSString *)name forSpecifier:(PSSpecifier *)spec {
	_name = [name retain];
}

- (PSSpecifier *)newExtraItemSpecifierWithContents:(NSString *)contents isExtension:(BOOL)extension {
	int c = [PSTableCell cellTypeFromString:@"PSEditTextCell"];
	PSTextFieldSpecifier *spec = [PSTextFieldSpecifier preferenceSpecifierNamed:nil
									     target:self
										set:@selector(setNewItem:forSpecifier:)
										get:(contents ? @selector(getOrigItem:) : nil)
									     detail:nil
									       cell:c
									       edit:nil];
	if(contents) [spec setProperty:contents forKey:@"valueCopy"];
	[spec setPlaceholder:(extension ? @"Extension (no dot)" : @"Mimetype")];
	[spec setKeyboardType:0 autoCaps:0 autoCorrection:0];
	[spec setProperty:[NSNumber numberWithBool:(contents == nil)] forKey:@"new"];
	[spec setProperty:(extension ? @"extension" : @"mimetype") forKey:@"itemType"];
	if(!contents) (extension ? _newExtSpec : _newMimeSpec) = spec;
	return spec;
}

- (NSString *)getOrigItem:(PSSpecifier *)spec {
	return [spec propertyForKey:@"valueCopy"];
}

- (void)setNewItem:(NSString *)s forSpecifier:(PSSpecifier *)spec {
	BOOL isExtension = [[spec propertyForKey:@"itemType"] isEqualToString:@"extension"];
	NSMutableArray *workArray = isExtension ? _extensions : _mimetypes;
	BOOL isNew = [[spec propertyForKey:@"new"] boolValue];
	NSString *oldValue = [spec propertyForKey:@"valueCopy"];

	if(!s || [s length] == 0) {
		if(isNew) return;

		if(oldValue) [workArray removeObject:oldValue];
		[self removeSpecifier:spec animated:YES];
		return;
	} else if([s isEqualToString:[spec propertyForKey:@"valueCopy"]]) return;

	if(oldValue) {
		[workArray removeObject:oldValue];
	}
	[workArray addObject:s];
	[spec setProperty:[NSNumber numberWithBool:NO] forKey:@"new"];
	[spec setProperty:s forKey:@"valueCopy"];

	if(isNew)
		[self insertSpecifier:[self newExtraItemSpecifierWithContents:nil isExtension:isExtension] atIndex:([self indexOfSpecifier:spec] + 1) animated:YES];
}

- (void)deleteButtonPressed:(id)object {
	[object setEnabled:NO];
	[object removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
	_deleted = YES;
	[self updatePreferencesFile];
	[self.parentController dismiss];
}
@end

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
	if(!_specifiers) {
		_specifiers = [[NSMutableArray array] retain];
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
			[self addSpecifier:spec];
		}
	}
	return _specifiers;
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
	NSMutableArray *_customTypeSpecifiers;
}
//- (id)initForContentSize:(CGSize)size;
//- (void)dealloc;
//- (void)suspend;
- (void)viewWillRedisplay;
- (id)specifiers;
@end

@implementation SDSettingsFileClassListController : PSListController
- (void)viewWillRedisplay {
	[self reloadSpecifiers];
}

- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		fileClassController = self;
		_customTypeSpecifiers = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)specifiers {
	_specifiers = [[self loadSpecifiersFromPlistName:@"FileClass" target:self] retain];
	NSArray *customTypes = [[[NSDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] objectForKey:@"CustomItems"] allKeys] ?: [NSArray array];

	int c = [PSTableCell cellTypeFromString:@"PSLinkCell"];
	int index = 3;
	for(NSString *fileClass in fileTypesDict) {
		PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:fileClass
								   target:self
								      set:nil
								      get:nil
								   detail:[SDSettingsFileTypeListController class]
								     cell:c
								     edit:nil];
		[spec setProperty:fileClass forKey:@"class"];
		[spec setProperty:[UIImage imageWithContentsOfFile:[resourceBundle pathForResource:[@"Class-" stringByAppendingString:fileClass] ofType:@"png" inDirectory:@"FileIcons"]] forKey:@"iconImage"];
		[self insertSpecifier:spec atIndex:index++];
	}

//	[s setProperty:objc_getClass("SDSettingsCustomFileTypeController") forKey:@"customControllerClass"];
	for(NSString *customType in customTypes) {
		PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:customType
								   target:self
								      set:nil
								      get:nil
								   detail:[SDFileTypeSetupController class]
								     cell:c
								     edit:nil];
		[spec setProperty:customType forKey:@"typename"];
		[spec setProperty:@"SDSettingsCustomFileTypeController" forKey:@"customControllerClass"];
		[spec setProperty:@"Save" forKey:@"okTitle"];
		[spec setProperty:@"Cancel" forKey:@"cancelTitle"];
		[spec setProperty:@"Edit this File Type information." forKey:@"prompt"];
		[_customTypeSpecifiers addObject:spec];
		[self addSpecifier:spec];
	}
	self.title = @"Filetypes";
	return _specifiers;
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
	if(_specifiers == nil) {
		_specifiers = [[self localizedSpecifiersWithSpecifiers:[self loadSpecifiersFromPlistName:plist target:self]] retain];
//	[specifiers addObjectsFromArray:extraSpecs];
	}
	return _specifiers;
}

@end
