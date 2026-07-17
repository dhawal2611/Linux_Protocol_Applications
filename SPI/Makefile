#
# OpenWrt Package Makefile for the dspi application
#

# include rules.mk pulls in global OpenWrt build environment variables like $(TOPDIR)
include $(TOPDIR)/rules.mk

# Define fundamental package metadata
PKG_NAME:=dspi
PKG_VERSION:=1.0
PKG_RELEASE:=1

# include package.mk provides core functions like BuildPackage, INSTALL_DIR, and INSTALL_BIN
include $(INCLUDE_DIR)/package.mk

# Define how the package appears inside 'make menuconfig'
define Package/dspi
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Custom DSPI W25QXX Application
  
  # DEPENDS ensures dependencies are built/installed. 
  # The '+' prefix automatically selects the package if dspi is selected.
  # kmod-spi-dev is required to expose the /dev/spidev* interfaces.
  DEPENDS:=+kmod-spi-dev
endef

# Define a long-form description for 'make menuconfig' help text
define Package/dspi/description
  A custom application for interacting with W25QXX SPI flash memory chips.
endef

# Preparation Phase: Prepares the temporary build directory ($(PKG_BUILD_DIR))
# Note: Indented lines MUST start with a literal TAB character, not spaces.
define Build/Prepare
	# Create the temporary workspace directory under build_dir/
	mkdir -p $(PKG_BUILD_DIR)
	
	# Copy everything from your local './files' directory into the workspace
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

# Installation Phase: Defines how files are packaged into the final .ipk file
# Note: Indented lines MUST start with a literal TAB character, not spaces.
define Package/dspi/install
	# $(1) represents the target filesystem root (ipkg virtual root directory)
	# This safely creates the /usr/bin directory layout on the target
	$(INSTALL_DIR) $(1)/usr/bin
	
	# Copies the compiled 'dspi' binary into /usr/bin on the target filesystem
	# INSTALL_BIN preserves executable permission bits (rwxr-xr-x)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dspi $(1)/usr/bin/
endef

# This macro call glues everything together and tells the OpenWrt build 
# system to parse this file and generate the build targets.
$(eval $(call BuildPackage,dspi))
