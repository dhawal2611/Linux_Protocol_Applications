# =============================================================================
# Recipe Metadata
# =============================================================================
# Summary description of the package (displays in package management tools)
SUMMARY = "SPI Userspace Application"

# License configuration
LICENSE = "MIT"
# Checksum of the license file to verify compliance and detect changes
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# =============================================================================
# Source Configuration
# =============================================================================
# List of local source files located in the recipe's 'files' directory
SRC_URI = "file://dspi.c \
           file://dspi.h \
           file://dspiw25qxx.c \
           file://dspiw25qxx.h \
           file://Makefile \
"

# Set the source directory to the working directory where files are unpacked
S = "${WORKDIR}"

# =============================================================================
# Build Tasks
# =============================================================================
# Compilation step using the BitBake standard make wrapper (oe_runmake)
do_compile() {
    # -C ${S} directs make to execute in the source directory
    # ${EXTRA_OEMAKE} ensures Yocto's cross-compiler flags (CFLAGS, LDFLAGS) are passed
    oe_runmake -C ${S} ${EXTRA_OEMAKE}
}

# Installation step to place files into the target root filesystem layout
do_install() {
    # Create the destination binary directory matching standard target paths (/usr/bin)
    install -d ${D}${bindir}
    
    # Install the compiled executable with executable permissions (0755)
    # Target binary name explicitly matches the Makefile output target
    install -m 0755 ${S}/dspiw25qxx ${D}${bindir}/
}
