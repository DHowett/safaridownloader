#import "SDMCommon.h"
#import "SDDownloadModel.h"

#import <SandCastle/SandCastle.h>
#import "SDSafariDownload.h"

@interface SDDownloadModel ()
- (NSMutableArray *)_arrayForListType:(SDDownloadModelList)list keyName:(NSString **)keyNamePtr;
@end

@implementation SDDownloadModel
@synthesize runningDownloads = _runningDownloads, finishedDownloads = _finishedDownloads;
static NSString *_archivePath;
+ (NSString *)archivePath {
	if(_archivePath) return _archivePath;
	NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
	_archivePath = [[[cacheURL path] stringByAppendingPathComponent:@"net.howett.safaridownloader.plist"] retain];
	return _archivePath;
}

- (id)init {
	if((self = [super init]) != nil) {
		_runningDownloads = [[NSMutableArray alloc] init];
		_finishedDownloads = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveData) name:UIApplicationWillTerminateNotification object:nil];
	} return self;
}

- (void)loadData {
	NSString *path = @"/tmp/.sdm.plist";
	[[SDM$SandCastle sharedInstance] removeItemAtResolvedPath:path];
	[[SDM$SandCastle sharedInstance] copyItemAtPath:[[self class] archivePath] toPath:path];
	NSDictionary *loaded = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	if(loaded) {
		[_runningDownloads addObjectsFromArray:[loaded objectForKey:@"running"]];
		[_finishedDownloads addObjectsFromArray:[loaded objectForKey:@"finished"]];
	}
	NSLog(@"loaded %@", loaded);
}

- (void)saveData {
	NSString *path = @"/tmp/.sdm.plist";
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:
			[NSDictionary dictionaryWithObjectsAndKeys:_runningDownloads, @"running",
								_finishedDownloads, @"finished", nil]];
	if(data) {
		[data writeToFile:path atomically:YES];
		[[SDM$SandCastle sharedInstance] removeItemAtResolvedPath:[[self class] archivePath]];
		[[SDM$SandCastle sharedInstance] copyItemAtPath:path toPath:[[self class] archivePath]];
	}
}

- (NSMutableArray *)_arrayForListType:(SDDownloadModelList)list keyName:(NSString **)keyNamePtr {
	switch(list) {
		case SDDownloadModelRunningList:
			if(keyNamePtr) *keyNamePtr = @"runningDownloads";
			return _runningDownloads;
		case SDDownloadModelFinishedList:
			if(keyNamePtr) *keyNamePtr = @"finishedDownloads";
			return _finishedDownloads;
	}
	return nil;
}

- (SDSafariDownload *)downloadWithURL:(NSURL*)url {
	for (SDSafariDownload *download in _runningDownloads) {
		if ([[download.URLRequest URL] isEqual:url])
			return download;
	}
	return nil; 
}

- (void)addDownload:(SDSafariDownload *)download toList:(SDDownloadModelList)list {
	NSString *keyName = nil;
	NSMutableArray *array = [self _arrayForListType:list keyName:&keyName];
	NSLog(@"Adding download %@ to list %@ key %@", download, array, keyName);
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:keyName];
	[array insertObject:download atIndex:0];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:keyName];
	[self saveData];
}

- (void)removeDownload:(SDSafariDownload *)download fromList:(SDDownloadModelList)list {
	NSString *keyName = nil;
	NSMutableArray *array = [self _arrayForListType:list keyName:&keyName];
	NSInteger index = [array indexOfObjectIdenticalTo:download];
	if(index == NSNotFound) return;
	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:keyName];
	[array removeObjectAtIndex:index];
	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:keyName];
	[self saveData];
}

- (void)emptyList:(SDDownloadModelList)list {
	NSString *keyName = nil;
	NSMutableArray *array = [self _arrayForListType:list keyName:&keyName];
	NSRange removals = (NSRange){0, array.count};
	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:removals] forKey:keyName];
	[array removeAllObjects];
	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:removals] forKey:keyName];
	[self saveData];
}

- (void)moveDownload:(SDSafariDownload *)download toList:(SDDownloadModelList)list {
	[download retain];
	NSMutableArray *target = [self _arrayForListType:list keyName:NULL];
	if(![target containsObject:download]) {
		[self removeDownload:download fromList:(list == SDDownloadModelFinishedList ? SDDownloadModelRunningList : SDDownloadModelFinishedList)];
		[self addDownload:download toList:list];
	}
	[download release];
}

- (NSIndexPath *)indexPathForDownload:(SDSafariDownload *)download {
	int row = -1;
	if((row = [_runningDownloads indexOfObjectIdenticalTo:download]) != NSNotFound) {
		return [NSIndexPath indexPathForRow:row inSection:0];
	} else if((row = [_finishedDownloads indexOfObjectIdenticalTo:download]) != NSNotFound) {
		return [NSIndexPath indexPathForRow:row inSection:1];
	}
	return nil;
}
@end
