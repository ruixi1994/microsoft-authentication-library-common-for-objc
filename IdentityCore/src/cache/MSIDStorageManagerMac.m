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

#import <Foundation/Foundation.h>
#import "MSIDAccountCacheItem.h"
#import "MSIDAccountType.h"
#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialType.h"
#import "MSIDJsonSerializer.h"
#import "MSIDLogger.h"
#import "MSIDStorageManagerMac.h"

typedef NS_ENUM(NSInteger, MSIDKeychainAccountType) {
    MSIDKeychainAccountTypeAADV1 = 1001,
    MSIDKeychainAccountTypeMSA,
    MSIDKeychainAccountTypeMSSTS,
    MSIDKeychainAccountTypeOther
};

@interface MSIDStorageManagerMac ()

@property (nonnull) MSIDJsonSerializer *jsonSerializer;

@end

@implementation MSIDStorageManagerMac

// Connect the interface property variable to an actual member variable:
@synthesize accessGroup = _accessGroup;

#pragma mark - init

- (id)init {
    self = [super init];
    if (self) {
        _jsonSerializer = [MSIDJsonSerializer new];
        _accessGroup = @"";
    }
    return self;
}

#pragma mark - Credentials

/** Gets all credentials which match the parameters. */
- (nullable NSArray<MSIDCredentialCacheItem *> *)readCredentials:(nullable __unused NSString *)correlationId
                                                   homeAccountId:(nullable __unused NSString *)homeAccountId
                                                     environment:(nullable __unused NSString *)environment
                                                           realm:(nullable __unused NSString *)realm
                                                        clientId:(nullable __unused NSString *)clientId
                                                          target:(nullable __unused NSString *)target
                                                           types:(nullable __unused NSSet<NSNumber *> *)types
                                                           error:(__unused NSError *_Nullable *_Nullable)error {
    return nil;
}

/** Writes all credentials in the list to the storage. */
- (BOOL)writeCredentials:(nullable __unused NSString *)correlationId
             credentials:(nullable __unused NSArray<MSIDCredentialCacheItem *> *)credentials
                   error:(NSError __unused *_Nullable *_Nullable)error {
    return TRUE;
}

/** Deletes all matching credentials. Parameters mirror read_credentials. */
- (BOOL)deleteCredentials:(nullable __unused NSString *)correlationId
            homeAccountId:(nullable __unused NSString *)homeAccountId
              environment:(nullable __unused NSString *)environment
                    realm:(nullable __unused NSString *)realm
                 clientId:(nullable __unused NSString *)clientId
                   target:(nullable __unused NSString *)target
                    types:(nullable __unused NSSet<NSNumber *> *)types
                    error:(__unused NSError *_Nullable *_Nullable)error {
    return TRUE;
}

#pragma mark - Accounts

/** Reads all accounts present in the cache. */
- (nullable NSArray<MSIDAccountCacheItem *> *)readAllAccounts:(nullable __unused NSString *)correlationId
                                                        error:(__unused NSError *_Nullable *_Nullable)error {
    return nil;
}

/** Reads an account object, if present. */
- (nullable MSIDAccountCacheItem *)readAccount:(nullable __unused NSString *)correlationId
                                 homeAccountId:(nullable __unused NSString *)homeAccountId
                                   environment:(nullable __unused NSString *)environment
                                         realm:(nullable __unused NSString *)realm
                                         error:(__unused NSError *_Nullable *_Nullable)error {
    return nil;
}

/** Write an account object into cache. */
- (BOOL)writeAccount:(nullable __unused NSString *)correlationId
             account:(nullable MSIDAccountCacheItem *)account
               error:(NSError *_Nullable *_Nullable)error {
    // Get previous account, so we don't loose any fields
    MSIDAccountCacheItem *previousAccount = [self readAccount:correlationId
                                                homeAccountId:account.homeAccountId
                                                  environment:account.environment
                                                        realm:account.realm
                                                        error:nil];
    if (previousAccount) {
        [account updateFieldsFromAccount:previousAccount];
    }

    NSData *jsonData = [self.jsonSerializer toJsonData:account context:nil error:error];
    if (!jsonData) {
        MSID_LOG_ERROR(nil, @"%@", @"Failed to serialize account to json data.");
        return FALSE;
    }

    NSDictionary *query = [self defaultAccountQuery:account.homeAccountId
                                        environment:account.environment
                                              realm:account.realm];
    NSDictionary *update = @{
        (id)kSecValueData: jsonData,
        (id)kSecAttrGeneric: account.localAccountId,
        (id)kSecAttrType: [self accountAttribute:account.accountType],
    };

    OSStatus status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *dict = [query mutableCopy];
        [dict addEntriesFromDictionary:update];
        status = SecItemAdd((CFDictionaryRef)dict, NULL);
    }

    if (status != errSecSuccess) {
        MSID_LOG_ERROR(nil, @"Failed to write account to keychain (%d)", status);
        if (error) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:(NSInteger)status userInfo:nil];
        }
        return FALSE;
    } else {
        return TRUE;
    }
}

/** Deletes an account and all associated credentials. */
- (BOOL)deleteAccount:(nullable __unused NSString *)correlationId
        homeAccountId:(nullable __unused NSString *)homeAccountId
          environment:(nullable __unused NSString *)environment
                realm:(nullable __unused NSString *)realm
                error:(__unused NSError *_Nullable *_Nullable)error {
    return TRUE;
}

/** Deletes all information associated with a given homeAccountId and environment. */
- (BOOL)deleteAccounts:(nullable __unused NSString *)correlationId
         homeAccountId:(nullable __unused NSString *)homeAccountId
           environment:(nullable __unused NSString *)environment
                 error:(__unused NSError *_Nullable *_Nullable)error {
    return TRUE;
}

#pragma mark - Account Utilities

- (NSDictionary *)defaultAccountQuery:(nullable __unused NSString *)homeAccountId
                          environment:(nullable __unused NSString *)environment
                                realm:(nullable __unused NSString *)realm {
    return @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: realm,
        (id)kSecAttrAccount: [NSString stringWithFormat:@"%@-%@-%@", self.accessGroup, homeAccountId, environment]
    };
}

- (NSNumber *)accountAttribute:(MSIDAccountType)accountType {
    switch (accountType) {
        case MSIDAccountTypeAADV1:
            return @(MSIDKeychainAccountTypeAADV1);
        case MSIDAccountTypeMSA:
            return @(MSIDKeychainAccountTypeMSA);
        case MSIDAccountTypeMSSTS:
            return @(MSIDKeychainAccountTypeMSSTS);
        case MSIDAccountTypeOther:
            return @(MSIDKeychainAccountTypeOther);
    }
}

- (MSIDAccountType)accountType:(NSNumber *)accountAttribute {
    switch ([accountAttribute integerValue]) {
        case MSIDKeychainAccountTypeAADV1:
            return MSIDAccountTypeAADV1;
        case MSIDKeychainAccountTypeMSA:
            return MSIDAccountTypeMSA;
        case MSIDKeychainAccountTypeMSSTS:
            return MSIDAccountTypeMSSTS;
        case MSIDKeychainAccountTypeOther:
            return MSIDAccountTypeOther;
        default:
            // TODO: report error/log?
            return MSIDAccountTypeOther;
    }
}

@end
