extern const NSString * const kSDUserSettingsReloadedNotification;
@interface SDUserSettings : NSObject {
	NSDictionary *_settings;
}
+ (id)sharedInstance;
- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue;
- (NSInteger)integerForKey:(NSString *)key default:(NSInteger)defaultValue;
- (NSArray *)arrayForKey:(NSString *)key;

- (void)reloadSettings;
- (NSArray *)disabledItemNames;
- (NSDictionary *)customFileTypes;
@end
