#import "TSSettingsListController.h"
#import <TSUtil.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListItemsController.h>
#import <TSPresentationDelegate.h>
#import "TSInstallationController.h"
#import "TSSettingsAdvancedListController.h"
#import "TSDonateListController.h"

@interface NSUserDefaults (Private)
- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;
@end
extern NSUserDefaults* trollStoreUserDefaults(void);

@implementation TSSettingsListController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:@"TrollStoreReloadSettingsNotification" object:nil];

#ifndef TROLLSTORE_LITE
	fetchLatestTrollStoreVersion(^(NSString* latestVersion)
	{
		NSString* currentVersion = [self getTrollStoreVersion];
		NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];
		if(result == NSOrderedAscending)
		{
			_newerVersion = latestVersion;
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self reloadSpecifiers];
			});
		}
	});

	//if (@available(iOS 16, *)) {} else {
		fetchLatestLdidVersion(^(NSString* latestVersion)
		{
			NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];
			NSString* ldidVersion = nil;
			NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
			if(ldidVersionData)
			{
				ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
			}
			
			if(![latestVersion isEqualToString:ldidVersion])
			{
				_newerLdidVersion = latestVersion;
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[self reloadSpecifiers];
				});
			}
		});
	//}

	if (@available(iOS 16, *))
	{
		_devModeEnabled = spawnRoot(rootHelperPath(), @[@"check-dev-mode"], nil, nil) == 0;
	}
	else
	{
		_devModeEnabled = YES;
	}
#endif
	[self reloadSpecifiers];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

#ifndef TROLLSTORE_LITE
		if(_newerVersion)
		{
			PSSpecifier* updateTrollStoreGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			updateTrollStoreGroupSpecifier.name = @"有可用更新";
			[_specifiers addObject:updateTrollStoreGroupSpecifier];

			PSSpecifier* updateTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"更新巨魔商店至 %@", _newerVersion]
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			updateTrollStoreSpecifier.identifier = @"updateTrollStore";
			[updateTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			updateTrollStoreSpecifier.buttonAction = @selector(updateTrollStorePressed);
			[_specifiers addObject:updateTrollStoreSpecifier];
		}

		if(!_devModeEnabled)
		{
			PSSpecifier* enableDevModeGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			enableDevModeGroupSpecifier.name = @"开发者模式";
			[enableDevModeGroupSpecifier setProperty:@"某些 App 需要启用开发者模式才能启动。此更改需要重启后才能生效。" forKey:@"footerText"];
			[_specifiers addObject:enableDevModeGroupSpecifier];

			PSSpecifier* enableDevModeSpecifier = [PSSpecifier preferenceSpecifierNamed:@"启用开发者模式"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			enableDevModeSpecifier.identifier = @"enableDevMode";
			[enableDevModeSpecifier setProperty:@YES forKey:@"enabled"];
			enableDevModeSpecifier.buttonAction = @selector(enableDevModePressed);
			[_specifiers addObject:enableDevModeSpecifier];
		}
#endif

		PSSpecifier* utilitiesGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		utilitiesGroupSpecifier.name = @"实用工具";

		NSString *utilitiesDescription = @"";
#ifdef TROLLSTORE_LITE
		if (shouldRegisterAsUserByDefault()) {
			utilitiesDescription = @"由于已安装 AppSync Unified，App 默认将注册为“用户”。\n\n";
		}
		else {
			utilitiesDescription = @"由于未安装 AppSync Unified，App 默认将注册为“系统”。当 App 失去其“系统”注册并停止工作时，在此处按 \"刷新 App 注册\" 即可修复它们。\n\n";
		}
#endif
		utilitiesDescription = [utilitiesDescription stringByAppendingString:@"如果 App 在安装后未立即出现，请在此处注销，之后它应会出现。"];

		[utilitiesGroupSpecifier setProperty:utilitiesDescription forKey:@"footerText"];
		[_specifiers addObject:utilitiesGroupSpecifier];

		PSSpecifier* respringButtonSpecifier = [PSSpecifier preferenceSpecifierNamed:@"注销"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		 respringButtonSpecifier.identifier = @"respring";
		[respringButtonSpecifier setProperty:@YES forKey:@"enabled"];
		respringButtonSpecifier.buttonAction = @selector(respringButtonPressed);

		[_specifiers addObject:respringButtonSpecifier];

		PSSpecifier* refreshAppRegistrationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"刷新 App 注册"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		refreshAppRegistrationsSpecifier.identifier = @"refreshAppRegistrations";
		[refreshAppRegistrationsSpecifier setProperty:@YES forKey:@"enabled"];
		refreshAppRegistrationsSpecifier.buttonAction = @selector(refreshAppRegistrationsPressed);

		[_specifiers addObject:refreshAppRegistrationsSpecifier];

		PSSpecifier* rebuildIconCacheSpecifier = [PSSpecifier preferenceSpecifierNamed:@"重建图标缓存"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
		 rebuildIconCacheSpecifier.identifier = @"uicache";
		[rebuildIconCacheSpecifier setProperty:@YES forKey:@"enabled"];
		rebuildIconCacheSpecifier.buttonAction = @selector(rebuildIconCachePressed);

		[_specifiers addObject:rebuildIconCacheSpecifier];

		NSArray *inactiveBundlePaths = trollStoreInactiveInstalledAppBundlePaths();
		if (inactiveBundlePaths.count > 0) {
			PSSpecifier* transferAppsSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"转移 %zu 个 "OTHER_APP_NAME@" %@", inactiveBundlePaths.count, inactiveBundlePaths.count > 1 ? @"App" : @"App"]
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSButtonCell
											edit:nil];
			transferAppsSpecifier.identifier = @"transferApps";
			[transferAppsSpecifier setProperty:@YES forKey:@"enabled"];
			transferAppsSpecifier.buttonAction = @selector(transferAppsPressed);

			[_specifiers addObject:transferAppsSpecifier];
		}

#ifndef TROLLSTORE_LITE
		//if (@available(iOS 16, *)) { } else {
			NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid"];
			NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];
			BOOL ldidInstalled = [[NSFileManager defaultManager] fileExistsAtPath:ldidPath];

			NSString* ldidVersion = nil;
			NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
			if(ldidVersionData)
			{
				ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
			}

			PSSpecifier* signingGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			signingGroupSpecifier.name = @"签名";

			if(ldidInstalled)
			{
				[signingGroupSpecifier setProperty:@"ldid 已安装，允许巨魔商店安装未签名的 IPA 文件。" forKey:@"footerText"];
			}
			else
			{
				[signingGroupSpecifier setProperty:@"为了让巨魔商店能够安装未签名的 IPA，必须通过此按钮安装 ldid。由于许可证问题，它无法直接内置于巨魔商店中。" forKey:@"footerText"];
			}

			[_specifiers addObject:signingGroupSpecifier];

			if(ldidInstalled)
			{
				NSString* installedTitle = @"ldid：已安装";
				if(ldidVersion)
				{
					installedTitle = [NSString stringWithFormat:@"%@ (%@)", installedTitle, ldidVersion];
				}

				PSSpecifier* ldidInstalledSpecifier = [PSSpecifier preferenceSpecifierNamed:installedTitle
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSStaticTextCell
												edit:nil];
				[ldidInstalledSpecifier setProperty:@NO forKey:@"enabled"];
				ldidInstalledSpecifier.identifier = @"ldidInstalled";
				[_specifiers addObject:ldidInstalledSpecifier];

				if(_newerLdidVersion && ![_newerLdidVersion isEqualToString:ldidVersion])
				{
					NSString* updateTitle = [NSString stringWithFormat:@"更新至 %@", _newerLdidVersion];
					PSSpecifier* ldidUpdateSpecifier = [PSSpecifier preferenceSpecifierNamed:updateTitle
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
					ldidUpdateSpecifier.identifier = @"updateLdid";
					[ldidUpdateSpecifier setProperty:@YES forKey:@"enabled"];
					ldidUpdateSpecifier.buttonAction = @selector(installOrUpdateLdidPressed);
					[_specifiers addObject:ldidUpdateSpecifier];
				}
			}
			else
			{
				PSSpecifier* installLdidSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安装 ldid"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				installLdidSpecifier.identifier = @"installLdid";
				[installLdidSpecifier setProperty:@YES forKey:@"enabled"];
				installLdidSpecifier.buttonAction = @selector(installOrUpdateLdidPressed);
				[_specifiers addObject:installLdidSpecifier];
			}
		//}

		PSSpecifier* persistenceGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		persistenceGroupSpecifier.name = @"持久化";
		[_specifiers addObject:persistenceGroupSpecifier];

		if([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"])
		{
			[persistenceGroupSpecifier setProperty:@"当 iOS 重建图标缓存时，所有巨魔商店 App（包括巨魔商店自身）都会被还原为“用户”状态，从而消失或无法启动。如果发生这种情况，你可以使用主屏幕上的 TrollHelper App 刷新 App 注册，让它们重新可用。" forKey:@"footerText"];
			PSSpecifier* installedPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"助手已作为独立 App 安装"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSStaticTextCell
											edit:nil];
			[installedPersistenceHelperSpecifier setProperty:@NO forKey:@"enabled"];
			installedPersistenceHelperSpecifier.identifier = @"persistenceHelperInstalled";
			[_specifiers addObject:installedPersistenceHelperSpecifier];
		}
		else
		{
			LSApplicationProxy* persistenceApp = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);
			if(persistenceApp)
			{
				NSString* appName = [persistenceApp localizedName];

				[persistenceGroupSpecifier setProperty:[NSString stringWithFormat:@"当 iOS 重建图标缓存时，所有巨魔商店 App（包括巨魔商店自身）都会被还原为“用户”状态，从而消失或无法启动。如果发生这种情况，你可以使用已安装到 %@ 的持久化助手刷新 App 注册，让它们重新可用。", appName] forKey:@"footerText"];
				PSSpecifier* installedPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"助手已安装到 %@", appName]
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSStaticTextCell
												edit:nil];
				[installedPersistenceHelperSpecifier setProperty:@NO forKey:@"enabled"];
				installedPersistenceHelperSpecifier.identifier = @"persistenceHelperInstalled";
				[_specifiers addObject:installedPersistenceHelperSpecifier];

				PSSpecifier* uninstallPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载持久化助手"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];

				uninstallPersistenceHelperSpecifier.identifier = @"uninstallPersistenceHelper";
				[uninstallPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];
				[uninstallPersistenceHelperSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
				uninstallPersistenceHelperSpecifier.buttonAction = @selector(uninstallPersistenceHelperPressed);
				[_specifiers addObject:uninstallPersistenceHelperSpecifier];
			}
			else
			{
				[persistenceGroupSpecifier setProperty:@"当 iOS 重建图标缓存时，所有巨魔商店 App（包括巨魔商店自身）都会被还原为“用户”状态，从而消失或无法启动。在无根（rootless）环境中实现持久化的唯一方法是替换一个系统应用，你可以在此选择一个系统 App，将其替换为持久化助手，以便在相关巨魔商店 App 消失或无法启动时用它刷新所有 App 的注册。" forKey:@"footerText"];

				_installPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安装持久化助手"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				_installPersistenceHelperSpecifier.identifier = @"installPersistenceHelper";
				[_installPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];
				_installPersistenceHelperSpecifier.buttonAction = @selector(installPersistenceHelperPressed);
				[_specifiers addObject:_installPersistenceHelperSpecifier];
			}
		}
#endif

		PSSpecifier* installationSettingsGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		installationSettingsGroupSpecifier.name = @"安全";
		[installationSettingsGroupSpecifier setProperty:@"启用 URL Scheme 后，App 和网站即可通过 apple-magnifier://install?url=<IPA_URL> 触发巨魔商店安装，并通过 apple-magnifier://enable-jit?bundle-id=<BUNDLE_ID> 启用 JIT。" forKey:@"footerText"];

		[_specifiers addObject:installationSettingsGroupSpecifier];

		PSSpecifier* URLSchemeToggle = [PSSpecifier preferenceSpecifierNamed:@"启用 URL Scheme"
										target:self
										set:@selector(setURLSchemeEnabled:forSpecifier:)
										get:@selector(getURLSchemeEnabledForSpecifier:)
										detail:nil
										cell:PSSwitchCell
										edit:nil];

		[_specifiers addObject:URLSchemeToggle];

		PSSpecifier* installAlertConfigurationSpecifier = [PSSpecifier preferenceSpecifierNamed:@"显示安装确认弹窗"
										target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
										detail:nil
										cell:PSLinkListCell
										edit:nil];

		installAlertConfigurationSpecifier.detailControllerClass = [PSListItemsController class];
		[installAlertConfigurationSpecifier setProperty:@"installationConfirmationValues" forKey:@"valuesDataSource"];
        [installAlertConfigurationSpecifier setProperty:@"installationConfirmationNames" forKey:@"titlesDataSource"];
		[installAlertConfigurationSpecifier setProperty:APP_ID forKey:@"defaults"];
		[installAlertConfigurationSpecifier setProperty:@"installAlertConfiguration" forKey:@"key"];
        [installAlertConfigurationSpecifier setProperty:@0 forKey:@"default"];

		[_specifiers addObject:installAlertConfigurationSpecifier];

		PSSpecifier* otherGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		[otherGroupSpecifier setProperty:[NSString stringWithFormat:@"%@ %@\n\n© 2022-2026 Lars Fröder (opa334)\n\n巨魔商店严禁用于盗版！\n\n致谢：\nGoogle TAG, @alfiecg_dev：CoreTrust 漏洞\n@lunotech11, @SerenaKit, @tylinux, @TheRealClarity, @dhinakg, @khanhduytran0：各类贡献\n@ProcursusTeam：uicache、ldid\n@cstar_ow：uicache\n@saurik：ldid", APP_NAME, [self getTrollStoreVersion]] forKey:@"footerText"];
		[_specifiers addObject:otherGroupSpecifier];

		PSSpecifier* advancedLinkSpecifier = [PSSpecifier preferenceSpecifierNamed:@"高级"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSLinkListCell
										edit:nil];
		advancedLinkSpecifier.detailControllerClass = [TSSettingsAdvancedListController class];
		[advancedLinkSpecifier setProperty:@YES forKey:@"enabled"];
		[_specifiers addObject:advancedLinkSpecifier];

		PSSpecifier* donateSpecifier = [PSSpecifier preferenceSpecifierNamed:@"捐赠"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSLinkListCell
										edit:nil];
		donateSpecifier.detailControllerClass = [TSDonateListController class];
		[donateSpecifier setProperty:@YES forKey:@"enabled"];
		[_specifiers addObject:donateSpecifier];

#ifndef TROLLSTORE_LITE
		// Uninstall TrollStore
		PSSpecifier* uninstallTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载巨魔商店"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
		uninstallTrollStoreSpecifier.identifier = @"uninstallTrollStore";
		[uninstallTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
		[uninstallTrollStoreSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
		uninstallTrollStoreSpecifier.buttonAction = @selector(uninstallTrollStorePressed);
		[_specifiers addObject:uninstallTrollStoreSpecifier];
#endif
		/*PSSpecifier* doTheDashSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Do the Dash"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
		doTheDashSpecifier.identifier = @"doTheDash";
		[doTheDashSpecifier setProperty:@YES forKey:@"enabled"];
		uninstallTrollStoreSpecifier.buttonAction = @selector(doTheDashPressed);
		[_specifiers addObject:doTheDashSpecifier];*/
	}

	[(UINavigationItem *)self.navigationItem setTitle:@"设置"];
	return _specifiers;
}

- (NSArray*)installationConfirmationValues
{
	return @[@0, @1, @2];
}

- (NSArray*)installationConfirmationNames
{
	return @[@"始终（推荐）", @"仅在远程 URL 安装时", @"从不（不推荐）"];
}

- (void)respringButtonPressed
{
	respring();
}

- (void)installOrUpdateLdidPressed
{
	[TSInstallationController installLdid];
}

- (void)enableDevModePressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"arm-dev-mode"], nil, nil);

	if (ret == 0) {
		UIAlertController* rebootNotification = [UIAlertController alertControllerWithTitle:@"需要重启"
			message:@"重启后，选择“开启”即可启用开发者模式。"
			preferredStyle:UIAlertControllerStyleAlert
		];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
		{
			[self reloadSpecifiers];
		}];
		[rebootNotification addAction:closeAction];

		UIAlertAction* rebootAction = [UIAlertAction actionWithTitle:@"立即重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			spawnRoot(rootHelperPath(), @[@"reboot"], nil, nil);
		}];
		[rebootNotification addAction:rebootAction];

		[TSPresentationDelegate presentViewController:rebootNotification animated:YES completion:nil];
	} else {
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"错误 %d", ret] message:@"启用开发者模式失败。" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
		[errorAlert addAction:closeAction];

		[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
	}
}

- (void)installPersistenceHelperPressed
{
	NSMutableArray* appCandidates = [NSMutableArray new];
	[[LSApplicationWorkspace defaultWorkspace] enumerateApplicationsOfType:1 block:^(LSApplicationProxy* appProxy)
	{
		if(appProxy.installed && !appProxy.restricted)
		{
			if([[NSFileManager defaultManager] fileExistsAtPath:[@"/System/Library/AppSignatures" stringByAppendingPathComponent:appProxy.bundleIdentifier]])
			{
				NSURL* trollStoreMarkURL = [appProxy.bundleURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:TS_ACTIVE_MARKER];
				if(![trollStoreMarkURL checkResourceIsReachableAndReturnError:nil])
				{
					[appCandidates addObject:appProxy];
				}
			}
		}
	}];

	UIAlertController* selectAppAlert = [UIAlertController alertControllerWithTitle:@"选择 App" message:@"选择一个系统 App，用于安装巨魔商店持久化助手。该 App 原本的功能将不可用，因此建议选择一个用不到的 App，例如“提示” App。" preferredStyle:UIAlertControllerStyleActionSheet];
	for(LSApplicationProxy* appProxy in appCandidates)
	{
		UIAlertAction* installAction = [UIAlertAction actionWithTitle:[appProxy localizedName] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			spawnRoot(rootHelperPath(), @[@"install-persistence-helper", appProxy.bundleIdentifier], nil, nil);
			[self reloadSpecifiers];
		}];

		[selectAppAlert addAction:installAction];
	}

	NSIndexPath* indexPath = [self indexPathForSpecifier:_installPersistenceHelperSpecifier];
	UITableView* tableView = [self valueForKey:@"_table"];
	selectAppAlert.popoverPresentationController.sourceView = tableView;
	selectAppAlert.popoverPresentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
	[selectAppAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:selectAppAlert animated:YES completion:nil];
}

- (void)transferAppsPressed
{
	UIAlertController *confirmationAlert = [UIAlertController alertControllerWithTitle:@"转移 App" message:[NSString stringWithFormat:@"此操作会将 %zu 个 App 从 "OTHER_APP_NAME@" 转移到 "APP_NAME@"。是否继续？", trollStoreInactiveInstalledAppBundlePaths().count] preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* transferAction = [UIAlertAction actionWithTitle:@"转移" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[TSPresentationDelegate startActivity:@"正在转移"];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			NSString *log;
			int transferRet = spawnRoot(rootHelperPath(), @[@"transfer-apps"], nil, &log);

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					[self reloadSpecifiers];

					if (transferRet != 0) {
						NSArray *remainingApps = trollStoreInactiveInstalledAppBundlePaths();
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"转移失败" message:[NSString stringWithFormat:@"未能转移 %zu 个 App", remainingApps.count] preferredStyle:UIAlertControllerStyleAlert];

						UIAlertAction* copyLogAction = [UIAlertAction actionWithTitle:@"复制调试日志" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
						{
							UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
							pasteboard.string = log;
						}];
						[errorAlert addAction:copyLogAction];

						UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
						[errorAlert addAction:closeAction];

						[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
					}
				}];
			});
		});
	}];
	[confirmationAlert addAction:transferAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
	[confirmationAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
}

- (id)getURLSchemeEnabledForSpecifier:(PSSpecifier*)specifier
{
	BOOL URLSchemeActive = (BOOL)[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	return @(URLSchemeActive);
}

- (void)setURLSchemeEnabled:(id)value forSpecifier:(PSSpecifier*)specifier
{
	NSNumber* newValue = value;
	NSString* newStateString = [newValue boolValue] ? @"enable" : @"disable";
	spawnRoot(rootHelperPath(), @[@"url-scheme", newStateString], nil, nil);

	UIAlertController* rebuildNoticeAlert = [UIAlertController alertControllerWithTitle:@"URL Scheme 已更改" message:@"为正确应用 URL Scheme 设置的更改，需要重建图标缓存。" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction* rebuildNowAction = [UIAlertAction actionWithTitle:@"立即重建" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[self rebuildIconCachePressed];
	}];
	[rebuildNoticeAlert addAction:rebuildNowAction];

	UIAlertAction* rebuildLaterAction = [UIAlertAction actionWithTitle:@"稍后重建" style:UIAlertActionStyleCancel handler:nil];
	[rebuildNoticeAlert addAction:rebuildLaterAction];

	[TSPresentationDelegate presentViewController:rebuildNoticeAlert animated:YES completion:nil];
}

- (void)doTheDashPressed
{
	spawnRoot(rootHelperPath(), @[@"dash"], nil, nil);
}

- (void)setPreferenceValue:(NSObject*)value specifier:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	[tsDefaults setObject:value forKey:[specifier propertyForKey:@"key"]];
}

- (NSObject*)readPreferenceValue:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	NSObject* toReturn = [tsDefaults objectForKey:[specifier propertyForKey:@"key"]];
	if(!toReturn)
	{
		toReturn = [specifier propertyForKey:@"default"];
	}
	return toReturn;
}

- (NSMutableArray*)argsForUninstallingTrollStore
{
	NSMutableArray* args = @[@"uninstall-trollstore"].mutableCopy;

	NSNumber* uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
    int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
    if(uninstallationMethodToUse == 1)
    {
        [args addObject:@"custom"];
    }

	return args;
}

@end