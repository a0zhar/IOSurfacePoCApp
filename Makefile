# Project variables
NAME := explt
PROJECT_FILE := $(shell find . -name "*.xcodeproj" | head -n 1)
ARCHIVE_PATH := ./build/$(NAME).xcarchive
DERIVED_DATA_PATH := ./build/DerivedData
STAGE_DIR := ./build/stage
EXPORT_PATH := ./build
EXPORT_OPTIONS_PLIST := ./exportOptions.plist
IPA_PATH := $(EXPORT_PATH)/$(NAME).ipa
PAYLOAD_DIR := $(STAGE_DIR)/Payload

# Target to build the unsigned IPA
all: package

# Step 1: Set up Xcode environment
setup_xcode:
	@echo "Checking available Xcode versions..."
	@ls /Applications | grep Xcode
	@echo "Targeting Xcode 16.1..."
	@if [ ! -d "/Applications/Xcode_16.1.app" ]; then \
		echo "Error: Xcode 16.1 is not installed on the system."; \
		exit 1; \
	fi
	@echo "Switching to Xcode 16.1..."
	@sudo xcode-select --switch /Applications/Xcode_16.1.app/Contents/Developer
	@xcodebuild -version

# Step 2: Clean the project
clean:
	@if [ -z "$(PROJECT_FILE)" ]; then \
		echo "Error: No .xcodeproj file found."; \
		exit 1; \
	fi
	@echo "Cleaning the project..."
	@xcodebuild -project "$(PROJECT_FILE)" \
		-scheme $(NAME) \
		-configuration Debug \
		-sdk iphoneos \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		clean

# Step 3: Build and archive the project
archive:
	@if [ -z "$(PROJECT_FILE)" ]; then \
		echo "Error: No .xcodeproj file found."; \
		exit 1; \
	fi
	@echo "Building and archiving the app (unsigned)..."
	@xcodebuild -project "$(PROJECT_FILE)" \
		-scheme $(NAME) \
		-configuration Debug \
		-sdk iphoneos \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		-archivePath "$(ARCHIVE_PATH)" \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_ENTITLEMENTS="" \
		CODE_SIGNING_ALLOWED=NO \
		archive

# Step 4: Stage and package the app
stage:
	@echo "Preparing staging directory..."
	@rm -rf $(STAGE_DIR)
	@mkdir -p $(PAYLOAD_DIR)
	@mv $(ARCHIVE_PATH)/Products/Applications/$(NAME).app $(PAYLOAD_DIR)
	@rm -rf $(PAYLOAD_DIR)/_CodeSignature

package:
	@echo "Packaging unsigned IPA..."
	@$(MAKE) clean
	@$(MAKE) archive
	@$(MAKE) stage
	@rm -f $(IPA_PATH)
	@zip -r9 $(IPA_PATH) -j $(STAGE_DIR)/Payload
	@echo "Unsigned IPA created successfully at $(IPA_PATH)"

# Clean all build artifacts
clean_all:
	@echo "Cleaning all build files..."
	@rm -rf build Payload
