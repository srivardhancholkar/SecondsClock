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

// Give the status-bar clock tabular (monospaced) digits so it doesn't jitter.
%hook _UIStatusBarStringView
- (void)applyStyleAttributes:(id)attrs {
    @try {
        NSString *ot = nil;
        @try { ot = [(id)self valueForKey:@"_originalText"]; } @catch(...){}
        if (ot && ot.length<=12 && [ot containsString:@":"] && attrs) {
            UIFont *f = nil;
            @try { f = [attrs valueForKey:@"font"]; } @catch(...){}
            if (f) {
                UIFontDescriptor *d = [f.fontDescriptor fontDescriptorByAddingAttributes:@{
                    UIFontDescriptorFeatureSettingsAttribute: @[@{
                        UIFontFeatureTypeIdentifierKey: @(6),      // kNumberSpacingType
                        UIFontFeatureSelectorIdentifierKey: @(0)   // kMonospacedNumbersSelector
                    }]}];
                UIFont *mono = [UIFont fontWithDescriptor:d size:f.pointSize];
                if (mono) { @try { [attrs setValue:mono forKey:@"font"]; } @catch(...){} }
                // one-time confirmation
                static BOOL logged=NO;
                if(!logged){ logged=YES;
                    [[NSString stringWithFormat:@"HIT applyStyleAttributes ot='%@' font=%@ attrsClass=%@\n", ot, f, NSStringFromClass([attrs class])]
                     writeToFile:@"/var/jb/tmp/mono.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
        }
    } @catch (__unused NSException *e) {}
    %orig(attrs);
}
%end
