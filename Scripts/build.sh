#!/bin/zsh

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
project_root="$(cd -- "$script_dir/.." && pwd)"
source_dir="$project_root/InputPin"
build_root="$project_root/build"
output_dir="$build_root/Release"
app_path="$output_dir/InputPin.app"
module_cache="$build_root/module-cache"

for required_file in \
    "$source_dir/main.swift" \
    "$source_dir/AppDelegate.swift" \
    "$source_dir/AudioDevice.swift" \
    "$source_dir/AudioManager.swift" \
    "$source_dir/LoginItemManager.swift" \
    "$source_dir/Settings.swift" \
    "$source_dir/StatusBarController.swift" \
    "$source_dir/Info.plist"; do
    if [[ ! -f "$required_file" ]]; then
        print -u2 "Missing required source file: $required_file"
        exit 1
    fi
done

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
swiftc_path="$(xcrun --sdk macosx --find swiftc)"
lipo_path="$(xcrun --sdk macosx --find lipo)"

mkdir -p "$output_dir" "$module_cache/arm64" "$module_cache/x86_64"

sources=(
    "$source_dir/main.swift"
    "$source_dir/AppDelegate.swift"
    "$source_dir/AudioDevice.swift"
    "$source_dir/AudioManager.swift"
    "$source_dir/LoginItemManager.swift"
    "$source_dir/Settings.swift"
    "$source_dir/StatusBarController.swift"
)

compile_architecture() {
    local architecture="$1"
    local binary_path="$build_root/InputPin-$architecture"
    local architecture_cache="$module_cache/$architecture"

    CLANG_MODULE_CACHE_PATH="$architecture_cache/clang" \
        SWIFT_MODULE_CACHE_PATH="$architecture_cache/swift" \
        "$swiftc_path" \
        -swift-version 5 \
        -O \
        -sdk "$sdk_path" \
        -target "$architecture-apple-macosx13.0" \
        "${sources[@]}" \
        -o "$binary_path" \
        -framework AppKit \
        -framework CoreAudio \
        -framework ServiceManagement
}

print "Building InputPin for arm64..."
compile_architecture arm64

print "Building InputPin for x86_64..."
compile_architecture x86_64

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

"$lipo_path" -create \
    "$build_root/InputPin-arm64" \
    "$build_root/InputPin-x86_64" \
    -output "$app_path/Contents/MacOS/InputPin"

cp "$source_dir/Info.plist" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDevelopmentRegion en" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable InputPin" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.inputpin.app" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName InputPin" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType APPL" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 13.0" "$app_path/Contents/Info.plist"

/usr/bin/codesign --force --sign - --timestamp=none "$app_path"

print "Built universal app: $app_path"
print "Run it with: open \"$app_path\""
