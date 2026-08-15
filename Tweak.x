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

static void dumpCls(NSMutableString *o,const char*n){
    Class c=objc_getClass(n); if(!c){[o appendFormat:@"(%s nil)\n",n];return;}
    [o appendFormat:@"\n===== %s methods =====\n",n];
    unsigned m=0;Method*ms=class_copyMethodList(c,&m);
    for(unsigned i=0;i<m;i++)[o appendFormat:@"%s\n",sel_getName(method_getName(ms[i]))];free(ms);
    [o appendFormat:@"----- %s ivars -----\n",n];
    unsigned k=0;Ivar*iv=class_copyIvarList(c,&k);
    for(unsigned i=0;i<k;i++)[o appendFormat:@"%s : %s\n",ivar_getName(iv[i]),ivar_getTypeEncoding(iv[i])];free(iv);
}
%ctor {
    @autoreleasepool { @try {
        NSMutableString *o=[NSMutableString string];
        dumpCls(o,"_UIStatusBarStringView");
        [o writeToFile:@"/var/jb/tmp/sbstring.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } @catch (__unused NSException *e) {} }
}
