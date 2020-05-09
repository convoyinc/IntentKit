//
//  INKActivityPresenter.m
//  INKOpenInKitDemo
//
//  Created by Michael Walker on 12/10/13.
//  Copyright (c) 2013 Mike Walker. All rights reserved.
//

#import "INKActivityPresenter.h"
#import "INKActivityViewController.h"
#import "IntentKit.h"
#import <MWLayoutHelpers/UIView+MWLayoutHelpers.h>

@interface INKActivityPresenter ()

@property (weak, nonatomic) UIViewController *presentingViewController;
@property (strong, nonatomic) UIView *shadeView;

@property (assign, nonatomic) UIModalPresentationStyle originalPresentingModalPresentationStyle;
@property (assign, nonatomic) UIModalPresentationStyle originalRootModalPresentationStyle;

@property (assign, nonatomic) BOOL originalRootProvidesPresentationContextTransitionStyle;
@property (assign, nonatomic) BOOL originalRootDefinesPresentationContext;

@property (copy, nonatomic) void (^completionBlock)(void);

@end

@implementation INKActivityPresenter

- (instancetype)initWithActivitySheet:(INKActivityViewController *)activitySheet {
    if (self = [super init]) {
        self.activitySheet = activitySheet;
        self.activitySheet.presenter = self;
        self.originalRootModalPresentationStyle = -1;
        self.originalPresentingModalPresentationStyle = -1;
    }
    return self;
}

- (instancetype)initWithActivity:(INKActivity *)activity {
    if (self = [super init]) {
        self.activity = activity;
        self.originalRootModalPresentationStyle = -1;
        self.originalPresentingModalPresentationStyle = -1;
    }
    return self;
}

- (BOOL)canPerformActivity {
    return self.activity || self.activitySheet.numberOfApplications > 0;
}

- (void)presentModally {
    UIViewController *top = IntentKit.sharedInstance.visibleViewController;
    [self presentModalActivitySheetFromViewController:top completion:nil];
}

- (void)presentModallyWithCompletion:(void(^)(void))completion {
    UIViewController *top = IntentKit.sharedInstance.visibleViewController;
    [self presentModalActivitySheetFromViewController:top completion:completion];
}

- (void)presentModalActivitySheetFromViewController:(UIViewController *)presentingViewController completion:(void (^)(void))completion {
    if (!self.canPerformActivity) return;

    self.completionBlock = completion;

    if (self.activity) {
        [self.activity performActivityInViewController:presentingViewController];
    } else if (self.activitySheet) {

        self.presentingViewController = presentingViewController;
        
        self.shadeView = [[UIView alloc] initWithFrame:self.presentingViewController.view.bounds];
        self.shadeView.backgroundColor = [UIColor blackColor];
        [self.presentingViewController.view addSubview:self.shadeView];

        BOOL isiOS8OrSuperior = [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f;

        if (!isiOS8OrSuperior) {
            self.originalRootModalPresentationStyle = UIApplication.sharedApplication.keyWindow.rootViewController.modalPresentationStyle;
            UIApplication.sharedApplication.keyWindow.rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            
            self.originalPresentingModalPresentationStyle = presentingViewController.modalPresentationStyle;
            presentingViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        }
        else {
            self.originalRootProvidesPresentationContextTransitionStyle = UIApplication.sharedApplication.keyWindow.rootViewController.providesPresentationContextTransitionStyle;
            self.originalRootDefinesPresentationContext = UIApplication.sharedApplication.keyWindow.rootViewController.definesPresentationContext;
            
            UIApplication.sharedApplication.keyWindow.rootViewController.providesPresentationContextTransitionStyle = YES;
            UIApplication.sharedApplication.keyWindow.rootViewController.definesPresentationContext = YES;
            [self.activitySheet setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        }
        
        [presentingViewController presentViewController:self.activitySheet animated:isiOS8OrSuperior completion:nil];
        
        self.shadeView.alpha = 0;
        CGPoint activitySheetOrigin = self.activitySheet.contentView.frame.origin;
        if (!isiOS8OrSuperior) {
            [self.activitySheet.contentView moveToPoint:CGPointMake(self.presentingViewController.view.left, self.presentingViewController.view.bottom)];
        }
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.shadeView.alpha = 0.4;
            if (!isiOS8OrSuperior) {
                [self.activitySheet.contentView moveToPoint:activitySheetOrigin];
            }
        } completion:nil];
}
}

- (void)presentActivitySheetFromViewController:(UIViewController *)presentingViewController popoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated completion:(void (^)(void))completion {
    if (!self.canPerformActivity) return;

    self.completionBlock = completion;

    if (self.activity) {
        [self.activity performActivityInViewController:presentingViewController];
    } else if (IntentKit.sharedInstance.isPad && self.activitySheet) {
        [self.activitySheet setModalPresentationStyle:UIModalPresentationPopover];
        [self.activitySheet.popoverPresentationController setSourceRect:rect];
        [self.activitySheet.popoverPresentationController setSourceView:view];
        [self.activitySheet.popoverPresentationController setPermittedArrowDirections:arrowDirections];

        self.presentingViewController = presentingViewController;
        [self.presentingViewController presentViewController:self.activitySheet animated:animated completion:self.completionBlock];
    } else {
        [self presentModalActivitySheetFromViewController:presentingViewController completion:self.completionBlock];
    }
}

- (void)presentActivitySheetFromViewController:(UIViewController *)presentingViewController popoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated completion:(void (^)(void))completion {
    if (!self.canPerformActivity) return;

    self.completionBlock = completion;

    if (self.activity) {
        [self.activity performActivityInViewController:presentingViewController];
    } else if (IntentKit.sharedInstance.isPad && self.activitySheet) {
        [self.activitySheet.popoverPresentationController setPermittedArrowDirections:arrowDirections];
        [self.activitySheet.popoverPresentationController setBarButtonItem:item];
        [self.activitySheet setModalPresentationStyle:UIModalPresentationPopover];

        self.presentingViewController = presentingViewController;
        [self.presentingViewController presentViewController:self.activitySheet animated:YES completion:completion];
    } else {
        [self presentModalActivitySheetFromViewController:presentingViewController completion:completion];
    }
}

- (void)dismissActivitySheetAnimated:(BOOL)animated {
    void (^animatedActions)(void) = ^{
        self.shadeView.alpha = 0;
        [self.activitySheet.view moveToPoint:CGPointMake(self.presentingViewController.view.left, self.presentingViewController.view.bottom)];
    };

    void (^completionActions)(BOOL finished) = ^(BOOL finished){
        [self.shadeView removeFromSuperview];

        if (self.originalPresentingModalPresentationStyle != -1) {
            self.presentingViewController.modalPresentationStyle = self.originalPresentingModalPresentationStyle;
        }

        if (self.originalRootModalPresentationStyle != -1) {
            UIApplication.sharedApplication.keyWindow.rootViewController.modalPresentationStyle = self.originalRootModalPresentationStyle;
        }
        
        BOOL isiOS8OrSuperior = [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f;
        if (isiOS8OrSuperior) {
            UIApplication.sharedApplication.keyWindow.rootViewController.providesPresentationContextTransitionStyle = self.originalRootProvidesPresentationContextTransitionStyle;
            UIApplication.sharedApplication.keyWindow.rootViewController.definesPresentationContext = self.originalRootDefinesPresentationContext;
        }

        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];

        if (self.completionBlock) {
            self.completionBlock();
            self.completionBlock = nil;
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations: animatedActions completion:completionActions];
    } else {
        animatedActions();
        completionActions(YES);
    }
}
@end
