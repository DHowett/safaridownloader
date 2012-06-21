#import "FileBrowser.h"
#import "ModalAlert.h"
#import "SDResources.h"
#import "SDFileType.h"
#import <QuartzCore/QuartzCore.h>
#import "SDDownloadManager.h"
#import "UIKitExtra/UIKeyboard.h"

#import "Safari/BrowserController.h"

#import <SandCastle/SandCastle.h>

#define HOME_DIR @"/private/var/mobile/Media/Downloads/"
#define kNewFolderAlert 239530

extern UIImage *_UIImageWithName(NSString *);
void UIKeyboardEnableAutomaticAppearance(void);
void UIKeyboardDisableAutomaticAppearance(void);

static YFFileBrowser* activeInstance;
static BOOL alertViewShown;

@interface YFPathObject : NSObject {
  NSString* name;
  NSString* fullpath;
  BOOL isDir;
  UIImage*	icon;
}
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* fullpath;
@property (nonatomic, retain) UIImage* icon;
@property (assign) BOOL isDir;

+ (id)objectWithName:(NSString*)n path:(NSString*)p isDir:(BOOL)dir;
- (id)initWithName:(NSString*)n path:(NSString*)p isDir:(BOOL)dir;
@end

@implementation YFPathObject
@synthesize name, fullpath, isDir, icon;

+ (id)objectWithName:(NSString*)n path:(NSString*)p isDir:(BOOL)dir {
  return [[[YFPathObject alloc] initWithName:n path:p isDir:dir] autorelease]; 
}

- (id)initWithName:(NSString*)n path:(NSString*)p isDir:(BOOL)dir {
  if ((self = [super init])) {
	self.name = n;
	self.fullpath = p;
	self.isDir = dir;
	self.icon = dir ? [SDResources iconForFolder] : 
			  [SDResources iconForFileType:[SDFileType fileTypeForExtension:[n pathExtension]]];
  }
  return self;
}

@end

@implementation YFFileBrowser

@synthesize context, data, currentPath, file;
@synthesize browserDelegate = _browserDelegate;

+ (YFFileBrowser*)activeInstance {
  return activeInstance; 
}

+ (BOOL)alertViewShown {
  return alertViewShown; 
}

- (id)initWithFile:(id)fil 
           context:(id)ctx 
          delegate:(id)del {  
  NSString *messageString = [self resizeToFitCount:1];
  //if ((self = [super initWithTitle:@"Downloads\n\n\n\n" 
  if ((self = [super initWithTitle:@"Downloads" 
						   message:messageString 
						  delegate:self 
				 cancelButtonTitle:@"Cancel" 
				 otherButtonTitles:@"Save", nil])) {
    self.file = fil;
    self.browserDelegate = del;
    self.context = ctx;
    self.currentPath = HOME_DIR;
    [self prepare];
    activeInstance = self;
  }
  return self;
}

- (void)enumerateForDirsInPath:(NSString*)path 
                     fillArray:(NSMutableArray*)array 
                      maxCount:(NSInteger)count {
  NSArray* list = [[objc_getClass("SandCastle") sharedInstance] directoryContentsAtPath:path];  
  NSMutableArray* aux = [NSMutableArray new];
  for (NSString* curFile in list) {
	if ([curFile hasPrefix:@"."])
	  continue;
	NSString* curPath = [path stringByAppendingPathComponent:curFile];
	if ([[objc_getClass("SandCastle") sharedInstance] pathIsDir:curPath])
	  [array addObject:[YFPathObject objectWithName:curFile path:curPath isDir:YES]];
	else
	  [aux addObject:curFile];
  }
  for (NSString* f in aux) {
	NSString* curPath = [path stringByAppendingPathComponent:f];
	[array addObject:[YFPathObject objectWithName:f path:curPath isDir:NO]];
  }
  [aux release];
}

- (void)setCurrentPath:(NSString*)path {
  [currentPath release];
  currentPath = [path copy];
  if (path == nil) {
    return;
  }
  
  NSMutableArray* temp = [NSMutableArray new];
  [self enumerateForDirsInPath:path fillArray:temp maxCount:0];
  NSArray *contents = [[temp copy] autorelease];
  [temp release];
  
  self.title = [[currentPath lastPathComponent] stringByAppendingString:@"\n\n\n\n"];
  [navButton setTitle:[[currentPath stringByDeletingLastPathComponent] lastPathComponent]];
  if ([currentPath isEqualToString:@"/private/var/mobile"] || 
	   [currentPath isEqualToString:@"/var/mobile"]) {
    navButton.alpha = 0;
  }
  else {
    navButton.alpha = 1;
  }
  self.data = contents;
}

- (NSString*)resizeToFitCount:(NSUInteger)count {
  NSString *messageString = nil;
  messageString = @"\n\n\n";
  tableHeight = 126;
  return messageString;
}

- (void)setData:(NSArray*)dat {
  [data release];
  data = [dat copy];
  [myTableView reloadData];
}

- (void)alertView:(UIAlertView *)alert 
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alert.tag == kNewFolderAlert) {
    if (buttonIndex != [alert cancelButtonIndex]) {
      NSString *entered = [(SDAlertPrompt *)alert enteredText];
	  Class SandCastle = objc_getClass("SandCastle");
	  [[SandCastle sharedInstance] createDirectoryAtResolvedPath:[currentPath stringByAppendingPathComponent:entered]];
	  self.currentPath = [currentPath stringByAppendingPathComponent:entered];
    }
  }
  else {
    //UIKeyboardDisableAutomaticAppearance();
    alertViewShown = NO;
    activeInstance = nil;
    
    if (buttonIndex == 1) {
      [_browserDelegate fileBrowser:self 
                      didSelectPath:currentPath
                            forFile:file
                        withContext:context];
    }
    else {
      [_browserDelegate fileBrowserDidCancel:self];
    }
  }
}

- (void)back {
  CATransition *animation = [CATransition animation];
  [animation setTimingFunction:
   [CAMediaTimingFunction 
    functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  [animation setDelegate:self];
  [animation setType:kCATransitionPush];
  [animation setSubtype:kCATransitionFromLeft];
  [animation setDuration:0.3];
  [animation setFillMode:kCAFillModeForwards];
  [animation setRemovedOnCompletion:YES];
  [[myTableView layer] addAnimation:animation forKey:@"push"];
  self.currentPath = [currentPath stringByDeletingLastPathComponent];
}

- (void)show {
  alertViewShown = YES;
  [super show];
}

- (void)newFolder {
  //UIKeyboardEnableAutomaticAppearance(); // w00t!
  SDAlertPrompt *prompt = [SDAlertPrompt alloc];
  prompt = [prompt initWithTitle:@"New Folder" 
                         message:@"Enter a name for the new folder" 
                        delegate:self 
               cancelButtonTitle:@"Cancel" 
                   okButtonTitle:@"OK"];
  prompt.tag = kNewFolderAlert;
  [prompt show];
  [prompt release];
}

- (void)prepare {
  
  UIView* container = [[UIView alloc] initWithFrame:CGRectMake(11, 47, 261, tableHeight)];
  container.backgroundColor = [UIColor whiteColor];
  container.clipsToBounds = YES;
  [self addSubview:container];
  
  myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 261, tableHeight) 
                                             style:UITableViewStylePlain];
  
  myTableView.delegate = self;
  myTableView.dataSource = self;
  [container addSubview:myTableView];
  
  NSString* buttonTitle = [[HOME_DIR stringByDeletingLastPathComponent] lastPathComponent];
  navButton = [[UINavigationButton alloc] initWithTitle:buttonTitle style:1];
  navButton.alpha = 1;
  [navButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
  navButton.frame = CGRectMake(15, 10, 70, 30);
  [self addSubview:navButton];
  
  UIImage* addImage = _UIImageWithName(@"UINavigationBarAddButton.png");
  UINavigationButton* newButton = [[UINavigationButton alloc] initWithImage:addImage style:0];
  [newButton addTarget:self action:@selector(newFolder) forControlEvents:UIControlEventTouchUpInside];
  newButton.frame = CGRectMake(236, 10, 34, 30);
  [self addSubview:newButton];
  [newButton release];
  
  UIImageView *shadows = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 261, tableHeight)];
  shadows.image = [_UIImageWithName(@"UIPopupAlertListShadow.png") stretchableImageWithLeftCapWidth:5 topCapHeight:7];
  [container addSubview:shadows];
  [shadows release];
}

- (UITableViewCell*)tableView:(UITableView *)tableView 
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ABC"];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:@"ABC"] autorelease];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
  }  
  
  YFPathObject* item = [data objectAtIndex:indexPath.row];
  cell.textLabel.text = item.name;
  cell.imageView.image = item.icon;
  
  if (item.isDir) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
  }
  else {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor grayColor];
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  YFPathObject* item = [data objectAtIndex:indexPath.row];
  if (!item.isDir)
    return;
  CATransition *animation = [CATransition animation];
  [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  [animation setDelegate:self];
  [animation setType:kCATransitionPush];
  [animation setSubtype:kCATransitionFromRight];
  [animation setDuration:0.3];
  [animation setFillMode:kCAFillModeForwards];
  [animation setRemovedOnCompletion:YES];
  [[myTableView layer] addAnimation:animation forKey:@"push"];
  self.currentPath = item.fullpath;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [data count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 38.0f; 
}

- (void)dealloc {
  activeInstance = nil;
  self.data = nil;
  self.browserDelegate = nil;
  self.context = nil;
  [myTableView release];
  [super dealloc];
}

@end
