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

%hook UILabel
- (void)setText:(NSString *)text {
    %orig;
    @try {
        if (text.length>=4 && text.length<=12 && [text containsString:@":"]) {
            unichar c0=[text characterAtIndex:0];
            UIFont *fnt=[(id)self font];
            if (c0>='0' && c0<='9' && fnt.pointSize < 40) {
                NSString *cls=NSStringFromClass([(id)self class]);
                static NSMutableSet *seen=nil; if(!seen) seen=[NSMutableSet set];
                NSString *key=[NSString stringWithFormat:@"%@|%.0f", cls, fnt.pointSize];
                if(![seen containsObject:key]){ [seen addObject:key];
                    NSMutableString *o=[NSMutableString string];
                    NSData *d=[NSData dataWithContentsOfFile:@"/var/jb/tmp/clocklabel.txt"];
                    if(d){ [o appendString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]]; }
                    [o appendFormat:@"=== %@  size=%.1f  text='%@'\n", cls, fnt.pointSize, text];
                    [o appendFormat:@"    font=%@\n", fnt];
                    UIView *v=(UIView*)self; int dd=0;
                    while(v && dd<7){ [o appendFormat:@"    ^ %@\n", NSStringFromClass([v class])]; v=[v superview]; dd++; }
                    [o writeToFile:@"/var/jb/tmp/clocklabel.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
        }
    } @catch (__unused NSException *e) {}
}
%end
%ctor {
    @autoreleasepool {
        @try {
            NSMutableString *out = [NSMutableString string];
            unsigned int n=0; Class *all=objc_copyClassList(&n);
            for(unsigned i=0;i<n;i++){
                const char *cn = class_getName(all[i]);
                if(!cn) continue;
                NSString *c = [NSString stringWithUTF8String:cn];
                NSString *lc = [c lowercaseString];
                BOOL timey = [lc containsString:@"time"] || [lc containsString:@"clock"] || [lc containsString:@"date"];
                BOOL viewy = [lc containsString:@"view"] || [lc containsString:@"label"] || [c hasPrefix:@"STUIStatusBar"] || [c hasPrefix:@"_UIStatusBar"];
                if(timey && viewy) [out appendFormat:@"%@\n", c];
            }
            free(all);
            [out writeToFile:@"/var/jb/tmp/clockclasses.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } @catch (__unused NSException *e) {}
    }
}
