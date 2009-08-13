#import "FileBrowser.h"
#import "ModalAlert.h"
#import "Resources.h" 
#import <QuartzCore/QuartzCore.h>

#define HOME_DIR @"/private/var/mobile/Library/Attachments"
#define kNewFolderAlert 239530

extern UIImage *_UIImageWithName(NSString *);

@implementation FileBrowser

@synthesize context, data, currentPath, attachment;
@synthesize browserDelegate = _browserDelegate;

+ (FileBrowser*)activeInstance {
  return activeInstance; 
}

+ (BOOL)alertViewShown {
  return alertViewShown; 
}

- (id)initWithAttachment:(id)att 
                 context:(id)ctx 
                delegate:(id)del
{  
  NSString *messageString = [self resizeToFitCount:1];
  if (self = [super initWithTitle:@"Attachments\n\n\n\n" 
                          message:messageString 
                         delegate:self 
                cancelButtonTitle:@"Cancel" 
                otherButtonTitles:@"Save", nil]) 
  {
    self.attachment = att;
    self.browserDelegate = del;
    self.context = ctx;
    self.currentPath = HOME_DIR;
    [self prepare];
    activeInstance = self;
  }
  return self;
}

- (void)setCurrentPath:(NSString*)path {
  [currentPath release];
  currentPath = [path copy];
  if (path == nil) {
    return;
  }
  NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:path];
  self.title = [[currentPath lastPathComponent] stringByAppendingString:@"\n\n\n\n"];
  [navButton setTitle:[[currentPath stringByDeletingLastPathComponent] lastPathComponent]];
  if ([currentPath isEqualToString:HOME_DIR]) {
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
  tableHeight = 135;
  return messageString;
}

- (void)setData:(NSArray*)dat {
  [data release];
  data = [dat copy];
  [self setMessage:[self resizeToFitCount:[dat count]]];
  [myTableView reloadData];
}

- (void)alertView:(UIAlertView *)alert 
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alert.tag == kNewFolderAlert) {
    if (buttonIndex != [alert cancelButtonIndex])
    {
      NSString *entered = [(AlertPrompt *)alert enteredText];
      BOOL success =[[NSFileManager defaultManager] createDirectoryAtPath:[currentPath stringByAppendingPathComponent:entered]
                                                 attributes:nil];
      if (success) {
        self.currentPath = [currentPath stringByAppendingPathComponent:entered];
      }
    }
  }
  else {
    alertViewShown = NO;
    activeInstance = nil;
    
    if (buttonIndex == 1) {
      [_browserDelegate fileBrowser:self 
                      didSelectPath:currentPath
                      forAttachment:attachment
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

-(void)show {
  alertViewShown = YES;
  [super show];
}

- (void)newFolder {
	AlertPrompt *prompt = [AlertPrompt alloc];
	prompt = [prompt initWithTitle:@"New Folder" 
                         message:@"Enter a name for the new folder" 
                        delegate:self 
               cancelButtonTitle:@"Cancel" 
                   okButtonTitle:@"OK"];
  prompt.tag = kNewFolderAlert;
	[prompt show];
	[prompt release];  
}

-(void)prepare {
  
  UIView* container = [[UIView alloc] initWithFrame:CGRectMake(11, 47, 261, tableHeight)];
  container.backgroundColor = [UIColor whiteColor];
  container.clipsToBounds = YES;
  [self addSubview:container];
  
  myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 261, tableHeight) 
                                             style:UITableViewStylePlain];
  
  myTableView.delegate = self;
  myTableView.dataSource = self;
  [container addSubview:myTableView];
  
  NSString* buttonTitle = nil;
  navButton = [[UINavigationButton alloc] initWithTitle:buttonTitle style:1];
  navButton.alpha = 0;
  [navButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
  navButton.frame = CGRectMake(15, 10, 70, 30);
  [self addSubview:navButton];
  
  UIImage* addImage = _UIImageWithName(@"UINavigationBarAddButton.png");
  UINavigationButton* newButton = [[UINavigationButton alloc] initWithImage:addImage style:0];
  [newButton addTarget:self action:@selector(newFolder) forControlEvents:UIControlEventTouchUpInside];
  newButton.frame = CGRectMake(236, 10, 34, 30);
  [self addSubview:newButton];
  
  UIImageView *imgView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 261, 4)] autorelease];
  imgView.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/AttachmentSaver/top.png"];
  [container addSubview:imgView];
  
  imgView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, tableHeight+66-23-47, 261, 4)] autorelease];
  imgView.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/AttachmentSaver/bottom.png"];
  [container addSubview:imgView];
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ABC"];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:@"ABC"] autorelease];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
  }  
  
  NSString* item = [data objectAtIndex:indexPath.row];
  NSString* full = [currentPath stringByAppendingPathComponent:item];
  
  cell.textLabel.text = item;
  
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir] && isDir) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.imageView.image = [Resources iconForFolder];
  }
  else {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.imageView.image = [Resources iconForExtension:[item pathExtension]];
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSString* item = [data objectAtIndex:indexPath.row];
  
  CATransition *animation = [CATransition animation];
  [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  [animation setDelegate:self];
  [animation setType:kCATransitionPush];
  [animation setSubtype:kCATransitionFromRight];
  [animation setDuration:0.3];
  [animation setFillMode:kCAFillModeForwards];
  [animation setRemovedOnCompletion:YES];
  [[myTableView layer] addAnimation:animation forKey:@"push"];
  self.currentPath = [currentPath stringByAppendingPathComponent:item];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [data count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 38.0f; 
}

-(void)dealloc {
  activeInstance = nil;
  self.data = nil;
  self.browserDelegate = nil;
  self.context = nil;
  [myTableView release];
  [super dealloc];
}

@end
