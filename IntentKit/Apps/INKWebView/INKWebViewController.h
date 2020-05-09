//
//  INKWebViewController.h
//  Pods
//
//  Created by Michael Walker on 4/16/14.
//
//

@interface INKWebViewController : UIViewController

@property (nonatomic, copy) void (^closeBlock)(void);


- (void)loadURL:(NSURL *)url;

@end
