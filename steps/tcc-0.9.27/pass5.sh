# SPDX-FileCopyrightText: 2021-2022 Andrius Štikonas <andrius@stikonas.eu>
# SPDX-FileCopyrightText: 2021-23 Samuel Tyler <samuel@samuelt.me>
#
# SPDX-License-Identifier: GPL-3.0-or-later

src_prepare() {
    default

    touch config.h
}

src_compile() {
    if match ${ARCH} aarch64; then
        TCC_TARGET_ARCH=ARM64
        LIB_ARM64=true
    fi
    if match ${ARCH} amd64; then
        TCC_TARGET_ARCH=X86_64
        LIB_ARM64=false
    fi
    if match ${ARCH} riscv32; then
        TCC_TARGET_ARCH=RISCV32
        LIB_ARM64=false
    fi
    if match ${ARCH} riscv64; then
        TCC_TARGET_ARCH=RISCV64
        LIB_ARM64=true
    fi
    if match ${ARCH} x86; then
        TCC_TARGET_ARCH=I386
        LIB_ARM64=false
    fi

    tcc-musl \
        -v \
        -static \
        -o tcc-musl \
        -D TCC_TARGET_${TCC_TARGET_ARCH}=1 \
        -D CONFIG_TCCDIR=\""${LIBDIR}/tcc"\" \
        -D CONFIG_TCC_CRTPREFIX=\""${LIBDIR}"\" \
        -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
        -D CONFIG_TCC_LIBPATHS=\""${LIBDIR}:${LIBDIR}/tcc"\" \
        -D CONFIG_TCC_SYSINCLUDEPATHS=\""${PREFIX}/include"\" \
        -D TCC_LIBGCC=\""${LIBDIR}/libc.a"\" \
        -D CONFIG_TCC_STATIC=1 \
        -D CONFIG_USE_LIBGCC=1 \
        -D TCC_VERSION=\"0.9.27\" \
        -D ONE_SOURCE=1 \
        -I "${PREFIX}/include" \
        tcc.c

    # libtcc1.a
    tcc-musl -c -D HAVE_CONFIG_H=1 lib/libtcc1.c
    if match ${LIB_ARM64} true; then
        tcc-musl -c -D HAVE_CONFIG_H=1 lib/lib-arm64.c
        ar cr libtcc1.a libtcc1.o lib-arm64.o
    else
        ar cr libtcc1.a libtcc1.o
    fi
}

src_install() {
    install -D tcc-musl "${DESTDIR}${PREFIX}/bin/tcc-musl"
    install -D -m 644 libtcc1.a "${DESTDIR}${LIBDIR}/libtcc1.a"
}
