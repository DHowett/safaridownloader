#import "SDSettings.h"
#import <objc/runtime.h>
#import "extension/DownloaderCommon.h"
#import "common/Resources.h"
#import "common/SDFileType.h"

static id fileClassController = nil;

static BOOL _legacy = NO;

@interface PSListController (ViewControllerStuff)
- (void)viewDidLoad;
@end

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
}
- (id)specifiers;
- (void)dealloc;
- (void)suspend;
- (void)updatePreferencesFile;
- (PSSpecifier *)newExtraItemSpecifierWithContents:(NSString *)contents isExtension:(BOOL)extension;
- (NSString *)getOrigItem:(PSSpecifier *)spec;
- (void)setNewItem:(NSString *)s forSpecifier:(PSSpecifier *)spec;
- (void)deleteButtonPressed:(id)object;
@end

@implementation SDFileTypeSetupController
+ (BOOL)isOverlay { return NO; }
// Used on < 3.2
- (void)navigationBar:(id)bar buttonClicked:(int)clicked {
	SDSettingsCustomFileTypeController *controller = [self lastController];
	if(clicked == 1) [controller updatePreferencesFile];
	[self dismiss];
	[fileClassController reloadSpecifiers];
}
@end

@implementation SDSettingsCustomFileTypeController
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		//[[_deleteCell button] addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Used on >= 3.2 to add navbar buttons. why do I need to do this myself? Why does it work for apple and not me?
	if (![[PSViewController class] instancesRespondToSelector:@selector(showLeftButton:withStyle:rightButton:withStyle:)]) {
		UIBarButtonItem *cancelButton([[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonClicked:)]);
		UIBarButtonItem *saveButton([[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(navBarButtonClicked:)]);
		cancelButton.tag = 0;
		saveButton.tag = 1;
		[[self navigationItem] setLeftBarButtonItem:cancelButton];
		[[self navigationItem] setRightBarButtonItem:saveButton];
		[cancelButton release];
		[saveButton release];
	}
}

// Used on >= 3.2
- (void)navBarButtonClicked:(UIBarButtonItem *)button {
	if(button.tag == 1) [self updatePreferencesFile];
	[fileClassController reloadSpecifiers];
	[self.parentController dismiss];
}

- (void)dealloc {
	[_customEntry release];
	[_extensions release];
	[_mimetypes release];
	[super dealloc];
}

- (BOOL)canBeShownFromSuspendedState { return NO; }

- (void)suspend {
	[self updatePreferencesFile];
}

- (NSString *)getTextFromSpecifier:(PSSpecifier *)spec {
	return [[spec propertyForKey:@"cellObject"] value];
}

- (void)updatePreferencesFile {
	NSMutableDictionary *prefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE];
	NSMutableDictionary *customItems = [prefsDict objectForKey:@"CustomItems"] ?: [NSMutableDictionary dictionary];

	_name = [self getTextFromSpecifier:_nameSpec];
	if(!_name) return;

	if(!_deleted) {
		NSString *finalExt, *finalMime;
		finalExt = [self getTextFromSpecifier:_newExtSpec];
		finalMime = [self getTextFromSpecifier:_newMimeSpec];
		if(finalExt) [_extensions addObject:finalExt];
		if(finalMime) [_mimetypes addObject:finalMime];
		//[self setNewItem:finalExt forSpecifier:_newExtSpec]; and mime

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

- (void)loadExtraItemsAtIndex:(int)index fromArray:(NSArray *)array {
	for(NSString *item in array) {
		[self insertSpecifier:[self newExtraItemSpecifierWithContents:item isExtension:(array == _extensions)] atIndex:index];
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
		if(!_isNewType) {
			extIdx = [self indexOfSpecifier:_newExtSpec];
			NSLog(@"%@", _extensions);
			[self loadExtraItemsAtIndex:extIdx fromArray:_extensions];

			mimIdx = [self indexOfSpecifier:_newMimeSpec];
			NSLog(@"%@", _mimetypes);
			[self loadExtraItemsAtIndex:mimIdx fromArray:_mimetypes];
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
	[spec setPlaceholder:(extension ? @"Extension" : @"Mimetype")];
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
	if(isExtension && [s hasPrefix:@"."]) {
		s = [s stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
	}
	[workArray addObject:s];
	[spec setProperty:[NSNumber numberWithBool:NO] forKey:@"new"];
	[spec setProperty:s forKey:@"valueCopy"];

	if(isNew)
		[self insertSpecifier:[self newExtraItemSpecifierWithContents:nil isExtension:isExtension] atIndex:([self indexOfSpecifier:spec] + 1) animated:YES];
}

- (void)deleteButtonPressed:(id)object {
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

- (BOOL)canBeShownFromSuspendedState { return NO; }

- (void)dealloc {
	[_disabledItems release];
	[super dealloc];
}

- (id)specifiers {
	if(!_specifiers) {
		_specifiers = [[NSMutableArray array] retain];
		NSString *fileClass = [self.specifier propertyForKey:@"class"];
		int c = [PSTableCell cellTypeFromString:@"PSSwitchCell"];
		NSArray *category = [[SDFileType allCategories] objectForKey:fileClass];
		category = [category sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		for(SDFileType *fileType in category) {
			PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:fileType.name
									   target:self
									      set:@selector(set:spec:)
									      get:@selector(get:)
									   detail:nil
									     cell:c
									     edit:nil];
			[spec setProperty:fileType forKey:@"fileType"];
			[spec setProperty:[SDResources iconForFileType:fileType] forKey:@"iconImage"];
			[(NSMutableArray*)_specifiers addObject:spec];
		}
	}
	return _specifiers;
}

- (CFBooleanRef)get:(PSSpecifier *)spec {
	if([_disabledItems containsObject:[[spec propertyForKey:@"fileType"] name]]) {
		return kCFBooleanFalse;
	} else {
		return kCFBooleanTrue;
	}
}

- (void)set:(CFBooleanRef)enabled spec:(PSSpecifier *)spec {
	if(enabled == kCFBooleanTrue) {
		[_disabledItems removeObject:[[spec propertyForKey:@"fileType"] name]];
	} else {
		[_disabledItems addObject:[[spec propertyForKey:@"fileType"] name]];
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] ?: [NSMutableDictionary dictionary];
	[dict setObject:[_disabledItems allObjects] forKey:@"DisabledItems"];
	[dict writeToFile:PREFERENCES_FILE atomically:NO];
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

- (BOOL)canBeShownFromSuspendedState { return NO; }

- (id)specifiers {
	if(!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"FileClass" target:self] retain];

		NSMutableArray *removals = [NSMutableArray array];
		for(PSSpecifier *s in _specifiers) {
			if([[s propertyForKey:@"legacy"] boolValue] && !_legacy) [removals addObject:s];
		}
		[(NSMutableArray*)_specifiers removeObjectsInArray:removals];

		NSArray *customTypes = [[[NSDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE] objectForKey:@"CustomItems"] allKeys] ?: [NSArray array];

		int c = [PSTableCell cellTypeFromString:@"PSLinkCell"];
		int index = _legacy ? 3 : 2;
		for(NSString *fileClass in [[SDFileType allCategories] allKeys]) {
			PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:fileClass
									   target:self
									      set:nil
									      get:nil
									   detail:[SDSettingsFileTypeListController class]
									     cell:c
									     edit:nil];
			[spec setProperty:fileClass forKey:@"class"];
			[spec setProperty:[UIImage imageWithContentsOfFile:[[SDResources imageBundle] pathForResource:[@"Category-" stringByAppendingString:fileClass] ofType:@"png" inDirectory:@"Icons"]] forKey:@"iconImage"];
			[(NSMutableArray *)_specifiers insertObject:spec atIndex:index++];
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
			[(NSMutableArray *)_specifiers addObject:spec];
		}
		self.title = @"Filetypes";
	}
	return _specifiers;
}
@end

@implementation SDSettingsController
+ (void)load {
	_legacy = ![UIDevice instancesRespondToSelector:@selector(isWildcat)];
}

- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
//		extraSpecs = [NSMutableArray array];
//		[extraSpecs addObject:spec];
		[SDFileType loadAllFileTypes];

	}
	return self;
}

- (void)dealloc {
	[SDFileType unloadAllFileTypes];
	[super dealloc];
}

- (id)specifiers {
	NSString *plist = [self.specifier propertyForKey:@"plist"] ?: @"SafariDownloader";
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:plist target:self] retain];
//	[specifiers addObjectsFromArray:extraSpecs];
		NSMutableArray *removals = [NSMutableArray array];
		for(PSSpecifier *s in _specifiers) {
			if([[s propertyForKey:@"legacy"] boolValue] && !_legacy) [removals addObject:s];
		}
		[(NSMutableArray*)_specifiers removeObjectsInArray:removals];
	}
	return _specifiers;
}

@end

// vim:ft=objc
