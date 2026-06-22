#!/bin/bash

# Exit on any error
set -e

echo "=== Vercel Flutter Web Build Start ==="

# 1. Clone Flutter stable channel
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK already cloned, skipping..."
fi

# 2. Add Flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Verify installation
echo "Flutter version:"
flutter --version

# 4. Enable Web support
flutter config --enable-web

# 5. Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# 6. Build Web Release
echo "Compiling Flutter Web..."
flutter build web --release --no-tree-shake-icons

# 7. Prepare Vercel output directory
echo "Preparing deployment assets..."
mkdir -p dist
cp -r build/web/* dist/

echo "=== Vercel Flutter Web Build Completed successfully ==="
