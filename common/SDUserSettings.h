extern const NSString * const kSDUserSettingsReloadedNotification;
@interface SDUserSettings : NSObject {
	NSMutableDictionary *_settings;
}
+ (id)sharedInstance;
- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue;
- (NSInteger)integerForKey:(NSString *)key default:(NSInteger)defaultValue;
- (NSObject *)objectForKey:(NSObject *)key default:(NSObject *)defaultValue;
- (float)floatForKey:(NSString *)key default:(float)defaultValue;
- (NSArray *)arrayForKey:(NSString *)key;

- (void)setObject:(NSObject *)object forKey:(NSString *)key;

- (void)reloadSettings;
- (void)commit;
- (NSArray *)disabledItemNames;
- (NSDictionary *)customFileTypes;
@end
