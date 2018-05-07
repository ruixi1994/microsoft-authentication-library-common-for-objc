//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "MSIDTokenCacheItem.h"
#import "MSIDTokenFilteringHelper.h"
#import "MSIDBaseToken.h"
#import "MSIDAccessToken.h"
#import "MSIDTestCacheIdentifiers.h"
#import "MSIDTestConfiguration.h"
#import "MSIDAccount.h"
#import "MSIDTestIdTokenUtil.h"

@interface MSIDTokenFilteringHelperTests : XCTestCase

@end

@implementation MSIDTokenFilteringHelperTests

#pragma mark - Generic

- (void)testFilterTokenCacheItems_whenReturnFirstYesAndFilterAll_shouldReturnOneItem
{
    MSIDTokenCacheItem *testItem = [MSIDTokenCacheItem new];
    testItem.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem.clientId = DEFAULT_TEST_CLIENT_ID;
    
    NSArray *input = @[testItem, testItem];
    
    NSArray *result = [MSIDTokenFilteringHelper filterTokenCacheItems:input
                                                            tokenType:MSIDTokenTypeOther
                                                          returnFirst:YES
                                                             filterBy:^BOOL(MSIDTokenCacheItem *tokenCacheItem) {
                                                                 return YES;
                                                             }];
    
    XCTAssertEqual([result count], 1);
    
    MSIDBaseToken *expectedToken = [MSIDBaseToken new];
    expectedToken.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    expectedToken.clientId = DEFAULT_TEST_CLIENT_ID;
    
    XCTAssertEqualObjects(result[0], expectedToken);
}

- (void)testFilterTokenCacheItems_whenReturnFirstNoAndFilterAll_shouldReturnTwoItems
{
    MSIDTokenCacheItem *testItem = [MSIDTokenCacheItem new];
    testItem.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem.clientId = DEFAULT_TEST_CLIENT_ID;
    
    NSArray *input = @[testItem, testItem];
    
    NSArray *result = [MSIDTokenFilteringHelper filterTokenCacheItems:input
                                                            tokenType:MSIDTokenTypeOther
                                                          returnFirst:NO
                                                             filterBy:^BOOL(MSIDTokenCacheItem *tokenCacheItem) {
                                                                 return YES;
                                                             }];
    
    XCTAssertEqual([result count], 2);
    
    MSIDBaseToken *expectedToken = [MSIDBaseToken new];
    expectedToken.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    expectedToken.clientId = DEFAULT_TEST_CLIENT_ID;
    
    XCTAssertEqualObjects(result[0], expectedToken);
    XCTAssertEqualObjects(result[1], expectedToken);
}

- (void)testFilterTokenCacheItems_whenReturnFirstYesAndFilterNone_shouldReturnEmptyResult
{
    NSArray *input = @[[MSIDTokenCacheItem new], [MSIDTokenCacheItem new]];
    
    NSArray *result = [MSIDTokenFilteringHelper filterTokenCacheItems:input
                                                            tokenType:MSIDTokenTypeOther
                                                          returnFirst:YES
                                                             filterBy:^BOOL(MSIDTokenCacheItem *tokenCacheItem) {
                                                                 return NO;
                                                             }];
    
    XCTAssertEqual([result count], 0);
}

- (void)testFilterTokenCacheItems_whenReturnFirstNoFilterNone_shouldReturnEmptyResult
{
    NSArray *input = @[[MSIDTokenCacheItem new], [MSIDTokenCacheItem new]];
    
    NSArray *result = [MSIDTokenFilteringHelper filterTokenCacheItems:input
                                                            tokenType:MSIDTokenTypeOther
                                                          returnFirst:NO
                                                             filterBy:^BOOL(MSIDTokenCacheItem *tokenCacheItem) {
                                                                 return NO;
                                                             }];
    
    XCTAssertEqual([result count], 0);
}

#pragma mark - Access tokens

- (void)testFilterAllAccessTokensWithScopes_whenNotSubset_shouldReturnEmptyResult
{
    MSIDTokenCacheItem *testItem = [MSIDTokenCacheItem new];
    testItem.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem.target = @"user.read user.write";
    
    NSArray *input = @[testItem, testItem];
    
    NSArray *result = [MSIDTokenFilteringHelper filterAllAccessTokenCacheItems:input
                                                                    withScopes:[NSOrderedSet orderedSetWithObjects:@"user.readwrite", nil]];
    
    XCTAssertEqual([result count], 0);
}

- (void)testFilterAllAccessTokensWithScopes_whenIsSubset_shouldReturnMatch
{
    MSIDTokenCacheItem *testItem = [MSIDTokenCacheItem new];
    testItem.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem.target = @"user.read user.write";
    testItem.tokenType = MSIDTokenTypeAccessToken;
    
    NSArray *input = @[testItem, testItem];
    
    NSArray *result = [MSIDTokenFilteringHelper filterAllAccessTokenCacheItems:input
                                                                    withScopes:[NSOrderedSet orderedSetWithObjects:@"user.read", nil]];
    
    XCTAssertEqual([result count], 1);
}

- (void)testFilterAccessTokensWithParameters_whenDifferentAuthorities_shouldReturnError
{
    MSIDTokenCacheItem *testItem1 = [MSIDTokenCacheItem new];
    testItem1.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem1.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem1.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem1.target = @"user.read user.write";
    testItem1.uniqueUserId = DEFAULT_TEST_UID;
    testItem1.tokenType = MSIDTokenTypeAccessToken;
    
    MSIDTokenCacheItem *testItem2 = [MSIDTokenCacheItem new];
    testItem2.authority = [NSURL URLWithString:@"https://login.microsoftonline.com/different_tenant"];
    testItem2.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem2.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem2.target = @"user.read user.write";
    testItem2.uniqueUserId = DEFAULT_TEST_UID;
    testItem2.tokenType = MSIDTokenTypeAccessToken;
    
    NSArray *input = @[testItem1, testItem2];
    
    MSIDConfiguration *configuration = [MSIDTestConfiguration configurationWithAuthority:nil
                                                                      clientId:DEFAULT_TEST_CLIENT_ID
                                                                   redirectUri:nil
                                                                        target:@"user.read"];
    
    MSIDAccount *account = [[MSIDAccount alloc] initWithLegacyUserId:DEFAULT_TEST_UID
                                                        uniqueUserId:DEFAULT_TEST_UID];
    
    NSError *error = nil;
    NSArray *result = [MSIDTokenFilteringHelper filterAllAccessTokenCacheItems:input
                                                                withConfiguration:configuration
                                                                       account:account
                                                                       context:nil
                                                                         error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MSIDErrorAmbiguousAuthority);
    XCTAssertNil(result);
    
}

- (void)testFilterAccessTokensWithParameters_withSameAuthoritiesDifferentClientId_shouldReturnEmptyResult
{
    MSIDTokenCacheItem *testItem1 = [MSIDTokenCacheItem new];
    testItem1.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem1.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem1.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem1.target = @"user.read user.write";
    testItem1.uniqueUserId = DEFAULT_TEST_UID;
    testItem1.tokenType = MSIDTokenTypeAccessToken;
    
    MSIDTokenCacheItem *testItem2 = [MSIDTokenCacheItem new];
    testItem2.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem2.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem2.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem2.target = @"user.read user.write";
    testItem2.uniqueUserId = DEFAULT_TEST_UID;
    testItem2.tokenType = MSIDTokenTypeAccessToken;
    
    NSArray *input = @[testItem1, testItem2];
    
    MSIDConfiguration *configuration = [MSIDTestConfiguration configurationWithAuthority:nil
                                                                      clientId:@"different client"
                                                                   redirectUri:nil
                                                                        target:@"user.read"];
    
    MSIDAccount *account = [[MSIDAccount alloc] initWithLegacyUserId:DEFAULT_TEST_UID
                                                        uniqueUserId:DEFAULT_TEST_UID];
    
    NSError *error = nil;
    NSArray *result = [MSIDTokenFilteringHelper filterAllAccessTokenCacheItems:input
                                                                withConfiguration:configuration
                                                                       account:account
                                                                       context:nil
                                                                         error:&error];
    
    XCTAssertNil(error);
    XCTAssertEqual([result count], 0);
}

- (void)testFilterAccessTokensWithParameters_withSameParameters_shouldReturnMatch
{
    MSIDTokenCacheItem *testItem1 = [MSIDTokenCacheItem new];
    testItem1.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem1.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem1.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem1.target = @"user.read user.write";
    testItem1.uniqueUserId = DEFAULT_TEST_UID;
    testItem1.tokenType = MSIDTokenTypeAccessToken;
    
    MSIDTokenCacheItem *testItem2 = [MSIDTokenCacheItem new];
    testItem2.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem2.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem2.accessToken = DEFAULT_TEST_ACCESS_TOKEN;
    testItem2.target = @"user.read user.write";
    testItem2.uniqueUserId = DEFAULT_TEST_UID;
    testItem2.tokenType = MSIDTokenTypeAccessToken;
    
    NSArray *input = @[testItem1, testItem2];
    
    MSIDConfiguration *configuration = [MSIDTestConfiguration configurationWithAuthority:nil
                                                                      clientId:DEFAULT_TEST_CLIENT_ID
                                                                   redirectUri:nil
                                                                        target:@"user.read"];
    
    MSIDAccount *account = [[MSIDAccount alloc] initWithLegacyUserId:DEFAULT_TEST_UID
                                                        uniqueUserId:DEFAULT_TEST_UID];
    
    NSError *error = nil;
    NSArray *result = [MSIDTokenFilteringHelper filterAllAccessTokenCacheItems:input
                                                                withConfiguration:configuration
                                                                       account:account
                                                                       context:nil
                                                                         error:&error];
    
    XCTAssertNil(error);
    XCTAssertEqual([result count], 2);
    XCTAssertEqualObjects(result[0], [testItem1 tokenWithType:MSIDTokenTypeAccessToken]);
    XCTAssertEqualObjects(result[1], [testItem2 tokenWithType:MSIDTokenTypeAccessToken]);
}

#pragma mark - Refresh tokens

- (void)testFilterRefreshTokens_withMatchingLegacyId_shouldReturnMatch
{
    NSString *idToken = [MSIDTestIdTokenUtil idTokenWithName:@"name" preferredUsername:@"user.me"];
    
    MSIDTokenCacheItem *testItem1 = [MSIDTokenCacheItem new];
    testItem1.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem1.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem1.refreshToken = DEFAULT_TEST_REFRESH_TOKEN;
    testItem1.uniqueUserId = DEFAULT_TEST_UID;
    testItem1.tokenType = MSIDTokenTypeRefreshToken;
    testItem1.idToken = idToken;
    
    MSIDTokenCacheItem *testItem2 = [MSIDTokenCacheItem new];
    testItem2.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem2.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem2.refreshToken = DEFAULT_TEST_REFRESH_TOKEN;
    testItem2.uniqueUserId = DEFAULT_TEST_UID;
    testItem2.tokenType = MSIDTokenTypeRefreshToken;
    testItem2.idToken = idToken;
    
    NSArray *input = @[testItem1, testItem2];
    
    NSArray *result = [MSIDTokenFilteringHelper filterRefreshTokenCacheItems:input
                                                                legacyUserId:@"user.me"
                                                                 environment:@"login.microsoftonline.com"
                                                                     context:nil];
    
    XCTAssertEqual([result count], 1);
    XCTAssertEqualObjects(result[0], [testItem1 tokenWithType:MSIDTokenTypeRefreshToken]);
    
}

- (void)testFilterRefreshTokens_withNoMatchingLegacyId_shouldReturnEmptyResult
{
    NSString *idToken = [MSIDTestIdTokenUtil idTokenWithName:@"name" preferredUsername:@"user.me2"];
    
    MSIDTokenCacheItem *testItem1 = [MSIDTokenCacheItem new];
    testItem1.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem1.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem1.refreshToken = DEFAULT_TEST_REFRESH_TOKEN;
    testItem1.uniqueUserId = DEFAULT_TEST_UID;
    testItem1.tokenType = MSIDTokenTypeRefreshToken;
    testItem1.idToken = idToken;
    
    MSIDTokenCacheItem *testItem2 = [MSIDTokenCacheItem new];
    testItem2.authority = [NSURL URLWithString:DEFAULT_TEST_AUTHORITY];
    testItem2.clientId = DEFAULT_TEST_CLIENT_ID;
    testItem2.refreshToken = DEFAULT_TEST_REFRESH_TOKEN;
    testItem2.uniqueUserId = DEFAULT_TEST_UID;
    testItem2.tokenType = MSIDTokenTypeRefreshToken;
    testItem2.idToken = idToken;
    
    NSArray *input = @[testItem1, testItem2];
    
    NSArray *result = [MSIDTokenFilteringHelper filterRefreshTokenCacheItems:input
                                                                legacyUserId:@"user.me"
                                                                 environment:@"login.microsoftonline.com"
                                                                     context:nil];
    
    XCTAssertEqual([result count], 0);
}

@end
