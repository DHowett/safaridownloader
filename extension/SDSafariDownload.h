//
//  SDSafariDownload.h
//  SDSafariDownload
//
//  Created by Youssef Francis on 7/21/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//
// Dustin L. Howett (2012-01-31)

#import <Foundation/Foundation.h>
#import "NSURLDownload.h"
#import "SDConcurrentOperation.h"

typedef enum {
	SDDownloadStatusWaiting = 0,
	SDDownloadStatusAuthenticationWaiting,
	SDDownloadStatusRunning,
	SDDownloadStatusPaused,
	SDDownloadStatusCompleted,
	SDDownloadStatusCancelled,
	SDDownloadStatusFailed,
	SDDownloadStatusRetrying
} SDDownloadStatus;

extern NSString * const kSDSafariDownloadTemporaryDirectory;

@protocol SDSafariDownloadDelegate;

/*
 * WHAT DO I NEED:
 * A status
 * A start date.
 * A filename.
 * A directory.
 * A temporary filename because the download could have a different name.
 * A temporary path (/tmp/.partial)
 * Number of total bytes.
 * Number of downloaded bytes so far.
 * Number of downloaded bytes this session.
 * ^^^^^^ What byte we began the download from
 * Progress can be calculated from that.
 * Time remaining can be calculated from that.
 *
 * A URL Request.
 * Whether or not we're using the suggested filename?
 * How many times we have retried.
 * The last error that occurred.
 *
 * RESUME DATA.
 * Whether authentication is required.
 * Authentication Credentials (maybe)
 * The downloader object.
 * The URL Response (headers, why not?)
 *
 * WHAT NEEDS TO BE SERIALIZED? WHAT NEEDS TO DISPATCH CHANGE NOTIFICATIONS?
 */

@interface SDSafariDownload : SDConcurrentOperation <NSURLDownloadDelegate>
{
	// Of interest to Outsiders
	SDDownloadStatus _status; // Serialize.
	BOOL _useSuggestedFilename; // Serialize.
	NSString *_filename; // Serialize.
	NSString *_mimeType; // Serialize.
	NSString *_path; // Serialize.
	NSString *_temporaryPath; // Serialize.
	NSDate *_startDate; // Serialize.
	unsigned long long _totalBytes; // Serialize.
	unsigned long long _downloadedBytes; // Serialize.
	unsigned int _retryCount;
	NSError *_lastError;

	unsigned long long _startedFromByte;
	NSURLRequest *_URLRequest;
	NSURLResponse *_URLResponse;

	NSMutableDictionary *_resumeData; // Serialize.
	BOOL _requiresAuthentication;
	NSURLCredential *_authenticationCredential;

	NSURLDownload *_downloader;
}

@property (nonatomic, readonly, assign) SDDownloadStatus status;
@property (nonatomic, assign) BOOL useSuggestedFilename;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *mimeType;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, readonly, retain) NSString *temporaryPath;
@property (nonatomic, readonly, retain) NSDate *startDate;
@property (nonatomic, readonly, assign) unsigned long long totalBytes;
@property (nonatomic, readonly, assign) unsigned long long downloadedBytes;
@property (nonatomic, readonly, assign) unsigned int retryCount;
@property (nonatomic, readonly, retain) NSError *lastError;
@property (nonatomic, readonly, assign) unsigned long long startedFromByte;
@property (nonatomic, retain) NSURLRequest *URLRequest;
@property (nonatomic, readonly, retain) NSURLResponse *URLResponse;
@property (nonatomic, readonly, retain) NSMutableDictionary *resumeData;
@property (nonatomic, readonly, assign) BOOL requiresAuthentication;
@property (nonatomic, readonly, retain) NSURLCredential *authenticationCredential;
@property (nonatomic, readonly, retain) NSURLDownload *downloader;

@property (nonatomic, assign) NSObject<SDSafariDownloadDelegate> *delegate;

+ (NSFileManager*)fileManager;
- (id)initWithDownload:(SDSafariDownload *)download;

/*
- (id)initWithRequest:(NSURLRequest*)urlRequest name:(NSString *)name delegate:(id)del useSuggested:(BOOL)use;
- (void)downloadFailedWithError:(NSError *)err;
- (void)setProgress:(float)prog speed:(float)spd;
- (void)downloadStarted;
- (void)setRetryString:(NSString*)status;
*/

@end

@protocol SDSafariDownloadDelegate
@optional
- (void)downloadDidChangeStatus:(SDSafariDownload *)download;
- (void)downloadDidReceiveData:(SDSafariDownload *)download;
- (void)downloadDidUpdateMetadata:(SDSafariDownload *)download;
- (NSString *)uniqueFilenameForDownload:(SDSafariDownload *)download withSuggestion:(NSString *)suggestedFilename;
- (BOOL)downloadShouldRetry:(SDSafariDownload *)download;
- (float)retryDelayForDownload:(SDSafariDownload *)download;
- (void)download:(SDSafariDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

/*
- (void)downloadDidBegin:(SDSafariDownload*)download;
- (void)downloadDidProvideFilename:(SDSafariDownload*)download;
- (void)downloadDidFinish:(SDSafariDownload*)download;
- (void)downloadDidUpdate:(SDSafariDownload*)download;
- (void)downloadDidFail:(SDSafariDownload*)download;
- (void)downloadDidCancel:(SDSafariDownload*)download;
- (void)downloadWillRetry:(SDSafariDownload*)download;
*/

@end

//@interface MyAuthenticationView : AuthenticationView
//- (void)setSavedChallenge:(id)savedChallenge;
//@end
