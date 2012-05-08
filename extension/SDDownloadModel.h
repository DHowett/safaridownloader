typedef enum {
	SDDownloadModelRunningList = 0,
	SDDownloadModelFinishedList,
} SDDownloadModelList;

@class SDSafariDownload;

@interface SDDownloadModel : NSObject {
	NSMutableArray *_runningDownloads;
	NSMutableArray *_finishedDownloads;
}
@property (nonatomic, retain, readonly) NSArray *runningDownloads;
@property (nonatomic, retain, readonly) NSArray *finishedDownloads;
- (id)init;
- (void)loadData;
- (void)saveData;
- (SDSafariDownload *)downloadWithURL:(NSURL*)url;
- (void)addDownload:(SDSafariDownload *)downloadi toList:(SDDownloadModelList)list;
- (void)removeDownload:(SDSafariDownload *)download fromList:(SDDownloadModelList)list;
- (void)emptyList:(SDDownloadModelList)list;
- (void)moveDownload:(SDSafariDownload *)download toList:(SDDownloadModelList)list;
- (NSIndexPath *)indexPathForDownload:(SDSafariDownload *)download;
@end
