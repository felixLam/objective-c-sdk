/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

#import <Foundation/Foundation.h>

@class OPTLYProjectConfig, OPTLYExperiment, OPTLYVariation;

/// Enum representing notification types.
typedef NS_ENUM(NSUInteger, OPTLYNotificationType) {
    OPTLYNotificationTypeActivate,
    OPTLYNotificationTypeTrack,
    OPTLYNotificationTypeIsFeatureEnabled,
    OPTLYNotificationTypeGetEnabledFeatures,
    OPTLYNotificationTypeGetFeatureVariable
};

typedef void (^ActivateListener)(OPTLYExperiment * _Nonnull experiment,
                                 NSString * _Nonnull userId,
                                 NSDictionary<NSString *, NSObject *> * _Nullable attributes,
                                 OPTLYVariation * _Nonnull variation,
                                 NSDictionary<NSString *,NSObject *> * _Nonnull event);

typedef void (^TrackListener)(NSString * _Nonnull eventKey,
                              NSString * _Nonnull userId,
                              NSDictionary<NSString *, NSObject *> * _Nullable attributes,
                              NSDictionary * _Nullable eventTags,
                              NSDictionary<NSString *,NSObject *> * _Nonnull event);

typedef void (^FeatureEnabledListener)(NSString * _Nonnull featureKey,
                                       NSString * _Nonnull userId,
                                       NSDictionary<NSString *, NSObject *> * _Nullable attributes,
                                       NSDictionary<NSString *, NSObject *> * _Nullable featureInfo);

typedef void (^GetEnabledFeaturesListener)(NSString * _Nonnull userId,
                                          NSDictionary<NSString *, NSObject *> * _Nullable attributes,
                                          NSArray<NSString *> * _Nullable enabledFeatures);

typedef void (^GetFeatureVariableListener)(NSString * _Nonnull featureKey,
                                           NSString * _Nonnull variableKey,
                                           NSString * _Nonnull userId,
                                           NSDictionary<NSString *, NSObject *> * _Nullable attributes,
                                           NSDictionary<NSString *, NSObject *> * _Nullable featureVariableInfo);

typedef void (^GenericListener)(NSDictionary * _Nonnull args);

typedef NSMutableDictionary<NSNumber *, GenericListener > OPTLYNotificationHolder;

extern NSString * _Nonnull const OPTLYNotificationExperimentKey;
extern NSString * _Nonnull const OPTLYNotificationVariationKey;
extern NSString * _Nonnull const OPTLYNotificationUserIdKey;
extern NSString * _Nonnull const OPTLYNotificationAttributesKey;
extern NSString * _Nonnull const OPTLYNotificationEventKey;
extern NSString * _Nonnull const OPTLYNotificationLogEventParamsKey;
/// track Notification Keys
extern NSString * _Nonnull const OPTLYNotificationEventTagsKey;
/// isFeatureEnabled Notification Keys
extern NSString * _Nonnull const OPTLYNotificationFeatureSource;
extern NSString * _Nonnull const OPTLYNotificationIsEnabled;
extern NSString * _Nonnull const OPTLYNotificationFeatureInfo;
extern NSString * _Nonnull const OPTLYNotificationEvent;
/// getEnabledFeatures Notification Keys
extern NSString * _Nonnull const OPTLYNotificationEnabledFeatures;
/// getFeatureVariable Notification Keys
extern NSString * _Nonnull const OPTLYNotificationFeatureKey;
extern NSString * _Nonnull const OPTLYNotificationVariableKey;
extern NSString * _Nonnull const OPTLYNotificationVariableValue;
extern NSString * _Nonnull const OPTLYNotificationVariableType;
extern NSString * _Nonnull const OPTLYNotificationFeatureEnabled;
extern NSString * _Nonnull const OPTLYNotificationFeatureEnabledSource;
extern NSString * _Nonnull const OPTLYNotificationFeatureVariableInfo;

@interface OPTLYNotificationCenter : NSObject

// Notification Id represeting id of notification.
@property (nonatomic, readonly) NSUInteger notificationId;

/**
 * Initializer for the Notification Center.
 *
 * @param config The project configuration.
 * @return An instance of the notification center.
 */
- (nullable instancetype)initWithProjectConfig:(nonnull OPTLYProjectConfig *)config;

/**
 * Add an activate notification listener to the notification center.
 *
 * @param activateListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
- (NSInteger)addActivateNotificationListener:(nonnull ActivateListener)activateListener;

/**
 * Add a track notification listener to the notification center.
 *
 * @param trackListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
- (NSInteger)addTrackNotificationListener:(TrackListener _Nonnull )trackListener;
    
/**
 * Add a featureEnabled notification listener to the notification center.
 *
 * @param featureEnabledListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
- (NSInteger)addFeatureEnabledNotificationListener:(FeatureEnabledListener _Nonnull )featureEnabledListener;
    
/**
 * Add a getEnabledFeature notification listener to the notification center.
 *
 * @param getEnabledFeatureListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
- (NSInteger)addGetEnabledFeaturesNotificationListener:(GetEnabledFeaturesListener _Nonnull )getEnabledFeatureListener;
    
/**
 * Add a getFeatureVariable notification listener to the notification center.
 *
 * @param getFeatureVariableListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
- (NSInteger)addGetFeatureVariableNotificationListener:(GetFeatureVariableListener _Nonnull )getFeatureVariableListener;

/**
 * Remove the notification listener based on the notificationId passed back from addNotification.
 * @param notificationId the id passed back from add notification.
 * @return true if removed otherwise false (if the notification is already removed, it returns false).
 */
- (BOOL)removeNotificationListener:(NSUInteger)notificationId;

/**
 * Clear notification listeners by notification type.
 * @param type type of OPTLYNotificationType to remove.
 */
- (void)clearNotificationListeners:(OPTLYNotificationType)type;

/**
 * Clear out all the notification listeners.
 */
- (void)clearAllNotificationListeners;

//
/**
 * fire notificaitons of a certain type.
 * @param type type of OPTLYNotificationType to fire.
 * @param args The arg list changes depending on the type of notification sent.
 */
- (void)sendNotifications:(OPTLYNotificationType)type args:(nullable NSDictionary *)args;
@end
