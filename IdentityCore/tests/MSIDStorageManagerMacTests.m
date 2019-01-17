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

#import <XCTest/XCTest.h>
#import "MSIDAccountCacheItem.h"
#import "MSIDTestIdentifiers.h"
#import "NSDictionary+MSIDTestUtil.h"
#import "MSIDClientInfo.h"
#import "MSIDStorageManagerMac.h"

@interface MSIDStorageManagerMacTests : XCTestCase

@end

@implementation MSIDStorageManagerMacTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testStorageManagerMac_writeAccount {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    MSIDAccountCacheItem *account = [MSIDAccountCacheItem new];
    account.environment = DEFAULT_TEST_ENVIRONMENT;
    account.realm = @"contoso.com";
    account.additionalAccountFields = @{@"test": @"test2",
                                        @"test3": @"test4"};
    account.localAccountId = @"0000004-0000004-000004";
    account.givenName = @"First name";
    account.familyName = @"Last name";
    account.accountType = MSIDAccountTypeMSSTS;
    account.homeAccountId = @"uid.utid";
    account.username = @"username";
    account.alternativeAccountId = @"alt";
    account.name = @"test user";

    MSIDStorageManagerMac *storage = [MSIDStorageManagerMac new];
    NSError* error;
    __unused BOOL result = [storage writeAccount:nil account:account error:&error];
    
}

#if 0
- (void)testKeychain {
    SecKeyRef key =  a key ;
    NSData* tag = [@"com.example.keys.mykey" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* addquery = @{ (id)kSecValueRef: (__bridge id)key,
                                (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                };
}

#endif

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
