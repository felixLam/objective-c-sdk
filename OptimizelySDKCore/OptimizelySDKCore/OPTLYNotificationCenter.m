/****************************************************************************
 * Copyright 2018-2019, Optimizely, Inc. and contributors                   *
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

#import "OPTLYNotificationCenter.h"
#import "OPTLYProjectConfig.h"
#import "OPTLYLogger.h"
#import "OPTLYExperiment.h"
#import "OPTLYVariation.h"
#import "OPTLYNSObject+Validation.h"
#import <objc/runtime.h>

NSString * _Nonnull const OPTLYNotificationExperimentKey = @"experiment";
NSString * _Nonnull const OPTLYNotificationVariationKey = @"variation";
NSString * _Nonnull const OPTLYNotificationUserIdKey = @"userId";
NSString * _Nonnull const OPTLYNotificationAttributesKey = @"attributes";
NSString * _Nonnull const OPTLYNotificationEventKey = @"eventKey";
NSString * _Nonnull const OPTLYNotificationLogEventParamsKey = @"logEventParams";
/// track Notification Keys
NSString * _Nonnull const OPTLYNotificationEventTagsKey = @"eventTags";
/// isFeatureEnabled Notification Keys
NSString * _Nonnull const OPTLYNotificationFeatureSource = @"source";
NSString * _Nonnull const OPTLYNotificationIsEnabled = @"enabled";
NSString * _Nonnull const OPTLYNotificationFeatureInfo = @"featureInfo";
NSString * _Nonnull const OPTLYNotificationEvent = @"event";
/// getEnabledFeatures Notification Keys
NSString * _Nonnull const OPTLYNotificationEnabledFeatures = @"enabledFeatures";
/// getFeatureVariable Notification Keys
NSString * _Nonnull const OPTLYNotificationFeatureKey = @"featureKey";
NSString * _Nonnull const OPTLYNotificationVariableKey = @"variableKey";
NSString * _Nonnull const OPTLYNotificationVariableValue = @"variableValue";
NSString * _Nonnull const OPTLYNotificationVariableType = @"variableType";
NSString * _Nonnull const OPTLYNotificationFeatureEnabled = @"featureEnabled";
NSString * _Nonnull const OPTLYNotificationFeatureEnabledSource = @"featureEnabledSource";
NSString * _Nonnull const OPTLYNotificationFeatureVariableInfo = @"featureVariableInfo";

@interface OPTLYNotificationCenter()

// Associative array of notification type to notification id and notification pair.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, OPTLYNotificationHolder *> *notifications;
@property (nonatomic, strong) OPTLYProjectConfig *config;

@end

@implementation OPTLYNotificationCenter : NSObject

- (instancetype)initWithProjectConfig:(OPTLYProjectConfig *)config {
    self = [super init];
    if (self != nil) {
        _notificationId = 1;
        _config = config;
        _notifications = [NSMutableDictionary new];
        for (NSUInteger i = OPTLYNotificationTypeActivate; i <= OPTLYNotificationTypeGetFeatureVariable; i++) {
            NSNumber *number = [NSNumber numberWithUnsignedInteger:i];
            _notifications[number] = [NSMutableDictionary new];
        }
    }
    return self;
}

#pragma mark - Public Methods

- (NSUInteger)notificationsCount {
    NSUInteger notificationsCount = 0;
    for (OPTLYNotificationHolder *notificationsMap in _notifications.allValues) {
        notificationsCount += notificationsMap.count;
    }
    return notificationsCount;
}

- (NSInteger)addActivateNotificationListener:(ActivateListener)activateListener {
    return [self addNotification:OPTLYNotificationTypeActivate listener:(GenericListener) activateListener];
}

- (NSInteger)addTrackNotificationListener:(TrackListener)trackListener {
    return [self addNotification:OPTLYNotificationTypeTrack listener:(GenericListener)trackListener];
}
    
- (NSInteger)addFeatureEnabledNotificationListener:(FeatureEnabledListener)featureEnabledListener {
    return [self addNotification:OPTLYNotificationTypeIsFeatureEnabled listener:(GenericListener)featureEnabledListener];
}
    
- (NSInteger)addGetEnabledFeaturesNotificationListener:(GetEnabledFeaturesListener _Nonnull )getEnabledFeatureListener {
    return [self addNotification:OPTLYNotificationTypeGetEnabledFeatures listener:(GenericListener)getEnabledFeatureListener];
}
    
- (NSInteger)addGetFeatureVariableNotificationListener:(GetFeatureVariableListener)getFeatureVariableListener {
    return [self addNotification:OPTLYNotificationTypeGetFeatureVariable listener:(GenericListener)getFeatureVariableListener];
}

- (BOOL)removeNotificationListener:(NSUInteger)notificationId {
    for (NSNumber *notificationType in _notifications.allKeys) {
        OPTLYNotificationHolder *notificationMap = _notifications[notificationType];
        if (notificationMap != nil && [notificationMap.allKeys containsObject:@(notificationId)]) {
            [notificationMap removeObjectForKey:@(notificationId)];
            return YES;
        }
    }
    return NO;
}

- (void)clearNotificationListeners:(OPTLYNotificationType)type {
    [_notifications[@(type)] removeAllObjects];
}

- (void)clearAllNotificationListeners {
    for (NSNumber *notificationType in _notifications.allKeys) {
        [self clearNotificationListeners:[notificationType unsignedIntegerValue]];
    }
}

- (void)sendNotifications:(OPTLYNotificationType)type args:(NSDictionary *)args {
    OPTLYNotificationHolder *notification = _notifications[@(type)];
    for (GenericListener listener in notification.allValues) {
        @try {
            switch (type) {
                case OPTLYNotificationTypeActivate:
                    [self notifyActivateListener:((ActivateListener) listener) args:args];
                    break;
                case OPTLYNotificationTypeTrack:
                    [self notifyTrackListener:((TrackListener) listener) args:args];
                    break;
                case OPTLYNotificationTypeIsFeatureEnabled:
                    [self notifyFeatureEnabledListener:((FeatureEnabledListener) listener) args:args];
                    break;
                case OPTLYNotificationTypeGetEnabledFeatures:
                    [self notifyGetEnabledFeaturesListener:((GetEnabledFeaturesListener) listener) args:args];
                    break;
                case OPTLYNotificationTypeGetFeatureVariable:
                    [self notifyGetFeatureVariableListener:((GetFeatureVariableListener) listener) args:args];
                    break;
                default:
                    listener(args);
            }
        } @catch (NSException *exception) {
            NSString *logMessage = [NSString stringWithFormat:@"Problem calling notify callback. Error: %@", exception.reason];
            [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        }
    }
}

#pragma mark - Private Methods

- (NSInteger)addNotification:(OPTLYNotificationType)type listener:(GenericListener)listener {
    NSNumber *notificationTypeNumber = [NSNumber numberWithUnsignedInteger:type];
    NSNumber *notificationIdNumber = [NSNumber numberWithUnsignedInteger:_notificationId];
    OPTLYNotificationHolder *notificationHoldersList = _notifications[notificationTypeNumber];
    
    if (![_notifications.allKeys containsObject:notificationTypeNumber] || notificationHoldersList.count == 0) {
        notificationHoldersList[notificationIdNumber] = listener;
    } else {
        for (GenericListener notificationListener in notificationHoldersList.allValues) {
            if (notificationListener == listener) {
                [_config.logger logMessage:@"The notification callback already exists." withLevel:OptimizelyLogLevelError];
                return -1;
            }
        }
        notificationHoldersList[notificationIdNumber] = listener;
    }
    
    return _notificationId++;
}

- (void)notifyActivateListener:(ActivateListener)listener args:(NSDictionary *)args {
    
    if(args.allKeys.count < 3) {
        NSString *logMessage = [NSString stringWithFormat:@"Not enough arguments to call %@ for notification callback.", listener];
        [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        return; // Not enough arguments in the array
    }
    
    OPTLYExperiment *experiment = (OPTLYExperiment *)[args objectForKey:OPTLYNotificationExperimentKey];
    assert(experiment);
    assert([experiment isKindOfClass:[OPTLYExperiment class]]);
    
    NSString *userId = (NSString *)[args objectForKey:OPTLYNotificationUserIdKey];
    assert(userId);
    assert([userId isValidStringType]);
    
    NSDictionary *attributes = (NSDictionary *)[args objectForKey:OPTLYNotificationAttributesKey];
    
    if (attributes != nil && ![attributes isEqual:[NSNull null]]) {
        assert([attributes isKindOfClass:[NSDictionary class]]);
    }
    
    OPTLYVariation *variation = (OPTLYVariation *)[args objectForKey:OPTLYNotificationVariationKey];
    assert(variation);
    assert([variation isKindOfClass:[OPTLYVariation class]]);
    
    NSDictionary *logEvent = (NSDictionary *)[args objectForKey:OPTLYNotificationLogEventParamsKey];
    assert(logEvent);
    assert([logEvent isKindOfClass:[NSDictionary class]]);
    
    listener(experiment, userId, attributes, variation, logEvent);
}

- (void)notifyTrackListener:(TrackListener)listener args:(NSDictionary *)args {
    
    if(args.allKeys.count < 3) {
        NSString *logMessage = [NSString stringWithFormat:@"Not enough arguments to call %@ for notification callback.", listener];
        [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        return; // Not enough arguments in the array
    }
    
    NSString *eventKey = (NSString *)[args objectForKey:OPTLYNotificationEventKey];
    assert(eventKey);
    assert([eventKey isValidStringType]);
    
    NSString *userId = (NSString *)[args objectForKey:OPTLYNotificationUserIdKey];
    assert(userId);
    assert([userId isValidStringType]);
    
    NSDictionary *attributes = (NSDictionary *)[args objectForKey:OPTLYNotificationAttributesKey];
    if (attributes != nil && ![attributes isEqual:[NSNull null]]) {
        assert([attributes isKindOfClass:[NSDictionary class]]);
    }
    
    NSDictionary *eventTags = (NSDictionary *)[args objectForKey:OPTLYNotificationEventTagsKey];
    if (eventTags != nil && ![eventTags isEqual:[NSNull null]]) {
        assert([eventTags isKindOfClass:[NSDictionary class]]);
    }
    
    NSDictionary *logEvent = (NSDictionary *)[args objectForKey:OPTLYNotificationLogEventParamsKey];
    assert(logEvent);
    assert([logEvent isKindOfClass:[NSDictionary class]]);
    
    listener(eventKey, userId, attributes, eventTags, logEvent);
}
    
- (void)notifyFeatureEnabledListener:(FeatureEnabledListener)listener args:(NSDictionary *)args {
    
    if(args.allKeys.count < 3) {
        NSString *logMessage = [NSString stringWithFormat:@"Not enough arguments to call %@ for notification callback.", listener];
        [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        return; // Not enough arguments in the array
    }
    
    NSString *featureKey = (NSString *)[args objectForKey:OPTLYNotificationFeatureKey];
    assert(featureKey);
    assert([featureKey isValidStringType]);
    
    NSString *userId = (NSString *)[args objectForKey:OPTLYNotificationUserIdKey];
    assert(userId);
    assert([userId isValidStringType]);
    
    NSDictionary *attributes = (NSDictionary *)[args objectForKey:OPTLYNotificationAttributesKey];
    
    if (attributes != nil && ![attributes isEqual:[NSNull null]]) {
        assert([attributes isKindOfClass:[NSDictionary class]]);
    }
    
    NSDictionary *featureInfo = (NSDictionary *)[args objectForKey:OPTLYNotificationFeatureInfo];

    if (featureInfo != nil && ![featureInfo isEqual:[NSNull null]]) {
        assert([featureInfo isKindOfClass:[NSDictionary class]]);
    }
    
    NSNumber *featureEnabled = (NSNumber *)[featureInfo objectForKey:OPTLYNotificationIsEnabled];
    assert(featureEnabled);
    
    NSString *source = (NSString *)[featureInfo objectForKey:OPTLYNotificationFeatureSource];
    assert(source);
    assert([source isValidStringType]);
    
    NSDictionary *logEvent = (NSDictionary *)[featureInfo objectForKey:OPTLYNotificationEvent];
    if (logEvent != nil && ![logEvent isEqual:[NSNull null]]) {
        assert([logEvent isKindOfClass:[NSDictionary class]]);
    }
    
    listener(featureKey, userId, attributes, featureInfo);
}
    
- (void)notifyGetEnabledFeaturesListener:(GetEnabledFeaturesListener)listener args:(NSDictionary *)args {
    
    if(args.allKeys.count < 3) {
        NSString *logMessage = [NSString stringWithFormat:@"Not enough arguments to call %@ for notification callback.", listener];
        [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        return; // Not enough arguments in the array
    }
    
    NSString *userId = (NSString *)[args objectForKey:OPTLYNotificationUserIdKey];
    assert(userId);
    assert([userId isValidStringType]);
    
    NSDictionary *attributes = (NSDictionary *)[args objectForKey:OPTLYNotificationAttributesKey];
    
    if (attributes != nil && ![attributes isEqual:[NSNull null]]) {
        assert([attributes isKindOfClass:[NSDictionary class]]);
    }
    
    NSArray<NSString *> *enabledFeatures = (NSArray<NSString *> *)[args objectForKey:OPTLYNotificationEnabledFeatures];
    assert(enabledFeatures);
    
    listener(userId, attributes, enabledFeatures);
}
    
- (void)notifyGetFeatureVariableListener:(GetFeatureVariableListener)listener args:(NSDictionary *)args {
    
    if(args.allKeys.count < 3) {
        NSString *logMessage = [NSString stringWithFormat:@"Not enough arguments to call %@ for notification callback.", listener];
        [_config.logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        return; // Not enough arguments in the array
    }
    
    NSString *featureKey = (NSString *)[args objectForKey:OPTLYNotificationFeatureKey];
    assert(featureKey);
    assert([featureKey isValidStringType]);
    
    NSString *variableKey = (NSString *)[args objectForKey:OPTLYNotificationVariableKey];
    assert(variableKey);
    assert([variableKey isValidStringType]);
    
    NSString *userId = (NSString *)[args objectForKey:OPTLYNotificationUserIdKey];
    assert(userId);
    assert([userId isValidStringType]);
    
    NSDictionary *attributes = (NSDictionary *)[args objectForKey:OPTLYNotificationAttributesKey];
    
    if (attributes != nil && ![attributes isEqual:[NSNull null]]) {
        assert([attributes isKindOfClass:[NSDictionary class]]);
    }
    
    NSDictionary *featureInfo = (NSDictionary *)[args objectForKey:OPTLYNotificationFeatureVariableInfo];
    
    if (featureInfo != nil && ![featureInfo isEqual:[NSNull null]]) {
        assert([featureInfo isKindOfClass:[NSDictionary class]]);
    }
    
    NSNumber *featureEnabled = (NSNumber *)[featureInfo objectForKey:OPTLYNotificationFeatureEnabled];
    assert(featureEnabled);
    
    NSString *source = (NSString *)[featureInfo objectForKey:OPTLYNotificationFeatureEnabledSource];
    assert(source);
    assert([source isValidStringType]);
    
    NSString *variableValue = (NSString *)[featureInfo objectForKey:OPTLYNotificationVariableValue];
    assert(variableValue);
    assert([variableValue isValidStringType]);
    
    NSString *variableType = (NSString *)[featureInfo objectForKey:OPTLYNotificationVariableType];
    assert(variableType);
    assert([variableType isValidStringType]);
    
    listener(featureKey, variableKey, userId, attributes, featureInfo);
}

@end
