#import "extension/SDMCommon.h"
#import "SDSettings.h"
#import <objc/runtime.h>
#import "common/SDResources.h"
#import "common/SDFileType.h"

@interface PSTextViewTableCell: NSObject
- (NSString *)value;
@end

static NSString *_preferencesPath;
static NSString *preferencesPath() {
	return _preferencesPath ?: _preferencesPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/net.howett.safaridownloader.plist"] retain];
}

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

@interface SDSettingsCustomFileTypeController : SDListController {
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
		UIBarButtonItem *cancelButton([[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"CANCEL", nil, [self bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonClicked:)]);
		UIBarButtonItem *saveButton([[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"SAVE", nil, [self bundle], @"") style:UIBarButtonItemStyleDone target:self action:@selector(navBarButtonClicked:)]);
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
	return [(PSTextViewTableCell *)[spec propertyForKey:@"cellObject"] value];
}

- (void)updatePreferencesFile {
	NSMutableDictionary *prefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:preferencesPath()] ?: [NSMutableDictionary dictionary];
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
	[prefsDict writeToFile:preferencesPath() atomically:NO];
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
		_customEntry = [[[[NSMutableDictionary dictionaryWithContentsOfFile:preferencesPath()] objectForKey:@"CustomItems"] objectForKey:_name] retain];
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
		self.title = _isNewType ? @"NEW_FILE_TYPE" : _name;
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
	NSString *placeholder = (extension ? @"EXTENSIONS_PLACEHOLDER" : @"MIMETYPES_PLACEHOLDER");
	[spec setPlaceholder:NSLocalizedStringFromTableInBundle(placeholder, nil, [self bundle], @"")];
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

@interface SDSettingsFileTypeListController : SDListController {
	int _type;
	NSMutableDictionary *_fileActions;
	NSMutableSet *_disabledItems;
}
- (id)initForContentSize:(CGSize)size;
- (void)dealloc;
- (id)specifiers;
@end

@implementation SDSettingsFileTypeListController
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		_fileActions = [[NSMutableDictionary dictionaryWithContentsOfFile:preferencesPath()] objectForKey:@"FileActions"] ?: [NSMutableDictionary dictionary];
		[_fileActions retain];
	}
	return self;
}

- (BOOL)canBeShownFromSuspendedState { return NO; }

- (void)dealloc {
	[_fileActions release];
	[super dealloc];
}

- (id)specifiers {
	if(!_specifiers) {
		_specifiers = [[NSMutableArray array] retain];
		NSString *fileClass = [self.specifier propertyForKey:@"class"];
		int c = [PSTableCell cellTypeFromString:@"PSSwitchCell"];
		NSArray *category = [[SDFileType allCategories] objectForKey:fileClass];
		category = [category sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
		for(SDFileType *fileType in category) {
			if(fileType.hidden) continue;
			if(!fileType.primaryMIMEType) continue;
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
	SDFileType *fileType = [spec propertyForKey:@"fileType"];
	NSNumber *preferredAction = [_fileActions objectForKey:[fileType primaryMIMEType]];
	SDFileTypeAction fileAction;
	if(!preferredAction) fileAction = [fileType defaultAction];
	else fileAction = (SDFileTypeAction)[preferredAction intValue];
	return fileAction == SDFileTypeActionDownload ? kCFBooleanTrue : kCFBooleanFalse;
}

- (void)set:(CFBooleanRef)enabled spec:(PSSpecifier *)spec {
	SDFileType *fileType = [spec propertyForKey:@"fileType"];
	SDFileTypeAction fileAction = SDFileTypeActionDownload;
	if(enabled == kCFBooleanFalse) {
		fileAction = SDFileTypeActionView;
	}
	[_fileActions setObject:[NSNumber numberWithInt:fileAction] forKey:[fileType primaryMIMEType]];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:preferencesPath()] ?: [NSMutableDictionary dictionary];
	[dict setObject:_fileActions forKey:@"FileActions"];
	[dict writeToFile:preferencesPath() atomically:NO];
}
@end

@interface SDSettingsFileClassListController : SDListController {
	NSMutableArray *_customTypeSpecifiers;
}
//- (id)initForContentSize:(CGSize)size;
//- (void)dealloc;
//- (void)suspend;
- (void)viewWillRedisplay;
- (id)specifiers;
@end

@implementation SDSettingsFileClassListController
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

		NSArray *customTypes = [[[NSDictionary dictionaryWithContentsOfFile:preferencesPath()] objectForKey:@"CustomItems"] allKeys] ?: [NSArray array];

		int c = [PSTableCell cellTypeFromString:@"PSLinkCell"];
		int index = _legacy ? 3 : 2;
		NSArray *classes = [[[SDFileType allCategories] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		for(NSString *fileClass in classes) {
			PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:SDLocalizedStringInTable(fileClass, @"FileTypes")
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
			[spec setProperty:NSLocalizedStringFromTableInBundle(@"SAVE", nil, [self bundle], @"") forKey:@"okTitle"];
			[spec setProperty:NSLocalizedStringFromTableInBundle(@"CANCEL", nil, [self bundle], @"") forKey:@"cancelTitle"];
			[spec setProperty:NSLocalizedStringFromTableInBundle(@"EDIT_FILE_TYPE_PROMPT", nil, [self bundle], @"") forKey:@"prompt"];
			[_customTypeSpecifiers addObject:spec];
			[(NSMutableArray *)_specifiers addObject:spec];
		}
		self.title = @"FILE_TYPES";
	}
	return _specifiers;
}
@end

@implementation SDListController
- (id)bundle {
	return [NSBundle bundleWithPath:BUNDLE_PATH];
}

- (void)setTitle:(NSString *)title {
	[super setTitle:NSLocalizedStringFromTableInBundle(title, nil, [self bundle], @"")];
}

- (id)navigationTitle {
	return [[self bundle] localizedStringForKey:[super navigationTitle] value:[super navigationTitle] table:nil];
}

- (id)loadSpecifiersFromPlistName:(NSString *)plistName target:(id)target {
	NSMutableArray *specifiers = [super loadSpecifiersFromPlistName:plistName target:target];
	NSMutableArray *removals = [NSMutableArray array];
	for(PSSpecifier *spec in specifiers) {
		if([[spec propertyForKey:@"legacy"] boolValue] && !_legacy) [removals addObject:spec];

		if([spec name]) [spec setName:[[self bundle] localizedStringForKey:[spec name] value:[spec name] table:nil]];
		if([spec titleDictionary]) {
			NSMutableDictionary *newTitles = [NSMutableDictionary dictionary];
			for(NSString *key in [spec titleDictionary]) {
				NSString *value = [[spec titleDictionary] objectForKey:key];
				[newTitles setObject:[[self bundle] localizedStringForKey:value value:value table:nil] forKey:key];
			}
			[spec setTitleDictionary:newTitles];
		}
		NSString *value = [spec propertyForKey:@"footerText"];
		if(value)
			[spec setProperty:[[self bundle] localizedStringForKey:value value:value table:nil] forKey:@"footerText"];
		value = [spec propertyForKey:@"prompt"];
		if(value)
			[spec setProperty:[[self bundle] localizedStringForKey:value value:value table:nil] forKey:@"prompt"];
		value = [spec propertyForKey:@"okTitle"];
		if(value)
			[spec setProperty:[[self bundle] localizedStringForKey:value value:value table:nil] forKey:@"okTitle"];
		value = [spec propertyForKey:@"cancelTitle"];
		if(value)
			[spec setProperty:[[self bundle] localizedStringForKey:value value:value table:nil] forKey:@"cancelTitle"];
		if([spec isKindOfClass:[PSTextFieldSpecifier class]]) {
			value = [(PSTextFieldSpecifier *)spec placeholder];
			if(value)
				[(PSTextFieldSpecifier *)spec setPlaceholder:[[self bundle] localizedStringForKey:value value:value table:nil]];
		}
	}
	[(NSMutableArray*)specifiers removeObjectsInArray:removals];
	return specifiers;
}

- (id)specifiers {
	if(!_specifiers) {
		NSString *plist = [self.specifier propertyForKey:@"plist"] ?: @"SafariDownloader";
		_specifiers = [[self loadSpecifiersFromPlistName:plist target:self] retain];
	}
	return _specifiers;
}
@end

@implementation SDSettingsController
+ (void)load {
	_legacy = ![UIDevice instancesRespondToSelector:@selector(isWildcat)];
}

// I realize that an instance controlling global state is a bad idea. I'm truly sorry. :(
- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		[SDFileType loadAllFileTypes];
	}
	return self;
}

- (void)dealloc {
	[SDFileType unloadAllFileTypes];
	[super dealloc];
}
@end

// vim:ft=objc
