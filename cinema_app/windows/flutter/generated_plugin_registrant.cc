//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <firebase_core/firebase_core_plugin_c_api.h>
<<<<<<< HEAD
#include <cloud_firestore/cloud_firestore_plugin_c_api.h>
#include <firebase_auth/firebase_auth_plugin_c_api.h>
=======
>>>>>>> e4664b6adbd5fd20042b65af73592313864d5c45

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
<<<<<<< HEAD
  CloudFirestorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CloudFirestorePluginCApi"));
  FirebaseAuthPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
=======
>>>>>>> e4664b6adbd5fd20042b65af73592313864d5c45
}
