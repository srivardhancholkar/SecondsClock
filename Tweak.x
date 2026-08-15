#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

static void dumpClass(NSMutableString *s, const char *clsname) {
    Class c = objc_getClass(clsname);
    if (!c) { [s appendFormat:@"\n(%s NOT FOUND)\n", clsname]; return; }
    [s appendFormat:@"\n===== %s methods =====\n", clsname];
    unsigned mc=0; Method *ms=class_copyMethodList(c,&mc);
    for(unsigned i=0;i<mc;i++) [s appendFormat:@"%s\n", sel_getName(method_getName(ms[i]))];
    free(ms);
    [s appendFormat:@"----- %s ivars -----\n", clsname];
    unsigned ic=0; Ivar *iv=class_copyIvarList(c,&ic);
    for(unsigned i=0;i<ic;i++) [s appendFormat:@"%s : %s\n", ivar_getName(iv[i]), ivar_getTypeEncoding(iv[i])];
    free(iv);
}

%ctor {
    @autoreleasepool {
        @try {
            NSMutableString *s = [NSMutableString string];
            [s appendFormat:@"proc=%@\n", [NSProcessInfo processInfo].processName];
            unsigned int n=0; Class *all=objc_copyClassList(&n);
            [s appendString:@"== classes with Time/Clock ==\n"];
            for(unsigned i=0;i<n;i++){ const char*cn=class_getName(all[i]);
                if(cn && (strcasestr(cn,"statusbar")&&(strcasestr(cn,"time")||strcasestr(cn,"clock")))) [s appendFormat:@"%s\n",cn]; }
            free(all);
            dumpClass(s,"SBStatusBarStateAggregator");
            [s writeToFile:@"/var/jb/tmp/clock_dump.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } @catch (__unused NSException *e) {}
    }
}
