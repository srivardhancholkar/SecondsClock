#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *withSeconds(NSString *fmt) {
    if (!fmt || [fmt containsString:@"ss"]) return fmt;
    if ([fmt containsString:@"mm"]) return [fmt stringByReplacingOccurrencesOfString:@"mm" withString:@"mm:ss"];
    if ([fmt containsString:@"m"])  return [fmt stringByReplacingOccurrencesOfString:@"m"  withString:@"m:ss"];
    return fmt;
}

%hook SBStatusBarStateAggregator
- (void)_resetTimeItemFormatter {
    %orig;
    @try {
        for (NSString *k in @[@"_timeItemDateFormatter", @"_shortTimeItemDateFormatter"]) {
            NSDateFormatter *f = [(id)self valueForKey:k];
            if (f) f.dateFormat = withSeconds(f.dateFormat);
        }
    } @catch (__unused NSException *e) {}
}
- (void)_restartTimeItemTimer {
    %orig;
    @try {
        NSTimer *old = [(id)self valueForKey:@"_timeItemTimer"];
        if (old) [old invalidate];
        NSTimer *t = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(_updateTimeItems) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
        [(id)self setValue:t forKey:@"_timeItemTimer"];
    } @catch (__unused NSException *e) {}
}
%end

// DIAGNOSTIC: find which view renders the time and its font/ivars
%hook _UIStatusBarStringView
- (void)setText:(NSString *)text {
    %orig;
    @try {
        if (text && [text containsString:@":"] && text.length <= 12) {
            static BOOL logged = NO;
            if (!logged) {
                logged = YES;
                NSMutableString *s = [NSMutableString string];
                [s appendFormat:@"class=%@ text='%@'\n", [self class], text];
                @try { [s appendFormat:@"font(valueForKey _font)=%@\n", [(id)self valueForKey:@"_font"]]; } @catch(...){}
                unsigned ic=0; Ivar *iv=class_copyIvarList([self class],&ic);
                for(unsigned i=0;i<ic;i++) [s appendFormat:@"%s : %s\n", ivar_getName(iv[i]), ivar_getTypeEncoding(iv[i])];
                free(iv);
                [s writeToFile:@"/var/jb/tmp/clockfont.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    } @catch (__unused NSException *e) {}
}
%end
