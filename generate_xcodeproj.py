#!/usr/bin/env python3
"""Generates GymWalkLog.xcodeproj/project.pbxproj"""

import os
import hashlib

BASE = "/Users/ac/Desktop/ジム歩走ログ"

def uid(name):
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

# ─── File list ────────────────────────────────────────────────────────────────
SOURCES = [
    ("GymWalkLog/GymWalkLogApp.swift",                   "GymWalkLogApp.swift"),
    ("GymWalkLog/MainTabView.swift",                     "MainTabView.swift"),
    ("GymWalkLog/Models/WorkoutRecord.swift",            "WorkoutRecord.swift"),
    ("GymWalkLog/Models/AppSettings.swift",              "AppSettings.swift"),
    ("GymWalkLog/Managers/PurchaseManager.swift",        "PurchaseManager.swift"),
    ("GymWalkLog/Managers/NotificationManager.swift",    "NotificationManager.swift"),
    ("GymWalkLog/Views/Home/HomeView.swift",             "HomeView.swift"),
    ("GymWalkLog/Views/Home/MiniCalendarView.swift",     "MiniCalendarView.swift"),
    ("GymWalkLog/Views/Record/NewRecordView.swift",      "NewRecordView.swift"),
    ("GymWalkLog/Views/Record/RecordDetailView.swift",   "RecordDetailView.swift"),
    ("GymWalkLog/Views/List/RecordListView.swift",       "RecordListView.swift"),
    ("GymWalkLog/Views/Stats/StatsView.swift",           "StatsView.swift"),
    ("GymWalkLog/Views/Settings/SettingsView.swift",     "SettingsView.swift"),
    ("GymWalkLog/Views/Pro/ProUpgradeView.swift",        "ProUpgradeView.swift"),
    ("GymWalkLog/Extensions/ColorTheme.swift",           "ColorTheme.swift"),
]

RESOURCES = [
    ("GymWalkLog/Assets.xcassets",                       "Assets.xcassets"),
    ("GymWalkLog/Preview Content/Preview Assets.xcassets", "Preview Assets.xcassets"),
]

INFOPLIST = ("GymWalkLog/Info.plist", "Info.plist")

# ─── UUID constants ─────────────────────────────────────────────────────────
P_PROJECT         = uid("project_root")
P_TARGET          = uid("target_main")
P_SOURCES_PHASE   = uid("phase_sources")
P_RESOURCES_PHASE = uid("phase_resources")
P_FRAMEWORKS_PHASE= uid("phase_frameworks")
P_DEBUG_CONFIG    = uid("config_debug")
P_RELEASE_CONFIG  = uid("config_release")
P_TARGET_DEBUG    = uid("target_config_debug")
P_TARGET_RELEASE  = uid("target_config_release")
P_CONFIGLIST_PROJ = uid("configlist_project")
P_CONFIGLIST_TGT  = uid("configlist_target")
P_MAIN_GROUP      = uid("group_main")
P_PRODUCT_GROUP   = uid("group_products")
P_FRAMEWORK_GROUP = uid("group_frameworks")
P_APP_PRODUCT     = uid("product_app")

# Framework UUIDs
FRAMEWORKS = [
    ("SwiftUI",            "SwiftUI.framework"),
    ("Foundation",         "Foundation.framework"),
    ("StoreKit",           "StoreKit.framework"),
    ("UserNotifications",  "UserNotifications.framework"),
    ("PhotosUI",           "PhotosUI.framework"),
    ("Charts",             "Charts.framework"),
    ("SwiftData",          "SwiftData.framework"),
]

# Subgroup UUIDs
SUBGROUPS = {
    "GymWalkLog":          uid("group_gymwalklog"),
    "Models":              uid("group_models"),
    "Managers":            uid("group_managers"),
    "Views":               uid("group_views"),
    "Home":                uid("group_views_home"),
    "Record":              uid("group_views_record"),
    "List":                uid("group_views_list"),
    "Stats":               uid("group_views_stats"),
    "Settings":            uid("group_views_settings"),
    "Pro":                 uid("group_views_pro"),
    "Extensions":          uid("group_extensions"),
    "Preview Content":     uid("group_preview"),
}

def file_ref_uid(path): return uid("ref_" + path)
def build_file_uid(path): return uid("bf_" + path)
def fw_ref_uid(name): return uid("fwref_" + name)
def fw_build_uid(name): return uid("fwbf_" + name)
def info_ref_uid(): return uid("ref_infoplist")

lines = []
def w(s=""): lines.append(s)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 56;")
w("\tobjects = {")
w()
w("/* Begin PBXBuildFile section */")

for path, name in SOURCES:
    w(f"\t\t{build_file_uid(path)} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uid(path)} /* {name} */; }};")

for path, name in RESOURCES:
    w(f"\t\t{build_file_uid(path)} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uid(path)} /* {name} */; }};")

for short, full in FRAMEWORKS:
    w(f"\t\t{fw_build_uid(short)} /* {full} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fw_ref_uid(short)} /* {full} */; }};")

w("/* End PBXBuildFile section */")
w()
w("/* Begin PBXFileReference section */")

for path, name in SOURCES:
    w(f"\t\t{file_ref_uid(path)} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")

for path, name in RESOURCES:
    if name.endswith(".xcassets"):
        ftype = "folder.assetcatalog"
    else:
        ftype = "file"
    w(f"\t\t{file_ref_uid(path)} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; name = {name}; path = \"{path.split('/', 1)[1]}\"; sourceTree = \"<group>\"; }};")

for short, full in FRAMEWORKS:
    w(f"\t\t{fw_ref_uid(short)} /* {full} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {full}; path = System/Library/Frameworks/{full}; sourceTree = SDKROOT; }};")

# Info.plist
path, name = INFOPLIST
w(f"\t\t{info_ref_uid()} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {name}; sourceTree = \"<group>\"; }};")

# App product
w(f"\t\t{P_APP_PRODUCT} /* GymWalkLog.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GymWalkLog.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

w("/* End PBXFileReference section */")
w()
w("/* Begin PBXFrameworksBuildPhase section */")
w(f"\t\t{P_FRAMEWORKS_PHASE} /* Frameworks */ = {{")
w("\t\t\tisa = PBXFrameworksBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for short, full in FRAMEWORKS:
    w(f"\t\t\t\t{fw_build_uid(short)} /* {full} in Frameworks */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXFrameworksBuildPhase section */")
w()
w("/* Begin PBXGroup section */")

# Main group
w(f"\t\t{P_MAIN_GROUP} = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{SUBGROUPS['GymWalkLog']} /* GymWalkLog */,")
w(f"\t\t\t\t{P_FRAMEWORK_GROUP} /* Frameworks */,")
w(f"\t\t\t\t{P_PRODUCT_GROUP} /* Products */,")
w("\t\t\t);")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Products group
w(f"\t\t{P_PRODUCT_GROUP} /* Products */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{P_APP_PRODUCT} /* GymWalkLog.app */,")
w("\t\t\t);")
w("\t\t\tname = Products;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Frameworks group
w(f"\t\t{P_FRAMEWORK_GROUP} /* Frameworks */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for short, full in FRAMEWORKS:
    w(f"\t\t\t\t{fw_ref_uid(short)} /* {full} */,")
w("\t\t\t);")
w("\t\t\tname = Frameworks;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# GymWalkLog root group
w(f"\t\t{SUBGROUPS['GymWalkLog']} /* GymWalkLog */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
# Top-level swift files
for path, name in SOURCES:
    parts = path.split("/")
    if len(parts) == 2:  # GymWalkLog/File.swift
        w(f"\t\t\t\t{file_ref_uid(path)} /* {name} */,")
w(f"\t\t\t\t{SUBGROUPS['Models']} /* Models */,")
w(f"\t\t\t\t{SUBGROUPS['Managers']} /* Managers */,")
w(f"\t\t\t\t{SUBGROUPS['Views']} /* Views */,")
w(f"\t\t\t\t{SUBGROUPS['Extensions']} /* Extensions */,")
w(f"\t\t\t\t{file_ref_uid(RESOURCES[0][0])} /* Assets.xcassets */,")
w(f"\t\t\t\t{info_ref_uid()} /* Info.plist */,")
w(f"\t\t\t\t{SUBGROUPS['Preview Content']} /* Preview Content */,")
w("\t\t\t);")
w("\t\t\tpath = GymWalkLog;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Models group
w(f"\t\t{SUBGROUPS['Models']} /* Models */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for path, name in SOURCES:
    if "Models/" in path:
        w(f"\t\t\t\t{file_ref_uid(path)} /* {name} */,")
w("\t\t\t);")
w("\t\t\tpath = Models;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Managers group
w(f"\t\t{SUBGROUPS['Managers']} /* Managers */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for path, name in SOURCES:
    if "Managers/" in path:
        w(f"\t\t\t\t{file_ref_uid(path)} /* {name} */,")
w("\t\t\t);")
w("\t\t\tpath = Managers;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Views group
w(f"\t\t{SUBGROUPS['Views']} /* Views */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for sub in ["Home", "Record", "List", "Stats", "Settings", "Pro"]:
    w(f"\t\t\t\t{SUBGROUPS[sub]} /* {sub} */,")
w("\t\t\t);")
w("\t\t\tpath = Views;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

for sub in ["Home", "Record", "List", "Stats", "Settings", "Pro"]:
    prefix = f"GymWalkLog/Views/{sub}/"
    files = [(p, n) for p, n in SOURCES if p.startswith(prefix)]
    w(f"\t\t{SUBGROUPS[sub]} /* {sub} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for path, name in files:
        w(f"\t\t\t\t{file_ref_uid(path)} /* {name} */,")
    w("\t\t\t);")
    w(f"\t\t\tpath = {sub};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

# Extensions group
w(f"\t\t{SUBGROUPS['Extensions']} /* Extensions */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for path, name in SOURCES:
    if "Extensions/" in path:
        w(f"\t\t\t\t{file_ref_uid(path)} /* {name} */,")
w("\t\t\t);")
w("\t\t\tpath = Extensions;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Preview Content group
w(f"\t\t{SUBGROUPS['Preview Content']} /* Preview Content */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{file_ref_uid(RESOURCES[1][0])} /* Preview Assets.xcassets */,")
w("\t\t\t);")
w("\t\t\tpath = \"Preview Content\";")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

w("/* End PBXGroup section */")
w()
w("/* Begin PBXNativeTarget section */")
w(f"\t\t{P_TARGET} /* GymWalkLog */ = {{")
w("\t\t\tisa = PBXNativeTarget;")
w("\t\t\tbuildConfigurationList = " + P_CONFIGLIST_TGT + " /* Build configuration list for PBXNativeTarget \"GymWalkLog\" */;")
w("\t\t\tbuildPhases = (")
w(f"\t\t\t\t{P_SOURCES_PHASE} /* Sources */,")
w(f"\t\t\t\t{P_FRAMEWORKS_PHASE} /* Frameworks */,")
w(f"\t\t\t\t{P_RESOURCES_PHASE} /* Resources */,")
w("\t\t\t);")
w("\t\t\tbuildRules = (")
w("\t\t\t);")
w("\t\t\tdependencies = (")
w("\t\t\t);")
w("\t\t\tname = GymWalkLog;")
w("\t\t\tproductName = GymWalkLog;")
w(f"\t\t\tproductReference = {P_APP_PRODUCT} /* GymWalkLog.app */;")
w("\t\t\tproductType = \"com.apple.product-type.application\";")
w("\t\t};")
w("/* End PBXNativeTarget section */")
w()
w("/* Begin PBXProject section */")
w(f"\t\t{P_PROJECT} /* Project object */ = {{")
w("\t\t\tisa = PBXProject;")
w("\t\t\tattributes = {")
w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
w("\t\t\t\tLastUpgradeCheck = 1500;")
w("\t\t\t\tTargetAttributes = {")
w(f"\t\t\t\t\t{P_TARGET} = {{")
w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
w("\t\t\t\t\t};")
w("\t\t\t\t};")
w("\t\t\t};")
w(f"\t\t\tbuildConfigurationList = {P_CONFIGLIST_PROJ} /* Build configuration list for PBXProject \"GymWalkLog\" */;")
w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
w("\t\t\tdevelopmentRegion = ja;")
w("\t\t\thasScannedForEncodings = 0;")
w("\t\t\tknownRegions = (")
w("\t\t\t\ten,")
w("\t\t\t\tja,")
w("\t\t\t\tBase,")
w("\t\t\t);")
w(f"\t\t\tmainGroup = {P_MAIN_GROUP};")
w(f"\t\t\tproductRefGroup = {P_PRODUCT_GROUP} /* Products */;")
w("\t\t\tprojectDirPath = \"\";")
w("\t\t\tprojectRoot = \"\";")
w("\t\t\ttargets = (")
w(f"\t\t\t\t{P_TARGET} /* GymWalkLog */,")
w("\t\t\t);")
w("\t\t};")
w("/* End PBXProject section */")
w()
w("/* Begin PBXResourcesBuildPhase section */")
w(f"\t\t{P_RESOURCES_PHASE} /* Resources */ = {{")
w("\t\t\tisa = PBXResourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for path, name in RESOURCES:
    w(f"\t\t\t\t{build_file_uid(path)} /* {name} in Resources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXResourcesBuildPhase section */")
w()
w("/* Begin PBXSourcesBuildPhase section */")
w(f"\t\t{P_SOURCES_PHASE} /* Sources */ = {{")
w("\t\t\tisa = PBXSourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for path, name in SOURCES:
    w(f"\t\t\t\t{build_file_uid(path)} /* {name} in Sources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXSourcesBuildPhase section */")
w()
w("/* Begin XCBuildConfiguration section */")

debug_settings = """				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

release_settings = """				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;"""

w(f"\t\t{P_DEBUG_CONFIG} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w(debug_settings)
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

w(f"\t\t{P_RELEASE_CONFIG} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w(release_settings)
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

target_debug = """				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\\"GymWalkLog/Preview Content\\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = GymWalkLog/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.gymwalklog.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;"""

target_release = target_debug

w(f"\t\t{P_TARGET_DEBUG} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w(target_debug)
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

w(f"\t\t{P_TARGET_RELEASE} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w(target_release)
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

w("/* End XCBuildConfiguration section */")
w()
w("/* Begin XCConfigurationList section */")

w(f"\t\t{P_CONFIGLIST_PROJ} /* Build configuration list for PBXProject \"GymWalkLog\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{P_DEBUG_CONFIG} /* Debug */,")
w(f"\t\t\t\t{P_RELEASE_CONFIG} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")

w(f"\t\t{P_CONFIGLIST_TGT} /* Build configuration list for PBXNativeTarget \"GymWalkLog\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{P_TARGET_DEBUG} /* Debug */,")
w(f"\t\t\t\t{P_TARGET_RELEASE} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")

w("/* End XCConfigurationList section */")
w("\t};")
w(f"\trootObject = {P_PROJECT} /* Project object */;")
w("}")

proj_dir = os.path.join(BASE, "GymWalkLog.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)
output_path = os.path.join(proj_dir, "project.pbxproj")
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Generated: {output_path}")
