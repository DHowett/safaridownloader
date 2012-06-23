@interface SpacedBarButtonItem: UIBarButtonItem
- (void)destroyPrecedingSpace;
@end

@interface SDDownloadButtonItem: SpacedBarButtonItem
- (void)setBadge:(NSString *)badge;
- (NSString *)badge;
@end
