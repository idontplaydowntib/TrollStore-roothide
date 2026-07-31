#import "TSApplicationsManager.h"
#import <TSUtil.h>
extern NSUserDefaults* trollStoreUserDefaults();

@implementation TSApplicationsManager

+ (instancetype)sharedInstance
{
    static TSApplicationsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TSApplicationsManager alloc] init];
    });
    return sharedInstance;
}

- (NSArray*)installedAppPaths
{
    return trollStoreInstalledAppBundlePaths();
}

- (NSError*)errorForCode:(int)code
{
    NSString* errorDescription = @"未知错误";
    switch(code)
    {
        // IPA install errors
        case 166:
        errorDescription = @"IPA 文件不存在或无法访问。";
        break;
        case 167:
        errorDescription = @"IPA 文件中似乎不包含任何应用。";
        break;
        case 168:
        errorDescription = @"解压 IPA 文件失败。";
        break;
        case 169:
        errorDescription = @"解压更新用的 tar 文件失败。";
        break;
        // App install errors
        case 170:
        errorDescription = @"为应用包创建容器失败。";
        break;
        case 171:
        errorDescription = @"设备上已安装了一个非 "APP_NAME@" 或 "OTHER_APP_NAME@" 的同标识符应用。如果你确定并非如此，可以选择强制安装。";
        break;
        case 172:
        errorDescription = @"该应用不包含 Info.plist 文件。";
        break;
        case 173:
        errorDescription = @"该应用未使用伪造的 CoreTrust 证书签名，且未安装 ldid。请在“设置”页安装 ldid 后重试。";
        break;
        case 174:
        errorDescription = @"应用的主可执行文件不存在。";
        break;
        case 175: {
            //if (@available(iOS 16, *)) {
            //    errorDescription = @"Failed to sign the app.";
            //}
            //else {
                errorDescription = @"应用签名失败：ldid 返回了非零状态码。";
            //}
        }
        break;
        case 176:
        errorDescription = @"应用的 Info.plist 缺少必要的字段。";
        break;
        case 177:
        errorDescription = @"标记应用为巨魔商店应用失败。";
        break;
        case 178:
        errorDescription = @"复制应用包失败。";
        break;
        case 179:
        errorDescription = @"你尝试安装的应用与设备上已安装的某个系统应用标识符相同。为避免可能的引导循环或其它问题，已阻止本次安装。";
        break;
        case 180:
        errorDescription = @"你尝试安装的应用主二进制文件已加密，无法对其应用 CoreTrust 绕过。请确保安装的是已脱壳（解密）的应用。";
        break;
        case 181:
        errorDescription = @"将应用加入图标缓存失败。";
        break;
        case 182:
        errorDescription = @"应用安装成功，但需要启用开发者模式才能运行。重启后请选择“打开”以启用开发者模式。";
        break;
        case 183:
        errorDescription = @"启用开发者模式失败。";
        break;
        case 184:
        errorDescription = @"应用安装成功，但其附带的部分二进制文件（如扩展、插件）仍处于加密状态。应用本身应可正常使用，但部分功能可能异常。";
        break;
        case 185:
        errorDescription = @"应用签名失败：CoreTrust 绕过返回了非零状态码。";
    }

    NSError* error = [NSError errorWithDomain:TrollStoreErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
    return error;
}

- (int)installIpa:(NSString*)pathToIpa force:(BOOL)force log:(NSString**)logOut
{
    NSMutableArray* args = [NSMutableArray new];
    [args addObject:@"install"];
    if(force)
    {
        [args addObject:@"force"];
    }
    NSNumber* installationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"installationMethod"];
    int installationMethodToUse = installationMethodToUseNum ? installationMethodToUseNum.intValue : 1;
    if(installationMethodToUse == 1)
    {
        [args addObject:@"custom"];
    }
    else
    {
        [args addObject:@"installd"];
    }
    [args addObject:pathToIpa];

    int ret = spawnRoot(rootHelperPath(), args, nil, logOut);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationsChanged" object:nil];
    return ret;
}

- (int)installIpa:(NSString*)pathToIpa
{
    return [self installIpa:pathToIpa force:NO log:nil];
}

- (int)uninstallApp:(NSString*)appId
{
    if(!appId) return -200;

    NSMutableArray* args = [NSMutableArray new];
    [args addObject:@"uninstall"];

    NSNumber* uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
    int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
    if(uninstallationMethodToUse == 1)
    {
        [args addObject:@"custom"];
    }
    else
    {
        [args addObject:@"installd"];
    }

    [args addObject:appId];

    int ret = spawnRoot(rootHelperPath(), args, nil, nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationsChanged" object:nil];
    return ret;
}

- (int)uninstallAppByPath:(NSString*)path
{
    if(!path) return -200;

    NSMutableArray* args = [NSMutableArray new];
    [args addObject:@"uninstall-path"];

    NSNumber* uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
    int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
    if(uninstallationMethodToUse == 1)
    {
        [args addObject:@"custom"];
    }
    else
    {
        [args addObject:@"installd"];
    }

    [args addObject:path];

    int ret = spawnRoot(rootHelperPath(), args, nil, nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationsChanged" object:nil];
    return ret;
}

- (BOOL)openApplicationWithBundleID:(NSString *)appId
{
    return [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:appId];
}

- (int)enableJITForBundleID:(NSString *)appId
{
    return spawnRoot(rootHelperPath(), @[@"enable-jit", appId], nil, nil);
}

- (int)changeAppRegistration:(NSString*)appPath toState:(NSString*)newState
{
    if(!appPath || !newState) return -200;
    return spawnRoot(rootHelperPath(), @[@"modify-registration", appPath, newState], nil, nil);
}

@end