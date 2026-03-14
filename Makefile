.PHONY: build run clean bundle dmg reset

APP_NAME = OpenFlow
BUNDLE_DIR = build/$(APP_NAME).app
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

# Build the executable
build:
	swift build -c release

# Create the .app bundle
bundle: build
	@echo "Creating $(APP_NAME).app bundle..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp .build/release/OpenFlow $(MACOS_DIR)/$(APP_NAME)
	@cp OpenFlow/Resources/Info.plist $(CONTENTS_DIR)/Info.plist
	@# Copy Assets if any icon files exist
	@if [ -d "OpenFlow/Resources/Assets.xcassets" ]; then \
		cp -r OpenFlow/Resources/Assets.xcassets $(RESOURCES_DIR)/; \
	fi
	@# Copy app icon if it exists
	@if [ -f "OpenFlow/Resources/AppIcon.icns" ]; then \
		cp OpenFlow/Resources/AppIcon.icns $(RESOURCES_DIR)/AppIcon.icns; \
	fi
	@# Ad-hoc code sign so macOS can track permissions consistently
	@codesign --force --sign - $(BUNDLE_DIR)
	@echo "✅ $(APP_NAME).app created and signed at $(BUNDLE_DIR)"

# Build, bundle, and run
run: bundle
	@echo "Launching $(APP_NAME)..."
	@open $(BUNDLE_DIR)

# Development build and run (debug)
dev:
	swift build
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp .build/debug/OpenFlow $(MACOS_DIR)/$(APP_NAME)
	@cp OpenFlow/Resources/Info.plist $(CONTENTS_DIR)/Info.plist
	@if [ -f "OpenFlow/Resources/AppIcon.icns" ]; then \
		cp OpenFlow/Resources/AppIcon.icns $(RESOURCES_DIR)/AppIcon.icns; \
	fi
	@codesign --force --sign - $(BUNDLE_DIR)
	@echo "Launching $(APP_NAME) (debug)..."
	@open $(BUNDLE_DIR)

# Create DMG installer (drag-and-drop to Applications)
dmg: bundle
	@chmod +x scripts/create-dmg.sh
	@bash scripts/create-dmg.sh

# Clean build artifacts
clean:
	swift package clean
	rm -rf build/
	@echo "✅ Cleaned"

# Install to /Applications
install: bundle
	@cp -r $(BUNDLE_DIR) /Applications/$(APP_NAME).app
	@echo "✅ Installed to /Applications/$(APP_NAME).app"

# Reset all app data (UserDefaults, database, models) for a fresh start
reset:
	@echo "Resetting $(APP_NAME) data..."
	@defaults delete com.openflow.app 2>/dev/null || true
	@rm -rf ~/Library/Application\ Support/OpenFlow
	@echo "✅ All app data cleared. Next launch will show onboarding."
