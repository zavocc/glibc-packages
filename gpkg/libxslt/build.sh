TERMUX_PKG_HOMEPAGE=http://xmlsoft.org/libxslt/
TERMUX_PKG_DESCRIPTION="XSLT processing library"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="COPYING"
TERMUX_PKG_MAINTAINER="@termux-pacman"
_MAJOR_VERSION=1.1
TERMUX_PKG_VERSION=${_MAJOR_VERSION}.42
TERMUX_PKG_SRCURL=https://download.gnome.org/sources/libxslt/${_MAJOR_VERSION}/libxslt-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=85ca62cac0d41fc77d3f6033da9df6fd73d20ea2fc18b0a3609ffb4110e1baeb
TERMUX_PKG_DEPENDS="libgcrypt-glibc, libxml2-glibc, liblzma-glibc"
TERMUX_PKG_SETUP_PYTHON=true
TERMUX_PKG_BUILD_DEPENDS="python-glibc"
