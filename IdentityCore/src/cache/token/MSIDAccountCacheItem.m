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

@interface MSIDAccountCacheItem()

@property (readwrite) NSDictionary *json;

@end

@implementation MSIDAccountCacheItem

#pragma mark - Equal

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:self.class])
    {
        return NO;
    }

    return [self isEqualToItem:(MSIDAccountCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDAccountCacheItem *)item
{
    BOOL result = YES;
    result &= self.accountType == item.accountType;
    result &= (!self.homeAccountId || !item.homeAccountId) || [self.homeAccountId isEqualToString:item.homeAccountId];
    result &= (!self.legacyUserId || !item.legacyUserId) || [self.legacyUserId isEqualToString:item.legacyUserId];
    result &= (!self.username || !item.username) || [self.username isEqualToString:item.username];
    result &= (!self.givenName || !item.givenName) || [self.givenName isEqualToString:item.givenName];
    result &= (!self.middleName || !item.middleName) || [self.middleName isEqualToString:item.middleName];
    result &= (!self.familyName || !item.familyName) || [self.familyName isEqualToString:item.familyName];
    result &= (!self.name || !item.name) || [self.name isEqualToString:item.name];
    result &= (!self.realm || !item.realm) || [self.realm isEqualToString:item.realm];
    result &= (!self.clientInfo || !item.clientInfo) || [self.clientInfo.rawClientInfo isEqualToString:item.clientInfo.rawClientInfo];
    result &= (!self.environment || !item.environment) || [self.environment isEqualToString:item.environment];
    result &= (!self.alternativeAccountId || !item.alternativeAccountId) || [self.alternativeAccountId isEqualToString:item.alternativeAccountId];
    return result;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.accountType;
    hash = hash * 31 + self.homeAccountId.hash;
    hash = hash * 31 + self.legacyUserId.hash;
    hash = hash * 31 + self.username.hash;
    hash = hash * 31 + self.givenName.hash;
    hash = hash * 31 + self.middleName.hash;
    hash = hash * 31 + self.familyName.hash;
    hash = hash * 31 + self.name.hash;
    hash = hash * 31 + self.realm.hash;
    hash = hash * 31 + self.clientInfo.hash;
    hash = hash * 31 + self.environment.hash;
    hash = hash * 31 + self.alternativeAccountId.hash;
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAccountCacheItem *item = [[self class] allocWithZone:zone];
    item.accountType = self.accountType;
    item.homeAccountId = [self.homeAccountId copyWithZone:zone];
    item.legacyUserId = [self.legacyUserId copyWithZone:zone];
    item.username = [self.username copyWithZone:zone];
    item.givenName = [self.givenName copyWithZone:zone];
    item.middleName = [self.middleName copyWithZone:zone];
    item.familyName = [self.familyName copyWithZone:zone];
    item.name = [self.name copyWithZone:zone];
    item.realm = [self.realm copyWithZone:zone];
    item.clientInfo = [self.clientInfo copyWithZone:zone];
    item.environment = [self.environment copyWithZone:zone];
    item.alternativeAccountId = [self.alternativeAccountId copyWithZone:zone];
    return item;
}

#pragma mark - JSON

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    if (!(self = [super init]))
    {
        return nil;
    }

    if (!json)
    {
        MSID_LOG_WARN(nil, @"Tried to decode an account cache item from nil json");
        return nil;
    }

    _json = json;

    _accountType = [MSIDAccountTypeHelpers accountTypeFromString:json[MSID_AUTHORITY_TYPE_CACHE_KEY]];

    if (!_accountType)
    {
        MSID_LOG_WARN(nil, @"No account type present in the JSON for credential");
        return nil;
    }

    _legacyUserId = json[MSID_ACCOUNT_ID_CACHE_KEY];
    _homeAccountId = json[MSID_HOME_ACCOUNT_ID_CACHE_KEY];
    _username = json[MSID_USERNAME_CACHE_KEY];
    _givenName = json[MSID_GIVEN_NAME_CACHE_KEY];
    _middleName = json[MSID_MIDDLE_NAME_CACHE_KEY];
    _familyName = json[MSID_FAMILY_NAME_CACHE_KEY];
    _name = json[MSID_NAME_CACHE_KEY];
    _realm = json[MSID_REALM_CACHE_KEY];
    _clientInfo = [[MSIDClientInfo alloc] initWithRawClientInfo:json[MSID_CLIENT_INFO_CACHE_KEY] error:nil];
    _environment = json[MSID_ENVIRONMENT_CACHE_KEY];
    _alternativeAccountId = json[MSID_ALTERNATIVE_ACCOUNT_ID_KEY];
    return self;
}

- (NSDictionary *)jsonDictionary
{    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (_json)
    {
        [dictionary addEntriesFromDictionary:_json];
    }
    
    if (_additionalAccountFields)
    {
        [dictionary addEntriesFromDictionary:_additionalAccountFields];
    }
    
    dictionary[MSID_AUTHORITY_TYPE_CACHE_KEY] = [MSIDAccountTypeHelpers accountTypeAsString:_accountType];
    dictionary[MSID_HOME_ACCOUNT_ID_CACHE_KEY] = _homeAccountId;
    dictionary[MSID_ACCOUNT_ID_CACHE_KEY] = _legacyUserId;
    dictionary[MSID_USERNAME_CACHE_KEY] = _username;
    dictionary[MSID_GIVEN_NAME_CACHE_KEY] = _givenName;
    dictionary[MSID_MIDDLE_NAME_CACHE_KEY] = _middleName;
    dictionary[MSID_FAMILY_NAME_CACHE_KEY] = _familyName;
    dictionary[MSID_NAME_CACHE_KEY] = _name;
    dictionary[MSID_ENVIRONMENT_CACHE_KEY] = _environment;
    dictionary[MSID_REALM_CACHE_KEY] = _realm;
    dictionary[MSID_CLIENT_INFO_CACHE_KEY] = _clientInfo.rawClientInfo;
    dictionary[MSID_ALTERNATIVE_ACCOUNT_ID_KEY] = _alternativeAccountId;
    return dictionary;
}

#pragma mark - Update

- (void)updateFieldsFromAccount:(MSIDAccountCacheItem *)account
{
    NSMutableDictionary *allAdditionalFields = [NSMutableDictionary dictionary];
    [allAdditionalFields addEntriesFromDictionary:account.additionalAccountFields];
    [allAdditionalFields addEntriesFromDictionary:_additionalAccountFields];
    _additionalAccountFields = allAdditionalFields;
}

#pragma mark - Query

- (BOOL)matchesWithHomeAccountId:(nullable NSString *)homeAccountId
                     environment:(nullable NSString *)environment
              environmentAliases:(nullable NSArray<NSString *> *)environmentAliases
{
    if (homeAccountId && ![self.homeAccountId isEqualToString:homeAccountId])
    {
        return NO;
    }

    if (environment && ![self.environment isEqualToString:environment])
    {
        return NO;
    }

    if (environmentAliases && ![self.environment msidIsEquivalentWithAnyAlias:environmentAliases])
    {
        return NO;
    }

    return YES;
}

@end
