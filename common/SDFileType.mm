#import "SDFileType.h"
#import "SDResources.h"

static NSMutableDictionary *_MIMEMapping;
static NSMutableDictionary *_extensionMapping;
#if SDFILETYPE_MAP_CATEGORIES == 1
static NSMutableDictionary *_categoryMapping;
#endif

@interface SDFileType ()
@property (nonatomic, copy) NSArray *MIMETypes;
@property (nonatomic, copy) NSArray *extensions;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *genericType;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, assign) BOOL forceExtensionUse;
@end

@implementation SDFileType
@synthesize MIMETypes = _MIMETypes, extensions = _extensions, name = _name, genericType = _genericType, category = _category, forceExtensionUse = _forceExtensionUse;

+ (void)loadAllFileTypes {
	_MIMEMapping = [[NSMutableDictionary alloc] init];
	_extensionMapping = [[NSMutableDictionary alloc] init];
#if SDFILETYPE_MAP_CATEGORIES == 1
	_categoryMapping = [[NSMutableDictionary alloc] init];
#endif

	NSDictionary *fileTypeMaster = [NSDictionary dictionaryWithContentsOfFile:[[SDResources supportBundle] pathForResource:@"FileTypes" ofType:@"plist"]];
	for(NSString *fileTypeName in [fileTypeMaster allKeys]) {
		SDFileType *newType = [[self alloc] initWithName:fileTypeName dictionary:[fileTypeMaster objectForKey:fileTypeName]];
		for(NSString *MIMEType in newType.MIMETypes) {
			[_MIMEMapping setObject:newType forKey:MIMEType];
		}
		for(NSString *extension in newType.extensions) {
			[_extensionMapping setObject:newType forKey:extension];
		}
#if SDFILETYPE_MAP_CATEGORIES == 1
		NSMutableArray *_categoryArray = (NSMutableArray *)[_categoryMapping objectForKey:newType.category];
		if(!_categoryArray) {
			_categoryArray = [NSMutableArray array];
			[_categoryMapping setObject:_categoryArray forKey:newType.category];
		}
		[_categoryArray addObject:newType];
#endif
		[newType release];
	}
}

+ (void)unloadAllFileTypes {
	[_MIMEMapping release];
	[_extensionMapping release];
#if SDFILETYPE_MAP_CATEGORIES == 1
	[_categoryMapping release];
#endif
}

+ (SDFileType *)fileTypeForMIMEType:(NSString *)MIMEType {
	return [_MIMEMapping objectForKey:MIMEType];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension {
	return [_extensionMapping objectForKey:extension];
}

+ (SDFileType *)fileTypeForExtension:(NSString *)extension orMIMEType:(NSString *)MIMEType {
	return [_extensionMapping objectForKey:extension] ?: [_MIMEMapping objectForKey:MIMEType];
}

#if SDFILETYPE_MAP_CATEGORIES == 1
+ (NSDictionary *)allCategories {
	return _categoryMapping;
}
#endif

- (id)initWithName:(NSString *)name dictionary:(NSString *)dictionary {
	if((self = [super init]) != nil) {
		self.name = name;
		self.MIMETypes = [dictionary valueForKey:@"Mimetypes"];
		self.extensions = [dictionary valueForKey:@"Extensions"];
		self.genericType = [dictionary valueForKey:@"GenericType"];
		self.category = [dictionary valueForKey:@"Category"];
		self.forceExtensionUse = [[dictionary valueForKey:@"ForceExtension"] boolValue];
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
	return [_MIMETypes objectAtIndex:0];
}
@end
