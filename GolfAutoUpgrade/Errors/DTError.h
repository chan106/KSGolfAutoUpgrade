//
//  DTError.h
//  DuoTrac
//
//  Created by PHAN P. Dong (Alain) on 11/10/15.
//  Copyright (c) 2015 Coach Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Error domains.
 */
extern NSString *const DTDeserializeErrorDomain;
extern NSString *const DTModelValidationErrorDomain;
extern NSString *const DTSwingErrorDomain;
extern NSString *const DTDuoTracAPIErrorDomain;

/**
 *  Error codes for deserializing error domain.
 */
typedef NS_ENUM(NSUInteger, DTDeserializeErrorCode) {
    DTDeserializeErrorCodeWrongClassType = 0,
    DTDeserializeErrorCodeIDMissing,
    DTDeserializeErrorCodeUserNameMissing,
    DTDeserializeErrorCodeShapeEmailMissing
};

/**
 *  Error codes for model validation domain.
 */
typedef NS_ENUM(NSUInteger, DTModelValidationErrorCode) {
    DTModelValidationErrorCodeEntryMissing = 0,
    DTModelValidationErrorCodeInvalidEmail,
    DTModelValidationErrorCodeUserPasswordIncorrect,
    DTModelValidationErrorCodeUserPasswordsNotMatch,
    DTModelValidationErrorCodeUserPasswordTooShort
};

typedef NS_ENUM(NSUInteger, DTSwingErrorCode) {
    DTSwingErrorCodeMissingData = 0,
    DTSwingErrorCodeFailedTransmission,
    DTSwingErrorCodeFailedCalculation,
    DTSwingErrorCodeCalcEngineNotAvailable,
    DTSwingErrorCodePullingExpired
};

/**
 *  Error codes for DuoTrac API consumption domain.
 */
typedef NS_ENUM(NSUInteger, DTDuoTracAPIErrorCode) {
    // General error codes
    DTDuoTracAPIErrorCodeSystemError = 500,
    DTDuoTracAPIErrorCodeUnauthorized = 401,
    DTDuoTracAPIErrorCodeUnreachable = 404,
    // User-related error codes
    DTDuoTracAPIErrorCodeUserInvalidCredentails = 1100,
    DTDuoTracAPIErrorCodeUserMissingRequiredFields = 1000,
    DTDuoTracAPIErrorCodeUserEmailExists = 1001,
    DTDuoTracAPIErrorCodeUserPasswordTooShort = 1002,
    DTDuoTracAPIErrorCodeUserEmailInvalid = 1003,
    DTDuoTracAPIErrorCodeUserEmailNotPresent = 1004,
    DTDuoTracAPIErrorCodeDuplicateData = 2002
};

/**
 *
 */
typedef NS_ENUM(NSUInteger, DTHTTPStatusCode) {
    DTHTTPStatusCodeOK = 200,
    DTHTTPStatusCodeNotFound = 400,
    DTHTTPStatusCodeUnauthorized = 401
};

@interface NSError (Intialization)

+ (NSError *)errorWithDomain:(NSString *)aDomain code:(NSInteger)aCode;

+ (NSError *)errorWithDomain:(NSString *)aDomain
                        code:(NSInteger)aCode
        localizedDescription:(NSString *)aDescription;

@end

@interface NSError (Message)

- (NSString *)errorMessage;

@end
