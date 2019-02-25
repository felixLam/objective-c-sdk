/****************************************************************************
 * Copyright 2016-2018, Optimizely, Inc. and contributors                   *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OPTLYNotificationCenter.h"
#import "OPTLYErrorHandler.h"
#import "OPTLYLogger.h"
#import "OPTLYUserProfileServiceBasic.h"
#import "OPTLYTestHelper.h"
#import "OPTLYProjectConfig.h"
#import "OPTLYExperiment.h"
#import "OPTLYVariation.h"
#import "Optimizely.h"
#import "OPTLYFeatureDecision.h"

static NSString *const kDataModelDatafileName = @"optimizely_6372300739_v4";
static NSString *const kUserId = @"userId";
static NSString *const kExperimentKey = @"testExperimentWithFirefoxAudience";
static NSString *const kVariationId = @"6362476365";

static NSString *const kAttributeKeyBrowserName = @"browser_name";
static NSString *const kAttributeValueBrowserValue = @"firefox";
static NSString *const kAttributeKeyBrowserBuildNo = @"browser_buildno";
static NSString *const kAttributeKeyBrowserVersion = @"browser_version";
static NSString *const kAttributeKeyObject = @"dummy_object";

@interface OPTLYNotificationCenter()
// notification Count represeting total number of notifications.
@property (nonatomic, readonly) NSUInteger notificationsCount;
@end

@interface OPTLYNotificationCenterTest : XCTestCase
@property (nonatomic, strong) OPTLYNotificationCenter *notificationCenter;
@property (nonatomic, copy) ActivateListener activateNotification;
@property (nonatomic, copy) ActivateListener anotherActivateNotification;
@property (nonatomic, copy) TrackListener trackNotification;
@property (nonatomic, copy) IsFeatureEnabledListener isFeatureEnabledListener;
@property (nonatomic, copy) GetEnabledFeaturesListener getEnabledFeaturesListener;
@property (nonatomic, copy) GetFeatureVariableListener getFeatureVariableListener;
@property (nonatomic, strong) OPTLYProjectConfig *projectConfig;
@end

@implementation OPTLYNotificationCenterTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    self.projectConfig = [[OPTLYProjectConfig alloc] initWithBuilder:[OPTLYProjectConfigBuilder builderWithBlock:^(OPTLYProjectConfigBuilder * _Nullable builder) {
        builder.datafile = datafile;
        builder.logger = [OPTLYLoggerDefault new];
        builder.errorHandler = [OPTLYErrorHandlerNoOp new];
        builder.userProfileService = [OPTLYUserProfileServiceNoOp new];
    }]];
    self.notificationCenter = [[OPTLYNotificationCenter alloc] initWithProjectConfig:self.projectConfig];
    __weak typeof(self) weakSelf = self;
    weakSelf.activateNotification = ^(OPTLYExperiment *experiment, NSString *userId, NSDictionary<NSString *, NSObject *> *attributes, OPTLYVariation *variation, NSDictionary<NSString *,NSString *> *event) {
        NSString *logMessage = @"activate notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, experiment.experimentKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, variation.variationKey] withLevel:OptimizelyLogLevelInfo];
    };
    weakSelf.anotherActivateNotification = ^(OPTLYExperiment *experiment, NSString *userId, NSDictionary<NSString *, NSObject *> *attributes, OPTLYVariation *variation, NSDictionary<NSString *,NSString *> *event) {
        NSString *logMessage = @"activate notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, experiment.experimentKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, variation.variationKey] withLevel:OptimizelyLogLevelInfo];
    };
    weakSelf.trackNotification = ^(NSString *eventKey, NSString *userId, NSDictionary<NSString *, NSObject *> *attributes, NSDictionary *eventTags, NSDictionary<NSString *,NSString *> *event) {
        NSString *logMessage = @"track notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, eventKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
    };
    weakSelf.isFeatureEnabledListener = ^(NSString * _Nonnull featureKey, NSString * _Nonnull userId, NSDictionary<NSString *,NSObject *> * _Nullable attributes, NSDictionary<NSString *,NSObject *> * _Nullable featureInfo) {
        NSString *logMessage = @"isFeatureEnabledListener notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, featureKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
    };
    weakSelf.getEnabledFeaturesListener = ^(NSString * _Nonnull userId, NSDictionary<NSString *,NSObject *> * _Nullable attributes, NSArray<NSString *> * _Nullable enabledFeatures) {
        NSString *logMessage = @"getEnabledFeaturesListener notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, enabledFeatures] withLevel:OptimizelyLogLevelInfo];
    };
    weakSelf.getFeatureVariableListener = ^(NSString * _Nonnull featureKey, NSString * _Nonnull variableKey, NSString * _Nonnull userId, NSDictionary<NSString *,NSObject *> * _Nullable attributes, NSDictionary<NSString *,NSObject *> * _Nullable featureVariableInfo) {
        NSString *logMessage = @"getFeatureVariableListener notification called with %@";
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, featureKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, variableKey] withLevel:OptimizelyLogLevelInfo];
        [weakSelf.projectConfig.logger logMessage:[NSString stringWithFormat:logMessage, userId] withLevel:OptimizelyLogLevelInfo];
    };
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // clean up all notifications
    [_notificationCenter clearAllNotificationListeners];
}

- (void)testAddAndRemoveNotificationListener {
    
    // Verify that callback added successfully.
    NSUInteger notificationId = [_notificationCenter addActivateNotificationListener:_activateNotification];
    XCTAssertEqual(1, notificationId);
    XCTAssertEqual(1, _notificationCenter.notificationsCount);
    
    // Verify that callback removed successfully.
    XCTAssertEqual(YES, [_notificationCenter removeNotificationListener:notificationId]);
    XCTAssertEqual(0, _notificationCenter.notificationsCount);
    
    //Verify return false with invalid ID.
    XCTAssertEqual(NO, [_notificationCenter removeNotificationListener:notificationId]);
    
    // Verify that callback added successfully and return right notification ID.
    XCTAssertEqual(_notificationCenter.notificationId, [_notificationCenter addActivateNotificationListener:_activateNotification]);
    XCTAssertEqual(1, _notificationCenter.notificationsCount);
}

- (void)testAddSameNotificationListenerMultipleTimes {
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    
    // Verify that adding same callback multiple times will gets failed.
    XCTAssertEqual(-1, [_notificationCenter addActivateNotificationListener:_activateNotification]);
    XCTAssertEqual(1, _notificationCenter.notificationsCount);
}

- (void)testClearNotifications {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Verify that callbacks added successfully.
    XCTAssertEqual(6, _notificationCenter.notificationsCount);
    
    // Verify that only decision callbacks are removed.
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeActivate];
    XCTAssertEqual(4, _notificationCenter.notificationsCount);
    
    // Verify that ClearNotifications does not break on calling twice for same type.
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeActivate];
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeActivate];
    
    // Verify that ClearNotifications does not break after calling ClearAllNotifications.
    [_notificationCenter clearAllNotificationListeners];
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeTrack];
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeIsFeatureEnabled];
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeGetEnabledFeatures];
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeGetFeatureVariable];
}

- (void)testClearAllNotifications {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Verify that callbacks added successfully.
    XCTAssertEqual(6, _notificationCenter.notificationsCount);
    
    // Verify that ClearAllNotifications remove all the callbacks.
    [_notificationCenter clearAllNotificationListeners];
    XCTAssertEqual(0, _notificationCenter.notificationsCount);
    
    // Verify that ClearAllNotifications does not break on calling twice or after ClearNotifications.
    [_notificationCenter clearNotificationListeners:OPTLYNotificationTypeActivate];
    [_notificationCenter clearAllNotificationListeners];
    [_notificationCenter clearAllNotificationListeners];
}

- (void)testSendActivateNotification {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    
    OPTLYExperiment *experiment = [_projectConfig getExperimentForKey:kExperimentKey];
    OPTLYVariation *variation = [experiment getVariationForVariationId:kVariationId];
    NSDictionary *attributes = [NSDictionary new];
    NSDictionary *event = [NSDictionary new];
    NSString *userId = [NSString stringWithFormat:@"%@", kUserId];
    
    NSDictionary *activateArgs = @{
                           OPTLYNotificationExperimentKey: experiment,
                           OPTLYNotificationUserIdKey: userId,
                           OPTLYNotificationAttributesKey: attributes,
                           OPTLYNotificationVariationKey: variation,
                           OPTLYNotificationLogEventParamsKey: event,
                           };
    // Verify that only the registered notifications of decision type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeActivate args:activateArgs];
    
    OCMReject(_trackNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    OCMVerify(_activateNotification);
    OCMVerify(_anotherActivateNotification);
    
    // Verify that after clearing notifications, SendNotification should not call any notification
    // which were previously registered.
    [_notificationCenter clearAllNotificationListeners];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeActivate args:activateArgs];
    // Again verify notifications which were registered are not called.
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
}

- (void)testSendTrackNotification {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    
    OPTLYExperiment *experiment = [_projectConfig getExperimentForKey:kExperimentKey];
    OPTLYVariation *variation = [experiment getVariationForVariationId:kVariationId];
    NSDictionary *attributes = [NSDictionary new];
    NSDictionary *event = [NSDictionary new];
    NSString *userId = [NSString stringWithFormat:@"%@", kUserId];
    
    NSString *eventKey = [NSString stringWithFormat:@"%@", kUserId];
    NSDictionary *eventTags = [NSDictionary new];
    
    NSDictionary *trackArgs = @{
                                OPTLYNotificationEventKey: eventKey,
                                OPTLYNotificationUserIdKey: userId,
                                OPTLYNotificationAttributesKey: attributes,
                                OPTLYNotificationVariationKey: variation,
                                OPTLYNotificationEventTagsKey: eventTags,
                                OPTLYNotificationLogEventParamsKey: event
                                };
    
    
    // Verify that only the registered notifications of track type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeTrack args:trackArgs];
    
    OCMVerify(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    // Verify that after clearing notifications, SendNotification should not call any notification
    // which were previously registered.
    [_notificationCenter clearAllNotificationListeners];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeTrack args:trackArgs];
    // Again verify notifications which were registered are not called.
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
}

- (void)testSendIsFeatureEnabledNotification {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    NSString *featureFlagKey = @"booleanFeature";
    NSMutableDictionary *featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureSource];
    
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationIsEnabled];
    [featureInfo setValue:[NSNull null] forKey:OPTLYNotificationEvent];
    
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setValue:featureFlagKey forKey:OPTLYNotificationFeatureKey];
    [args setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [args setValue:[NSNull null] forKey:OPTLYNotificationAttributesKey];
    [args setValue:featureInfo forKey:OPTLYNotificationFeatureInfo];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:args];
    
    OCMVerify(_isFeatureEnabledListener);
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    // Verify that after clearing notifications, SendNotification should not call any notification
    // which were previously registered.
    [_notificationCenter clearAllNotificationListeners];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:args];
    // Again verify notifications which were registered are not called.
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
}

- (void)testSendGetEnabledFeaturesNotification {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [args setValue:[NSNull null] forKey:OPTLYNotificationAttributesKey];
    [args setValue:@[] forKey:OPTLYNotificationEnabledFeatures];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetEnabledFeatures args:args];
    
    OCMVerify(_getEnabledFeaturesListener);
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_getFeatureVariableListener);
    OCMReject(_isFeatureEnabledListener);
    
    // Verify that after clearing notifications, SendNotification should not call any notification
    // which were previously registered.
    [_notificationCenter clearAllNotificationListeners];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:args];
    // Again verify notifications which were registered are not called.
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
}

- (void) testSendGetFeatureVariableNotification {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    [_notificationCenter addActivateNotificationListener:_anotherActivateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];

    // Fire decision type notifications.
    NSString *featureFlagKey = @"booleanFeature";
    NSMutableDictionary *featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationFeatureEnabled];
    [featureInfo setValue:@YES forKey:OPTLYNotificationVariableValue];
    [featureInfo setValue:@"boolean" forKey:OPTLYNotificationVariableType];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureEnabledSource];
    
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setValue:featureFlagKey forKey:OPTLYNotificationFeatureKey];
    [args setValue:@"tempKey" forKey:OPTLYNotificationVariableKey];
    [args setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [args setValue:[NSNull null] forKey:OPTLYNotificationAttributesKey];
    [args setValue:featureInfo forKey:OPTLYNotificationFeatureVariableInfo];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetFeatureVariable args:args];
    
    OCMVerify(_getFeatureVariableListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    
    // Verify that after clearing notifications, SendNotification should not call any notification
    // which were previously registered.
    [_notificationCenter clearAllNotificationListeners];
    
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:args];
    // Again verify notifications which were registered are not called.
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_anotherActivateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
}

- (void) testSendNotificationWithAnyAttributes {
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    OPTLYExperiment *experiment = [_projectConfig getExperimentForKey:kExperimentKey];
    OPTLYVariation *variation = [experiment getVariationForVariationId:kVariationId];
    NSDictionary *attributes = @{
        kAttributeKeyBrowserName: kAttributeValueBrowserValue,
        kAttributeKeyBrowserBuildNo: @(10),
        kAttributeKeyBrowserVersion: @(0.3),
        kAttributeKeyObject: @{
            kAttributeKeyBrowserName: kAttributeValueBrowserValue,
        }
    };
    NSDictionary *logEvent = [NSDictionary new];
    NSString *userId = [NSString stringWithFormat:@"%@", kUserId];
    
    NSDictionary *activateArgs = @{
                                   OPTLYNotificationExperimentKey: experiment,
                                   OPTLYNotificationUserIdKey: userId,
                                   OPTLYNotificationAttributesKey: attributes,
                                   OPTLYNotificationVariationKey: variation,
                                   OPTLYNotificationLogEventParamsKey: logEvent,
                                   };
    
    // Verify that only the registered notifications of decision type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeActivate args:activateArgs];
    OCMVerify(_activateNotification);
    
    NSString *eventKey = [NSString stringWithFormat:@"%@", kUserId];
    NSDictionary *eventTags = [NSDictionary new];
    
    NSDictionary *trackArgs = @{
                                OPTLYNotificationEventKey: eventKey,
                                OPTLYNotificationUserIdKey: userId,
                                OPTLYNotificationAttributesKey: attributes,
                                OPTLYNotificationVariationKey: variation,
                                OPTLYNotificationEventTagsKey: eventTags,
                                OPTLYNotificationLogEventParamsKey: logEvent
                                };
    
    // Verify that only the registered notifications of track type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeTrack args:trackArgs];
    OCMVerify(_trackNotification);
    
    NSString *featureFlagKey = @"booleanFeature";
    NSMutableDictionary *featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureSource];
    
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationIsEnabled];
    [featureInfo setValue:[NSNull null] forKey:OPTLYNotificationEvent];
    
    NSMutableDictionary *isFeatureEnabledArgs = [[NSMutableDictionary alloc] init];
    [isFeatureEnabledArgs setValue:featureFlagKey forKey:OPTLYNotificationFeatureKey];
    [isFeatureEnabledArgs setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [isFeatureEnabledArgs setValue:attributes forKey:OPTLYNotificationAttributesKey];
    [isFeatureEnabledArgs setValue:featureInfo forKey:OPTLYNotificationFeatureInfo];
    
    // Verify that only the registered notifications of isFeatureEnabled type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:isFeatureEnabledArgs];
    OCMVerify(_isFeatureEnabledListener);
    
    NSMutableDictionary *getEnabledFeaturesArgs = [[NSMutableDictionary alloc] init];
    [getEnabledFeaturesArgs setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [getEnabledFeaturesArgs setValue:attributes forKey:OPTLYNotificationAttributesKey];
    [getEnabledFeaturesArgs setValue:@[] forKey:OPTLYNotificationEnabledFeatures];
    
    // Verify that only the registered notifications of getEnabledFeatures type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetEnabledFeatures args:getEnabledFeaturesArgs];
    OCMVerify(_getEnabledFeaturesListener);
    
    featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationFeatureEnabled];
    [featureInfo setValue:@YES forKey:OPTLYNotificationVariableValue];
    [featureInfo setValue:@"boolean" forKey:OPTLYNotificationVariableType];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureEnabledSource];
    
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setValue:featureFlagKey forKey:OPTLYNotificationFeatureKey];
    [args setValue:@"tempKey" forKey:OPTLYNotificationVariableKey];
    [args setValue:kUserId forKey:OPTLYNotificationUserIdKey];
    [args setValue:[NSNull null] forKey:OPTLYNotificationAttributesKey];
    [args setValue:featureInfo forKey:OPTLYNotificationFeatureVariableInfo];
    
    // Verify that only the registered notifications of getFeatureVariable type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetFeatureVariable args:args];
    OCMVerify(_getFeatureVariableListener);
}

- (void)testSendNotificationsWithInvalidArgs {
    
    // Add activate notifications.
    [_notificationCenter addActivateNotificationListener:_activateNotification];
    
    // Add track notification.
    [_notificationCenter addTrackNotificationListener:_trackNotification];
    
    // Add isFeatureEnabled notification.
    [_notificationCenter addIsFeatureEnabledNotificationListener:_isFeatureEnabledListener];
    
    // Add getEnabledFeatures notification.
    [_notificationCenter addGetEnabledFeaturesNotificationListener:_getEnabledFeaturesListener];
    
    // Add getFeatureVariable notification.
    [_notificationCenter addGetFeatureVariableNotificationListener:_getFeatureVariableListener];
    
    // Fire decision type notifications.
    OPTLYExperiment *experiment = [_projectConfig getExperimentForKey:kExperimentKey];
    OPTLYVariation *variation = [experiment getVariationForVariationId:kVariationId];
    NSDictionary *attributes = [NSDictionary new];
    NSDictionary *event = [NSDictionary new];
    NSString *userId = [NSString stringWithFormat:@"%@", kUserId];
    
    // Verify that only the registered notifications of decision type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeActivate args:@[experiment, userId, attributes, variation]];
    
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    NSString *eventKey = [NSString stringWithFormat:@"%@", kUserId];
    NSDictionary *eventTags = [NSDictionary new];
    
    // Verify that only the registered notifications of track type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeTrack args:@[eventKey, userId, eventTags, event]];
    
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    NSString *featureFlagKey = @"booleanFeature";
    NSMutableDictionary *featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureSource];
    
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationIsEnabled];
    [featureInfo setValue:[NSNull null] forKey:OPTLYNotificationEvent];
    
    // Verify that only the registered notifications of isFeatureEnabled type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeIsFeatureEnabled args:@[featureFlagKey, kUserId, attributes, featureInfo]];
    
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    // Verify that only the registered notifications of getEnabledFeatures type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetEnabledFeatures args:@[kUserId, ]];
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
    featureInfo = [[NSMutableDictionary alloc] init];
    [featureInfo setValue:[NSNumber numberWithBool:1] forKey:OPTLYNotificationFeatureEnabled];
    [featureInfo setValue:@YES forKey:OPTLYNotificationVariableValue];
    [featureInfo setValue:@"boolean" forKey:OPTLYNotificationVariableType];
    [featureInfo setValue:DecisionSourceExperiment forKey:OPTLYNotificationFeatureEnabledSource];
    
    // Verify that only the registered notifications of getFeatureVariable type are called.
    [_notificationCenter sendNotifications:OPTLYNotificationTypeGetFeatureVariable args:@[featureFlagKey, kUserId, featureInfo]];
    OCMReject(_trackNotification);
    OCMReject(_activateNotification);
    OCMReject(_isFeatureEnabledListener);
    OCMReject(_getEnabledFeaturesListener);
    OCMReject(_getFeatureVariableListener);
    
}

@end
