// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDAccountCacheItem.h"
#import "MSIDClientInfo.h"
#import "MSIDStorageManagerMac.h"
#import "MSIDTestIdentifiers.h"
#import "NSDictionary+MSIDTestUtil.h"
#import <XCTest/XCTest.h>

@interface MSIDStorageManagerMacTests : XCTestCase {
    id<MSIDStorageManager> _storage;
}
@end

@implementation MSIDStorageManagerMacTests

- (void)setUp {
    _storage = [MSIDStorageManagerMac new];
}

- (void)tearDown {
    _storage = nil;
}

- (void)testStorageManagerMac_whenAccountWritten_updatesKeychain {
    MSIDAccountCacheItem *account = [MSIDAccountCacheItem new];
    account.environment = DEFAULT_TEST_ENVIRONMENT;
    account.realm = @"contoso.com";
    account.additionalAccountFields = @{@"test": @"test2", @"test3": @"test4"};
    account.localAccountId = @"0000004-0000004-000004";
    account.givenName = @"First name";
    account.familyName = @"Last name";
    account.accountType = MSIDAccountTypeMSSTS;
    account.homeAccountId = @"uid.utid";
    account.username = @"username";
    account.alternativeAccountId = @"alt";
    account.name = @"test user";

    NSError *error;
    BOOL result = [_storage writeAccount:nil account:account error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

@end
