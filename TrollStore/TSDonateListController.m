#import "TSDonateListController.h"
#import <Preferences/PSSpecifier.h>

@implementation TSDonateListController


- (void)donateToAlfiePressed
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ko-fi.com/alfiecg_dev"] options:@{} completionHandler:^(BOOL success){}];
}

- (void)donateToOpaPressed
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=opa334@protonmail.com&item_name=TrollStore"] options:@{} completionHandler:^(BOOL success){}];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];
		
		PSSpecifier* alfieGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		alfieGroupSpecifier.name = @"Alfie";
		[alfieGroupSpecifier setProperty:@"Alfie 通过 patchdiffing 发现了新的 CoreTrust 漏洞（CVE-2023-41991），制作了 POC 二进制文件，并借助 ChOma 库实现了自动应用该漏洞，同时也为该库做出了贡献。" forKey:@"footerText"];
		[_specifiers addObject:alfieGroupSpecifier];

		PSSpecifier* alfieDonateSpecifier = [PSSpecifier preferenceSpecifierNamed:@"捐赠给 alfiecg_dev"
									target:self
									set:nil
									get:nil
									detail:nil
									cell:PSButtonCell
									edit:nil];
		alfieDonateSpecifier.identifier = @"donateToAlfie";
		[alfieDonateSpecifier setProperty:@YES forKey:@"enabled"];
		alfieDonateSpecifier.buttonAction = @selector(donateToAlfiePressed);
		[_specifiers addObject:alfieDonateSpecifier];

		PSSpecifier* opaGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		opaGroupSpecifier.name = @"Opa";
		[opaGroupSpecifier setProperty:@"Opa 开发了 ChOma 库，帮助利用它实现了漏洞的自动化应用，并将其集成到了巨魔商店中。" forKey:@"footerText"];
		[_specifiers addObject:opaGroupSpecifier];

		PSSpecifier* opaDonateSpecifier = [PSSpecifier preferenceSpecifierNamed:@"捐赠给 opa334"
									target:self
									set:nil
									get:nil
									detail:nil
									cell:PSButtonCell
									edit:nil];
		opaDonateSpecifier.identifier = @"donateToOpa";
		[opaDonateSpecifier setProperty:@YES forKey:@"enabled"];
		opaDonateSpecifier.buttonAction = @selector(donateToOpaPressed);
		[_specifiers addObject:opaDonateSpecifier];
	}
	[(UINavigationItem *)self.navigationItem setTitle:@"捐赠"];
	return _specifiers;
}

@end