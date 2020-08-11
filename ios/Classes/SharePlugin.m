// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SharePlugin.h"

@interface ShareStreamHandler ()
@property(nonatomic) FlutterEventSink shareSink;
@end

static NSString *const PLATFORM_CHANNEL = @"plugins.flutter.io/share";
static NSString *const STREAM = @"plugins.flutter.io/receiveshare";

@implementation FLTSharePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterEventChannel *eventChannel =
      [FlutterEventChannel eventChannelWithName:STREAM
                                  binaryMessenger:registrar.messenger];
  FlutterMethodChannel *shareChannel =
      [FlutterMethodChannel methodChannelWithName:PLATFORM_CHANNEL
                                  binaryMessenger:registrar.messenger];
    
  ShareStreamHandler *shareStreamHandler = [[ShareStreamHandler alloc] init];
  [eventChannel setStreamHandler:shareStreamHandler];

  [shareChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    if ([@"share" isEqualToString:call.method]) {
      NSDictionary *arguments = [call arguments];

        if ([arguments[@"text"] length] == 0 && arguments[@"is_multiple"] == false) {
        result(
            [FlutterError errorWithCode:@"error" message:@"Non-empty text expected" details:nil]);
        return;
      }

      NSNumber *originX = arguments[@"originX"];
      NSNumber *originY = arguments[@"originY"];
      NSNumber *originWidth = arguments[@"originWidth"];
      NSNumber *originHeight = arguments[@"originHeight"];

      CGRect originRect;
      if (originX != nil && originY != nil && originWidth != nil && originHeight != nil) {
        originRect = CGRectMake([originX doubleValue], [originY doubleValue],
                                [originWidth doubleValue], [originHeight doubleValue]);
      }

      [self share:call.arguments
          withController:[UIApplication sharedApplication].keyWindow.rootViewController
          atSource:originRect
          handler:shareStreamHandler];
      result(nil);
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
}

+ (void)share:(id)sharedItems
    withController:(UIViewController *)controller
    atSource:(CGRect)origin
    handler:(ShareStreamHandler*) shareStreamHandler {
  NSString *share_type = sharedItems[@"type"];
  NSDictionary *dict = [NSDictionary dictionaryWithDictionary:sharedItems];
  //NSLog(share_type);
  UIActivityViewController *activityViewController = nil;
  NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
  data[@"type"] = share_type;
  if ([share_type isEqualToString:@"image/*"])
  {
      NSMutableArray *items = [[NSMutableArray alloc]init];
      //NSLog(path);
      NSNumber *multiple = sharedItems[@"is_multiple"];
      if ([multiple boolValue] == true) {
          int i = 0;
          while ([[dict allKeys] containsObject:[@(i) stringValue]]) {
              NSString *text = [dict objectForKey:[@(i) stringValue]];
              UIImage *image = [UIImage imageWithContentsOfFile:text];
              [items addObject:image];
              data[[@(i) stringValue]] = text;
              i++;
          }
          data[@"count"] = @(i);
          data[@"is_multiple"] = @(true);
      } else {
          NSString *path = sharedItems[@"path"];
          UIImage *image = [UIImage imageWithContentsOfFile:path];
          [items addObject:image];
          data[@"path"] = path;
      }
      activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:items
                                              applicationActivities:nil];
  } 
  else if ([share_type isEqualToString:@"*/*"])
  {
      NSMutableArray *items = [[NSMutableArray alloc]init];
      //NSLog(path);
      NSNumber *multiple = sharedItems[@"is_multiple"];
      if ([multiple boolValue] == true) {
          int i = 0;
          while ([[dict allKeys] containsObject:[@(i) stringValue]]) {
              NSString *text = [dict objectForKey:[@(i) stringValue]];
              NSURL *url = [NSURL fileURLWithPath:text];
              [items addObject:url];
              data[[@(i) stringValue]] = text;
              i++;
          }
          data[@"count"] = @(i);
          data[@"is_multiple"] = @(true);
      } else {
          NSString *path = sharedItems[@"path"];
          NSURL *url = [NSURL fileURLWithPath:path];
          [items addObject:url];
          data[@"path"] = path;
      }
      activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:items
                                              applicationActivities:nil];
  } 
  else if ([share_type isEqualToString:@"text/plain"])
  {
      NSMutableArray *items = [[NSMutableArray alloc]init];
      NSNumber *multiple = sharedItems[@"is_multiple"];
      if ([multiple boolValue] == true) {
          int i = 0;
          while ([[dict allKeys] containsObject:[@(i) stringValue]]) {
              NSString *text = [dict objectForKey:[@(i) stringValue]];
              [items addObject:text];
              data[[@(i) stringValue]] = text;
              i++;
          }
          data[@"count"] = @(i);
          data[@"is_multiple"] = @(true);
      } else {
          NSString *text = sharedItems[@"text"];
          [items addObject:text];
          data[@"text"] = text;
      }
      activityViewController =
          [[UIActivityViewController alloc] initWithActivityItems:items
                                            applicationActivities:nil];
  } 
  else
  {
      NSLog(@"Unknown mimetype");
  }
    activityViewController.popoverPresentationController.sourceView = controller.view;
    if (!CGRectIsEmpty(origin)) {
        activityViewController.popoverPresentationController.sourceRect = origin;
    }
    activityViewController.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        if(activityType) {
            data[@"package"] = activityType;
            [shareStreamHandler send:data];
        }
    };

    [controller presentViewController:activityViewController animated:YES completion: nil];
}

@end

@implementation ShareStreamHandler

- (void)send:(NSDictionary*)data {
    if(self.shareSink) {
        self.shareSink(data);
    }
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.shareSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.shareSink = nil;
    return nil;
}

@end
