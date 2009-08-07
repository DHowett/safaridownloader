//
//  SafariDownload.m
//  SafariDownload
//
//  Created by Youssef Francis on 7/21/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "SafariDownload.h"

#ifndef DEBUG
#define NSLog(...)
#endif

@implementation SafariDownload
@synthesize
delegate    = _delegate,
urlReq      = _urlRequest,
startDate   = _startDate,
filename    = _filename, 
mimetype    = _mimetype, 
sizeString  = _sizeString,
timeString  = _timeString,
size        = _size,
progress    = _progress,
time        = _time_remaining,
speed       = _speed,
useSuggest  = _useSuggested,
complete    = _complete,
failed      = _failed;

@synthesize downloadOperation;

- (id)initWithRequest:(NSURLRequest*)urlRequest 
                 name:(NSString *)name 
             delegate:(id)del
         useSuggested:(BOOL)use {
  if (self = [super init])
  {
    self.delegate   = del;
    self.urlReq     = urlRequest;
    self.startDate  = [NSDate date];
    self.filename   = name;
    self.sizeString = @"N/A";
    self.timeString = @"Calculating remaining time...";
    self.useSuggest = use;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
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
    self.useSuggest = [coder decodeBoolForKey: @"suggest" ];
    self.failed     = [coder decodeBoolForKey: @"failed"  ];
    self.mimetype   = [coder decodeObject];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
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
  [coder encodeBool:   _useSuggested   forKey:@"suggest" ];
  [coder encodeBool:   _failed         forKey:@"failed"  ];
  [coder encodeObject: _mimetype       ];
}

- (void)setDownloadSize:(NSInteger)length {
  [self setSize:length]; 
}

- (void)setSize:(NSInteger)length {
  double rSize = (double)(length/((double)1024)); // kb
  NSString *ord = @"K";
  if (rSize > 1024.0) {
    ord = @"M";
    rSize /= (double)1024;
  }
  self.sizeString = [NSString stringWithFormat:@"%.1lf%@B", rSize, ord];
}

- (void)setFilename:(NSString*)nam {
  [_filename release];
  _filename = [nam retain];
  if (_filename != nil) {
    [_delegate performSelectorOnMainThread:@selector(downloadDidProvideFilename:) withObject:self waitUntilDone:YES];
  }
}

- (void)setProgress:(float)prog 
              speed:(float)spd {
  self.progress = prog; self.speed = spd;
  [_delegate performSelectorOnMainThread:@selector(downloadDidUpdate:) withObject:self waitUntilDone:YES];
}

- (void)setComplete:(BOOL)comp
{
  _complete = comp;
  if (comp)
    [_delegate performSelectorOnMainThread:@selector(downloadDidFinish:) withObject:self waitUntilDone:NO];
}

- (void)downloadDidReceiveAuthenticationChallenge {
  [_delegate performSelectorOnMainThread:@selector(downloadDidReceiveAuthenticationChallenge:) withObject:self waitUntilDone:NO];
}

- (void)downloadStarted {
  [_delegate performSelectorOnMainThread:@selector(downloadDidBegin:) withObject:self waitUntilDone:NO];
}

- (void)downloadCancelled {
  [_delegate performSelectorOnMainThread:@selector(downloadDidCancel:) withObject:self waitUntilDone:NO];
}

- (void)downloadFailedWithError:(NSError *)err {
  NSLog(@"FAILED WITH ERROR: %@", [err localizedDescription]);
  self.failed = YES;
  [_delegate performSelectorOnMainThread:@selector(downloadDidFail:) withObject:self waitUntilDone:NO];
}

- (BOOL)isEqual:(SafariDownload*)comparator {
  if ([self.urlReq URL] == nil || [comparator.urlReq URL] == nil)
    return NO;
  return [[self.urlReq URL] isEqual:[comparator.urlReq URL]];
}

- (void) dealloc {
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