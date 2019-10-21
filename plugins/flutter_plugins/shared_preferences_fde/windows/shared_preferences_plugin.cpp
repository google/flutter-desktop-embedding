// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "shared_preferences_plugin.h"

#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <sstream>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

class WindowsSharedPreferences {
 public:
  WindowsSharedPreferences() : m_KeyOpen(false) {}

  ~WindowsSharedPreferences() { close(); }

  bool open(bool rw) {
    m_KeyOpen = openKey(&m_Key, rw);
    return m_KeyOpen;
  }

  void close() {
    if (m_KeyOpen) {
      closeKey(m_Key);
      m_KeyOpen = false;
    }
  }

  // Load all the keys from the registry and return as EncodableValues
  // returns empty map on error.
  EncodableValue getAll() {
    if (!m_KeyOpen) {
      return EncodableValue(EncodableMap());
    }

    DWORD valueCount, maxValueNameLen, maxValueLen;
    if (RegQueryInfoKey(m_Key, NULL, NULL, 0, NULL, NULL, NULL, &valueCount,
                        &maxValueNameLen, &maxValueLen, NULL,
                        NULL) != ERROR_SUCCESS) {
      return EncodableValue(EncodableMap());
    }

    // Add space for the zero terminators.
    maxValueNameLen++;
    maxValueLen++;

    std::unique_ptr<char[]> valueName =
        std::make_unique<char[]>(maxValueNameLen);
    std::unique_ptr<char[]> value = std::make_unique<char[]>(maxValueLen);

    EncodableMap map;
    for (unsigned int i = 0; i < valueCount; i++) {
      DWORD valueNameLen = maxValueNameLen;
      DWORD valueLen = maxValueLen;
      DWORD type;
      DWORD result = RegEnumValueA(m_Key, i, valueName.get(), &valueNameLen,
                                   NULL, &type, (LPBYTE)value.get(), &valueLen);
      if (result != ERROR_SUCCESS) {
        continue;
      }

      if (type == REG_SZ) {
        map.emplace(EncodableValue(valueName.get()),
                    EncodableValue(value.get()));
      }

      if (type == REG_BINARY) {
        if (valueLen < sizeof(FlutterRegistryEntry)) {
          OutputDebugString(TEXT("Invalid Binary Encoding, length too short."));
          continue;
        }

        FlutterRegistryEntry *re = (FlutterRegistryEntry *)value.get();

        switch (re->type) {
          case Bool:
            map.emplace(EncodableValue(valueName.get()), EncodableValue(re->b));
            break;
          case Double:
            map.emplace(EncodableValue(valueName.get()), EncodableValue(re->d));
            break;
          case Int32:
            map.emplace(EncodableValue(valueName.get()),
                        EncodableValue(re->int32));
            break;
          case Int64:
            map.emplace(EncodableValue(valueName.get()),
                        EncodableValue(re->int64));
            break;
          case StringList: {
            size_t pos = 0;
            std::vector<EncodableValue> strings;
            uint8_t *data = &re->sl[0];
            size_t stringListLength = valueLen - sizeof(FlutterRegistryEntry);
            while ((pos + 2) < stringListLength) {
              uint16_t len = data[pos + 0] << 8 | data[pos + 1];
              pos += 2;
              if (pos + len >= stringListLength) {
                OutputDebugString(
                    TEXT("Invalid binary encoding for StringList"));
                break;
              }

              std::string v;
              v.assign((char *)(data + pos), len);
              strings.push_back(EncodableValue(v));
              pos += len;
            }
            map.emplace(EncodableValue(valueName.get()), strings);
            break;
          }
        }
      }
    }

    return std::move(EncodableValue(std::move(map)));
  }

  bool setString(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    std::string strValue = value.StringValue();
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_SZ, strValue.c_str(),
                           (DWORD)strValue.length()) == ERROR_SUCCESS;
  }

  bool setInt32(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    FlutterRegistryEntry re = {};
    re.type = Int32;
    re.int32 = value.IntValue();
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_BINARY, &re,
                           sizeof(re)) == ERROR_SUCCESS;
  }

  bool setInt64(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    FlutterRegistryEntry re = {};
    ;
    re.type = Int64;
    re.int64 = value.LongValue();
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_BINARY, &re,
                           sizeof(re)) == ERROR_SUCCESS;
  }

  bool setDouble(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    FlutterRegistryEntry re = {};
    ;
    re.type = Double;
    re.d = value.DoubleValue();
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_BINARY, &re,
                           sizeof(re)) == ERROR_SUCCESS;
  }

  bool setBool(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    FlutterRegistryEntry re = {};
    ;
    re.type = Bool;
    re.b = value.BoolValue();
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_BINARY, &re,
                           sizeof(re)) == ERROR_SUCCESS;
  }

  bool setStringList(const std::string &name, const EncodableValue &value) {
    if (!m_KeyOpen) {
      return false;
    }

    const std::vector<EncodableValue> &strings = value.ListValue();

    uint32_t len = 1;
    for (const EncodableValue &value : strings) {
      std::string s = value.StringValue();
      len += 2;                     // lenght bytes.
      len += (uint32_t)s.length();  // data bytes
    }
    len += sizeof(FlutterRegistryEntry);

    std::unique_ptr<uint8_t[]> data = std::make_unique<uint8_t[]>(len);
    FlutterRegistryEntry *re = (FlutterRegistryEntry *)data.get();
    re->type = StringList;
    uint8_t *stringData = &re->sl[0];
    int pos = 0;
    for (const EncodableValue &value : strings) {
      std::string s = value.StringValue();
      size_t strlen = s.length();
      if (strlen > 0xffff) {
        OutputDebugString(TEXT("String too long."));
        continue;
      }
      stringData[pos++] = 0xff & (strlen >> 8);
      stringData[pos++] = strlen & 0xff;
      memcpy(stringData + pos, s.c_str(), strlen);
      pos += (uint16_t)strlen;
    }
    return RegSetKeyValueA(m_Key, NULL, name.c_str(), REG_BINARY, data.get(),
                           len) == ERROR_SUCCESS;
  }

  bool removeEntry(const std::string &name) {
    if (!m_KeyOpen) {
      return false;
    }

    return RegDeleteValueA(m_Key, name.c_str()) == ERROR_SUCCESS;
  }

  bool clear() {
    if (!m_KeyOpen) {
      return false;
    }

    DWORD valueCount, maxValueNameLen;
    if (RegQueryInfoKey(m_Key, NULL, NULL, 0, NULL, NULL, NULL, &valueCount,
                        &maxValueNameLen, NULL, NULL, NULL) != ERROR_SUCCESS) {
      return false;
    }

    // Add space for the zero terminators.
    maxValueNameLen++;
    std::unique_ptr<char[]> valueName =
        std::make_unique<char[]>(maxValueNameLen);
    std::vector<std::string> names;

    EncodableMap map;
    for (unsigned int i = 0; i < valueCount; i++) {
      DWORD valueNameLen = maxValueNameLen;
      DWORD type;
      DWORD result = RegEnumValueA(m_Key, i, valueName.get(), &valueNameLen,
                                   NULL, &type, NULL, NULL);
      if (result != ERROR_SUCCESS) {
        continue;
      }
      names.push_back(std::string(valueName.get(), valueNameLen));
    }

    for (auto name : names) {
      removeEntry(name);
    }

    return true;
  }

 private:
  // Windows Registry types do not match up with Flutter types
  // So for all types (except strings) we create a binary
  // registry key and store the type information with the value.

  // We could use the flutter EncodableValue::type field, but
  // since this api is still in flux decided against that so that
  // values in the registry stay valid.
  enum Types { Bool, Int32, Int64, Double, StringList };

  // Structure for encoding values in the binary registry field.
  typedef struct {
    Types type;
    union {
      bool b;
      int32_t int32;
      int64_t int64;
      double d;
    };
    // This field is used for storing the stringlist header
    // string list are composed of 2 bytes length fields
    // and then the string data (without terminating zeros)
    uint8_t sl[1];
  } FlutterRegistryEntry;

  bool m_KeyOpen;
  HKEY m_Key;

  std::string getFilename() {}

  // opens the registry key using the HKCU\Software\Flutter\<executable_name>
  // key.
  bool openKey(HKEY *key, bool rw) {
    // gets the whole path of the application
    // including the filename.
    char pn[2048];
    GetModuleFileNameA(NULL, (char *)&pn, 2048);
    pn[1023] = 0;

    // Try to find the executable name.
    std::string pathName = pn;
    std::size_t found = pathName.find_last_of("/\\");
    std::string fileName = pathName.substr(found + 1);

    // Create the registry key based on the above.
    std::string keyName = "Software\\Flutter\\" + fileName;
    DWORD disp;
    OutputDebugStringA(keyName.c_str());
    if (RegCreateKeyExA(HKEY_CURRENT_USER, keyName.c_str(), 0, NULL,
                        REG_OPTION_NON_VOLATILE,
                        rw ? KEY_WRITE | KEY_READ : KEY_READ, NULL, key,
                        &disp) != ERROR_SUCCESS) {
      return false;
    }
    return true;
  }

  // Close the key.
  void closeKey(HKEY key) { RegCloseKey(key); }
};

class SharedPreferencesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~SharedPreferencesPlugin();

 private:
  SharedPreferencesPlugin();

  // Called when a method is called on plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);
};

// static
void SharedPreferencesPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "plugins.flutter.io/shared_preferences",
      &flutter::StandardMethodCodec::GetInstance());

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<SharedPreferencesPlugin> plugin(
      new SharedPreferencesPlugin());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SharedPreferencesPlugin::SharedPreferencesPlugin() = default;

SharedPreferencesPlugin::~SharedPreferencesPlugin() = default;

void SharedPreferencesPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const std::string &method_name = method_call.method_name();
  WindowsSharedPreferences sharedPrefs;

  if (method_name.compare("getAll") == 0) {
    if (!sharedPrefs.open(false)) {
      result->Error("Failed to open Registry Key for Reading");
      return;
    }

    EncodableValue v = std::move(sharedPrefs.getAll());
    result->Success(&v);
    return;
  }

  if (method_name.compare("commit") == 0) {
    // we always store immediately.
    EncodableValue v = EncodableValue(true);
    result->Success(&v);
    return;
  }

  if (method_name.compare("clear") == 0) {
    if (!sharedPrefs.open(true)) {
      result->Error("Failed to open Registry Key for Writing");
      return;
    }

    EncodableValue v = EncodableValue(sharedPrefs.clear());
    result->Success(&v);
    return;
  }

  if (method_name.compare("remove") == 0) {
    if (!sharedPrefs.open(true)) {
      result->Error("Failed to open Registry Key for Writing");
      return;
    }

    std::string key;
    const EncodableMap &arguments = method_call.arguments()->MapValue();
    auto key_it = arguments.find(EncodableValue("key"));
    if (key_it != arguments.end()) {
      key = key_it->second.StringValue();
    }
    EncodableValue v = EncodableValue(sharedPrefs.removeEntry(key));
    result->Success(&v);
    return;
  }

  if (method_name.compare("setString") == 0 ||
      method_name.compare("setBool") == 0 ||
      method_name.compare("setDouble") == 0 ||
      method_name.compare("setInt") == 0 ||
      method_name.compare("setStringList") == 0) {
    if (!sharedPrefs.open(true)) {
      result->Error("Failed to open Registry Key for Writing");
      return;
    }

    std::string key;
    EncodableValue value;
    if (method_call.arguments() && method_call.arguments()->IsMap()) {
      const EncodableMap &arguments = method_call.arguments()->MapValue();
      auto key_it = arguments.find(EncodableValue("key"));
      if (key_it != arguments.end()) {
        key = key_it->second.StringValue();
      }

      auto value_it = arguments.find(EncodableValue("value"));

      if (value_it != arguments.end()) {
        value = value_it->second;
      }
      bool r = false;
      switch (value.type()) {
        case EncodableValue::Type::kBool:
          r = sharedPrefs.setBool(key, value);
          break;
        case EncodableValue::Type::kDouble:
          r = sharedPrefs.setDouble(key, value);
          break;
        case EncodableValue::Type::kInt:
          r = sharedPrefs.setInt32(key, value);
          break;
        case EncodableValue::Type::kLong:
          r = sharedPrefs.setInt64(key, value);
          break;
        case EncodableValue::Type::kString:
          r = sharedPrefs.setString(key, value);
          break;
        case EncodableValue::Type::kList:
          r = sharedPrefs.setStringList(key, value);
          break;
        default:
          result->Error("Type not implemented.");
          return;
      }

      EncodableValue res = EncodableValue(r);
      result->Success(&res);
      return;
    }

    result->Error("Missing arguments.");
    return;
  }

  result->NotImplemented();
}

}  // namespace

// extern "C" FLUTTER_PLUGIN_EXPORT
void SharedPreferencesPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  SharedPreferencesPlugin::RegisterWithRegistrar(plugin_registrar);
}
