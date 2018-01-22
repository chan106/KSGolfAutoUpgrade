//
//  DTError.m
//  DuoTrac
//
//  Created by PHAN P. Dong (Alain) on 11/10/15.
//  Copyright (c) 2015 Coach Labs. All rights reserved.
//

#import "DTError.h"

NSString *const DTDeserializeErrorDomain = @"DTDeserializeErrorDomain";
NSString *const DTModelValidationErrorDomain = @"DTModelValidationErrorDomain";
NSString *const DTSwingErrorDomain = @"DTSwingErrorDomain";
NSString *const DTDuoTracAPIErrorDomain = @"DTDuoTracAPIErrorDomain";

@implementation NSError (Intialization)

+ (NSError *)errorWithDomain:(NSString *)aDomain code:(NSInteger)aCode {
    return [NSError errorWithDomain:aDomain code:aCode userInfo:nil];
}

+ (NSError *)errorWithDomain:(NSString *)aDomain
                        code:(NSInteger)aCode
        localizedDescription:(NSString *)aDescription {
    NSDictionary *userInfo = nil;
    
    if (aDescription) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    aDescription,
                    NSLocalizedDescriptionKey, nil];
    }
    
    return [NSError errorWithDomain:aDomain code:aCode userInfo:userInfo];
}

@end


#define kSystemErrorMessage NSLocalizedString(@"Our system got some internal issues. Try later.", @"")
@interface NSError (MessageUtils)

+ (NSString *)errorMessageForDomain:(NSString *)aDomain code:(NSInteger)aCode;
+ (NSDictionary *)errorMessagesForDuoTracAPIDomain;

@end

@implementation NSError (MessageUtils)

+ (NSString *)errorMessageForDomain:(NSString *)aDomain
                               code:(NSInteger)aCode {
    
    NSDictionary *messages;
    if ([aDomain isEqualToString:DTDuoTracAPIErrorDomain]) {
        messages = [self errorMessagesForDuoTracAPIDomain];
    }
    else if ([aDomain isEqualToString:DTModelValidationErrorDomain]) {
        messages = [self errorMessagesForModelValidationDomain];
    }
    NSString *errorMessage = nil;
    if ([messages objectForKey:@(aCode)]) {
        errorMessage = [messages objectForKey:@(aCode)];
    }
    else {
        errorMessage = kSystemErrorMessage;
    }
    
    return errorMessage;
}


+ (NSDictionary *)errorMessagesForDuoTracAPIDomain {
    return @{
             @(DTDuoTracAPIErrorCodeSystemError) : kSystemErrorMessage,
             @(DTDuoTracAPIErrorCodeUserInvalidCredentails) : NSLocalizedString(@"Invalid e-mail / password. Try Again.", @""),
             @(DTDuoTracAPIErrorCodeUnauthorized) : NSLocalizedString(@"Unauthorized Request.", @""),
             @(DTDuoTracAPIErrorCodeUserMissingRequiredFields) : NSLocalizedString(@"Missing entry.", @""),
             @(DTDuoTracAPIErrorCodeUserEmailExists) : NSLocalizedString(@"Email already exists.", @""),
             @(DTDuoTracAPIErrorCodeUserPasswordTooShort) : NSLocalizedString(@"Password too short.", @""),
             @(DTDuoTracAPIErrorCodeUserEmailInvalid) : NSLocalizedString(@"Invalid e-mail.", @""),
             @(DTDuoTracAPIErrorCodeUserEmailNotPresent) : NSLocalizedString(@"E-mail not found. Try Again.", @"")
             };
}

+ (NSDictionary *)errorMessagesForModelValidationDomain {
    return @{
             @(DTModelValidationErrorCodeEntryMissing) : NSLocalizedString(@"Missing entry.", @""),
             @(DTModelValidationErrorCodeInvalidEmail) : NSLocalizedString(@"Invalid e-mail. Try Again.", @""),
             @(DTModelValidationErrorCodeUserPasswordIncorrect) : NSLocalizedString(@"Incorrect password. Try Again.", @""),
             @(DTModelValidationErrorCodeUserPasswordsNotMatch) : NSLocalizedString(@"Passwords did not match.", @""),
             @(DTModelValidationErrorCodeUserPasswordTooShort) : NSLocalizedString(@"Password too short.", @"")
             };
}

@end

@implementation NSError (Message)

- (NSString *)errorMessage {
    
    NSString *userFriendlyMessage = [NSError errorMessageForDomain:self.domain
                                                              code:self.code];
    if (userFriendlyMessage) {
        return userFriendlyMessage;
    }
    return self.localizedDescription;
}

@end
