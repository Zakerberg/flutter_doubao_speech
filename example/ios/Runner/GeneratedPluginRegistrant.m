//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<doubao_speech/DoubaoSpeechPlugin.h>)
#import <doubao_speech/DoubaoSpeechPlugin.h>
#else
@import doubao_speech;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [DoubaoSpeechPlugin registerWithRegistrar:[registry registrarForPlugin:@"DoubaoSpeechPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
}

@end
