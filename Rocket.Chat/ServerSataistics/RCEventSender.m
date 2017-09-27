//
//  RCEventSender.m
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import "RCEventSender.h"
#import <Foundation/Foundation.h>

@implementation RCEventSender
- (void)sendData:(NSData *)data {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
    urlRequest.HTTPMethod = @"POST";
    [urlRequest addValue:@"Basic c2Vla2luZ2FscGhhOmlwdmlwdg==" forHTTPHeaderField:@"Authorization"];
    urlRequest.HTTPBody = data;
    [[[NSURLSession sharedSession] dataTaskWithRequest:urlRequest] resume];
}
- (void)sendParams:(NSDictionary *)params {
    //NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
   // [urlRequest addValue:@"Basic c2Vla2luZ2FscGhhOmlwdmlwdg==" forHTTPHeaderField:@"Authorization"];
   // urlRequest.HTTPBody = ;
    [self.sessionManager POST:@"/mone_event" parameters:params progress:nil success:nil failure:nil];
    //[[[NSURLSession sharedSession] dataTaskWithRequest:urlRequest] resume];
}

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://rc.staging.seekingalpha.com"]];
    }
    return _sessionManager;
}

@end
/*
 var httpSessionManager: LogEventManager?
 func send(event: LogEvent?) {
 let httpBody = event?.convertToPost()
 self.post(httpBody: httpBody, url: event?.moneURL)
 }
 
 func post(httpBody: Data?, url: String?) {
 
 guard let httpBody = httpBody else {
 return
 }
 guard let url = url else {
 return
 }
 guard let serviceUrl = URL(string: url) else {
 return
 }
 var request = URLRequest(url: serviceUrl)
 request.httpMethod = "POST"
 request.addValue("Basic c2Vla2luZ2FscGhhOmlwdmlwdg==", forHTTPHeaderField: "Authorization")
 request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36", forHTTPHeaderField: "User-Agent")
 request.httpBody = httpBody
 
 let session = URLSession.shared
 session.dataTask(with: request) { (data, response, error) in
 if let response = response {
 print(">>>>>>> event sending response ")
 print(response)
 }
 if let data = data {
 do {
 let json = try JSONSerialization.jsonObject(with: data, options: [])
 print(json)
 //                    if let dict = json as? NSDictionary {
 //                        complition(dict)
 //                    }
 } catch {
 print(error)
 }
 }
 }.resume()
 }
 */
