#!/bin/bash

# Exit on error
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter doctor..."
flutter doctor

echo "Building frontend..."
cd frontend
flutter clean
flutter pub get
flutter build web --release

echo "Build complete."
