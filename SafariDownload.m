//
//  SafariDownload.m
//  SafariDownload
//
//  Created by Youssef Francis on 7/21/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "SafariDownload.h"

@implementation SafariDownload
@synthesize
delegate    = _delegate,
urlReq      = _urlRequest,
startDate   = _startDate,
filename    = _filename, 
sizeString  = _sizeString,
timeString  = _timeString,
size        = _size,
progress    = _progress,
time        = _time_remaining,
speed       = _speed,
complete    = _complete;

- (id)initWithRequest:(NSURLRequest*)urlRequest 
                 name:(NSString *)name 
             delegate:(id)del
{
  if (self = [super init])
  {
    self.delegate   = del;
    self.urlReq     = urlRequest;
    self.startDate  = [NSDate date];
    self.filename   = name;
    self.sizeString = @"N/A";
    self.timeString = @"Calculating remaining time...";
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init])
  {
    self.urlReq     = [coder decodeObject];
    self.startDate  = [coder decodeObject];
    self.filename   = [coder decodeObject];
    self.sizeString = [coder decodeObject];
    self.timeString = [coder decodeObject];
    self.time       = [coder decodeIntForKey:  @"time"    ];
    self.progress   = [coder decodeFloatForKey:@"progress"];
    self.speed      = [coder decodeFloatForKey:@"speed"   ];
    self.size       = [coder decodeBoolForKey: @"size"    ];
    self.complete   = [coder decodeBoolForKey: @"complete"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  [coder encodeObject: _urlRequest     ];
  [coder encodeObject: _startDate      ];
  [coder encodeObject: _filename       ];
  [coder encodeObject: _sizeString     ];
  [coder encodeObject: _timeString     ];
  [coder encodeInt:    _time_remaining forKey:@"time"    ];
  [coder encodeFloat:  _progress       forKey:@"progress"];
  [coder encodeFloat:  _speed          forKey:@"speed"   ];
  [coder encodeInt:    _size           forKey:@"size"    ];
  [coder encodeBool:   _complete       forKey:@"complete"];
}

- (void)setSize:(NSInteger)length
{
  double rSize = (double)(length/((double)1024)); // kb
  NSString *ord = @"K";
  if (rSize > 1024.0) {
    ord = @"M";
    rSize /= (double)1024;
  }
  self.sizeString = [NSString stringWithFormat:@"%.1lf%@B", rSize, ord];
}

- (void)setProgress:(float)prog 
              speed:(float)spd
{
  self.progress = prog; self.speed = spd;
  [_delegate performSelectorOnMainThread:@selector(downloadDidUpdate:) withObject:self waitUntilDone:YES];
}

- (void)setComplete:(BOOL)comp
{
  _complete = comp;
  if (comp)
    [_delegate performSelectorOnMainThread:@selector(downloadDidFinish:) withObject:self waitUntilDone:NO];
}

- (void)downloadStarted
{
  [_delegate performSelectorOnMainThread:@selector(downloadDidBegin:) withObject:self waitUntilDone:NO];
}

- (void)downloadFailedWithError:(NSError *)err
{
  NSLog(@"FAILED WITH ERROR: %@", [err localizedDescription]);
  [_delegate performSelectorOnMainThread:@selector(downloadDidFail:) withObject:self waitUntilDone:NO];
}

- (BOOL)isEqual:(SafariDownload*)comparator
{
  if ([self.urlReq URL] == nil || [comparator.urlReq URL] == nil)
    return NO;
  return [[self.urlReq URL] isEqual:[comparator.urlReq URL]];
}

- (void) dealloc
{
  NSLog(@"SAFARI DOWNLOAD DEALLOC!");
  _delegate = nil;
  [_urlRequest release];
  [_filename release];
  [_sizeString release];
  [_timeString release];
  [super dealloc];
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
