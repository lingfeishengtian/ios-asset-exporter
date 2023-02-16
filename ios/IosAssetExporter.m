//
//  RCTBridge.m
//  Filen
//
//  Created by Hunter Han on 2/15/23.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AssetExporter, NSObject)

RCT_EXTERN_METHOD(exportPhotoAssets:(NSArray *)withIdentifiers to:(NSString *)to withPrefix:(NSString *)withPrefix shouldRemoveExistingFile:(BOOL)shouldRemoveExistingFile ignoreBlacklist:(BOOL)ignoreBlacklist callback:(RCTResponseSenderBlock)callback
 )

@end
