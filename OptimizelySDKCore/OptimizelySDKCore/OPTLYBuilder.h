/*************************************************************************** 
 * Copyright 2016 Optimizely                                                *
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

@class OPTLYProjectConfig, OPTLYBucketer, OPTLYEventBuilder, OPTLYEventBuilderDefault;
@protocol OPTLYErrorHandler, OPTLYEventBuilder, OPTLYEventDispatcher, OPTLYLogger;

/**
 * This class contains the information on how your Optimizely instance will be built.
 */

@class OPTLYBuilder;

/// This is a block that takes the builder values.
typedef void (^OPTLYBuilderBlock)(OPTLYBuilder * _Nullable builder);

@interface OPTLYBuilder: NSObject

/// A datafile is required to create an Optimizely object.
@property (nonatomic, readwrite, strong, nullable) NSData *datafile;
/// The Project Configuration created by the builder.
@property (nonatomic, readonly, strong, nullable) OPTLYProjectConfig *config;
/// The bucketer created by the builder.
@property (nonatomic, readonly, strong, nullable) OPTLYBucketer *bucketer;
/// The event builder created by the builder.
@property (nonatomic, readonly, strong, nullable) OPTLYEventBuilderDefault *eventBuilder;
/// The error handler is by default set to one that is created by Optimizely. This default error handler can be overridden by any object that conforms to the OPTLYErrorHandler protocol.
@property (nonatomic, readwrite, strong, nullable) id<OPTLYErrorHandler> errorHandler;
/// The event dispatcher is by default set to one that is created by Optimizely. This default event dispatcher can be overridden by any object that conforms to the OPTLYEventDispatcher protocol.
@property (nonatomic, readwrite, strong, nullable) id<OPTLYEventDispatcher> eventDispatcher;
/// The logger is by default set to one that is created by Optimizely. This default logger can be overridden by any object that conforms to the OPTLYLogger protocol.
@property (nonatomic, readwrite, strong, nullable) id<OPTLYLogger> logger;

/// Create an Optimizely Builder object.
+ (nullable instancetype)builderWithBlock:(nonnull OPTLYBuilderBlock)block;

@end