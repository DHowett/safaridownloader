#include <Foundation/Foundation.h>

@class SandCastle, CPDistributedMessagingCenter;

@interface SandCastle : NSObject {
	CPDistributedMessagingCenter *center;
}

+ (SandCastle *)sharedInstance;
- (NSString *)temporaryPathForFileName:(NSString *)fileName;

- (NSArray*)directoryContentsAtPath:(NSString*)path;
- (BOOL)pathIsDir:(NSString*)path;
- (BOOL)fileExistsAtPath:(NSString*)path;

- (void)copyItemAtPath:(NSString*)path toPath:(NSString*)destination;
- (void)moveTemporaryFile:(NSString *)file toResolvedPath:(NSString *)path;
- (void)removeItemAtResolvedPath:(NSString *)path;
- (void)createDirectoryAtResolvedPath:(NSString *)path;

@end