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

#import "MSIDB2CAuthority.h"
#import "MSIDB2CAuthorityResolver.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDAuthority+Internal.h"

@implementation MSIDB2CAuthority

- (nullable instancetype)initWithURL:(NSURL *)url
                      validateFormat:(BOOL)validateFormat
                             context:(id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    self = [super initWithURL:url validateFormat:validateFormat context:context error:error];
    if (self)
    {
        _url = [self.class normalizedAuthorityUrl:url formatValidated:validateFormat context:context error:error];
        if (!_url) return nil;
    }
    
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    return [self initWithURL:url validateFormat:YES context:context error:error];
}

- (nullable instancetype)initWithURL:(nonnull NSURL *)url
                           rawTenant:(NSString *)rawTenant
                             context:(nullable id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    self = [self initWithURL:url context:context error:error];
    if (self)
    {
        if (rawTenant)
        {
            _url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@/%@/%@", [url msidHostWithPortIfNecessary], url.pathComponents[1], rawTenant, url.pathComponents[3]]];
            if (![self.class isAuthorityFormatValid:_url context:context error:error]) return nil;
        }
    }

    return self;
}

+ (BOOL)isAuthorityFormatValid:(NSURL *)url
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{    
    if (![super isAuthorityFormatValid:url context:context error:error]) return NO;
    
    BOOL isB2c = NO;
    if (url.pathComponents.count >= 2)
    {
        isB2c = [[url.pathComponents[1] lowercaseString] isEqualToString:@"tfp"];
    }

    if (!isB2c)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"It is not B2C authority.", nil, nil, nil, context.correlationId, nil);
        }
        return NO;
    }
    
    if (url.pathComponents.count < 4)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"B2C authority should have at least 3 segments in the path (i.e. https://<host>/tfp/<tenant>/<policy>/...)", nil, nil, nil, context.correlationId, nil);
        }
        
        return NO;
    }
    
    return YES;
}

- (nonnull NSString *)telemetryAuthorityType
{
    return MSID_TELEMETRY_VALUE_AUTHORITY_B2C;
}

- (BOOL)supportsBrokeredAuthentication
{
    return NO;
}

- (BOOL)supportsClientIDAsScope
{
    return YES;
}

#pragma mark - Protected

- (id<MSIDAuthorityResolving>)resolver
{
    return [MSIDB2CAuthorityResolver new];
}

#pragma mark - Private

+ (NSURL *)normalizedAuthorityUrl:(NSURL *)url
                  formatValidated:(BOOL)formatValidated
                          context:(id<MSIDRequestContext>)context
                            error:(NSError **)error
{
    if (!url)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"authority is nil.", nil, nil, nil, context.correlationId, nil);
        }
        return nil;
    }
    
    // remove query and fragments
    if (!formatValidated)
    {
        NSURLComponents *urlComp = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        urlComp.query = nil;
        urlComp.fragment = nil;
        
        return urlComp.URL;
    }
    
    // This is just for safety net. If formatValidated, it should satisfy the following condition.
    if (url.pathComponents.count < 4)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"authority is not a valid format to be normalized.", nil, nil, nil, context.correlationId, nil);
        }
        return nil;
    }
    
    // normalize further for validated formats
    NSString *normalizedAuthorityUrl = [NSString stringWithFormat:@"https://%@/%@/%@/%@", [url msidHostWithPortIfNecessary], url.pathComponents[1].msidURLEncode, url.pathComponents[2].msidURLEncode, url.pathComponents[3].msidURLEncode];
    return [NSURL URLWithString:normalizedAuthorityUrl];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDB2CAuthority *authority = [[self.class allocWithZone:zone] initWithURL:_url validateFormat:NO context:nil error:nil];
    
    authority.openIdConfigurationEndpoint = [_openIdConfigurationEndpoint copyWithZone:zone];
    authority.metadata = self.metadata;
    
    return authority;
}

@end
