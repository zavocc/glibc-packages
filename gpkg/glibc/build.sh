TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/libc/
TERMUX_PKG_DESCRIPTION="GNU C Library"
TERMUX_PKG_LICENSE="GPL-3.0, LGPL-3.0"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=2.38
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL=https://ftp.gnu.org/gnu/libc/glibc-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2
TERMUX_PKG_DEPENDS="linux-api-headers-glibc"
TERMUX_PKG_RECOMMENDS="glibc-runner"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_CONFFILES="glibc/etc/gai.conf, glibc/etc/locale.gen"

termux_step_pre_configure() {
	if [ "$TERMUX_PACKAGE_LIBRARY" != "glibc" ]; then
		termux_error_exit "Compilation is only possible based on glibc"
	fi

	for i in shmem-android.h mprotect.c; do
		install -Dm644 "${TERMUX_PKG_BUILDER_DIR}/${i}" "${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i}"
	done

	rm ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/*/clone3.S
}

termux_step_configure() {
	echo "slibdir=${TERMUX_PREFIX}/lib" > configparms
	echo "rtlddir=${TERMUX_PREFIX}/lib" >> configparms
	echo "sbindir=${TERMUX_PREFIX}/bin" >> configparms
	echo "rootsbindir=${TERMUX_PREFIX}/bin" >> configparms

	unset CFLAGS
	${TERMUX_PKG_SRCDIR}/configure \
		--prefix=$TERMUX_PREFIX \
		--libdir=${TERMUX_PREFIX}/lib \
		--libexecdir=${TERMUX_PREFIX}/lib \
		--host=$TERMUX_HOST_PLATFORM \
		--build=$TERMUX_HOST_PLATFORM \
		--target=$TERMUX_HOST_PLATFORM \
		--with-bugurl=https://github.com/termux-pacman/glibc-packages/issues \
		--enable-bind-now \
		--enable-cet \
		--disable-multi-arch \
		--enable-stack-protector=strong \
		--enable-systemtap \
		--disable-profile \
		--disable-crypt \
		--disable-werror CFLAGS="-O2 -pipe"
}

termux_step_make() {
	echo "build-programs=no" >> configparms
	make -O

	sed -i "/build-programs=/s#no#yes#" configparms
	echo "CFLAGS=-O2 -pipe" >> configparms
	make -O
	make info

	elf/ld.so --library-path "$PWD" locale/localedef -c -f ${TERMUX_PKG_SRCDIR}/localedata/charmaps/UTF-8 -i ${TERMUX_PKG_SRCDIR}/localedata/locales/C ./C.UTF-8/
}

termux_step_make_install() {
	rm -fr ${TERMUX_PREFIX}/include/gnu

	make install_root="/" install

	rm -f ${TERMUX_PREFIX}/etc/ld.so.cache
	rm -f ${TERMUX_PREFIX}/bin/{tzselect,zdump,zic}

	install -dm755 ${TERMUX_PREFIX}/lib/tmpfiles.d
	install -m644 ${TERMUX_PKG_SRCDIR}/nscd/nscd.conf ${TERMUX_PREFIX}/etc/nscd.conf
	install -m644 ${TERMUX_PKG_SRCDIR}/nscd/nscd.tmpfiles ${TERMUX_PREFIX}/lib/tmpfiles.d/nscd.conf
	install -m644 ${TERMUX_PKG_SRCDIR}/posix/gai.conf ${TERMUX_PREFIX}/etc/gai.conf
	install -m755 ${TERMUX_PKG_BUILDER_DIR}/locale-gen ${TERMUX_PREFIX}/bin
	sed -i "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g; s|@TERMUX_PREFIX_CLASSICAL@|$TERMUX_PREFIX_CLASSICAL|g" \
		${TERMUX_PREFIX}/bin/locale-gen

	install -m644 ${TERMUX_PKG_BUILDER_DIR}/locale.gen.txt ${TERMUX_PREFIX}/etc/locale.gen
	sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
		${TERMUX_PKG_SRCDIR}/localedata/SUPPORTED >> ${TERMUX_PREFIX}/etc/locale.gen

	sed -e '1,3d' -e 's|/| |g' -e 's| \\||g' \
		${TERMUX_PKG_SRCDIR}/localedata/SUPPORTED > ${TERMUX_PREFIX}/share/i18n/SUPPORTED

	install -dm755 ${TERMUX_PREFIX}/lib/locale
	cp -r ./C.UTF-8 -t ${TERMUX_PREFIX}/lib/locale
	sed -i '/#C\.UTF-8 /d' ${TERMUX_PREFIX}/etc/locale.gen

	install -Dm644 ${TERMUX_PKG_BUILDER_DIR}/sdt.h ${TERMUX_PREFIX}/include/sys/sdt.h
	install -Dm644 ${TERMUX_PKG_BUILDER_DIR}/sdt-config.h ${TERMUX_PREFIX}/include/sys/sdt-config.h

	ln -sf $PATH_DYNAMIC_LINKER $TERMUX_PREFIX/bin/ld.so
	ln -sf $PATH_DYNAMIC_LINKER $TERMUX_PREFIX/lib/ld.so
}
