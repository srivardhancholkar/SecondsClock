#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Add seconds to a date-format string by expanding the minutes field.
static NSString *withSeconds(NSString *fmt) {
    if (!fmt || [fmt containsString:@"ss"]) return fmt;
    if ([fmt containsString:@"mm"]) return [fmt stringByReplacingOccurrencesOfString:@"mm" withString:@"mm:ss"];
    if ([fmt containsString:@"m"])  return [fmt stringByReplacingOccurrencesOfString:@"m"  withString:@"m:ss"];
    return fmt;
}

%hook SBStatusBarStateAggregator

// Whenever the formatters are (re)built, inject seconds into them.
- (void)_resetTimeItemFormatter {
    %orig;
    @try {
        for (NSString *k in @[@"_timeItemDateFormatter", @"_shortTimeItemDateFormatter"]) {
            NSDateFormatter *f = [(id)self valueForKey:k];
            if (f) f.dateFormat = withSeconds(f.dateFormat);
        }
    } @catch (__unused NSException *e) {}
}

// The stock timer fires on the minute; replace it with a 1s repeating timer
// so the string (now containing seconds) refreshes every second.
- (void)_restartTimeItemTimer {
    %orig;
    @try {
        NSTimer *old = [(id)self valueForKey:@"_timeItemTimer"];
        if (old) [old invalidate];
        NSTimer *t = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(_updateTimeItems)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
        [(id)self setValue:t forKey:@"_timeItemTimer"];
    } @catch (__unused NSException *e) {}
}

%end
