//
//  WGURLSession.m
//  Sample
//
//  Created by 7owen on 16/3/14.
//  Copyright © 2016年 7owen. All rights reserved.
//

#import "WGURLSession.h"
#import "AFNetworking.h"

@interface WGURLSession ()

@property (nonatomic, strong) WGURLRequestContext *requestContext;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) id<WGURLSessionDomainResolution> _domainResolution;

@end

@implementation WGURLSession

+ (WGURLSession * (^)(WGURLRequestContext *requestContext))requestContext {
    return ^(WGURLRequestContext *requestContext){
        WGURLSession *session = [WGURLSession new];
        session.requestContext = requestContext;
        return session;
    };
}

+ (WGURLSession * (^)(NSURLRequest *request))request {
    return ^(NSURLRequest *request){
        WGURLSession *session = [WGURLSession new];
        session.request = request;
        return session;
    };
}

- (WGURLSession * (^)(id<WGURLSessionDomainResolution> domainResolution))domainResolution {
    return ^(id<WGURLSessionDomainResolution> domainResolution){
        self._domainResolution = domainResolution;
        return self;
    };
}

- (WGURLSession * (^)(WGURLSessionEditRequest requestBlock))editRequest {
    return ^(WGURLSessionEditRequest requestBlock){
        NSMutableURLRequest *request = [self.request mutableCopy];
        requestBlock(request);
        self.request = request;
        return self;
    };
}

- (WGURLSession * (^)(AFHTTPSessionManager *manager))sessionManager {
    return ^(AFHTTPSessionManager *manager){
        self.manager = manager;
        return self;
    };
}

- (WGURLSession * (^)(WGURLSessionCompletionHandler completionHandler))get {
    return ^(WGURLSessionCompletionHandler completionHandler){
        if (__domainResolution) {
            if (_request) {
                NSMutableURLRequest *request = [_request mutableCopy];
                NSString *ip = [__domainResolution queryWithDomain:request.URL.host];
                if (ip) {
                    [request addValue:request.URL.host forHTTPHeaderField:@"Host"];
                    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
                    urlComponents.host = ip;
                    request.URL = [urlComponents URL];
                }
                self.request = request;
            } else if (_requestContext) {
                _requestContext.connectIPAddress = [__domainResolution queryWithDomain:_requestContext.serverInfo.host];
            }
        }
        NSURLRequest *request = self.request;
        if (request) {
            AFHTTPSessionManager *manager = self.manager;
            if (!manager) {
                manager = [AFHTTPSessionManager manager];
            }
            NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                if (!error) {
                    NSLog(@"Response: %@", responseObject);
                    if (completionHandler) {
                        completionHandler(httpResponse, responseObject, nil);
                    }
                } else {
                    NSLog(@"Response code: %ld,error:%@ responseData:%@", (long)httpResponse.statusCode,error, responseObject);
                    if (completionHandler) {
                        completionHandler(httpResponse, responseObject, error);
                    }
                }
            }];
            [task resume];
        } else {
            completionHandler(nil, nil, nil);
        }
        return self;
    };
}

- (NSURLRequest*)request {
    if (!_request) {
        _request = [_requestContext generateURLRequest];
    }
    return _request;
}

@end
