# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="2"

inherit eutils toolchain-funcs

DESCRIPTION="Another Password Generator"
HOMEPAGE="http://www.adel.nursat.kz/apg/"
SRC_URI="http://www.adel.nursat.kz/apg/download/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x64-macos"
IUSE="cracklib"

DEPEND="cracklib? ( sys-libs/cracklib )"
RDEPEND="${DEPEND}"

src_prepare() {
	chmod -R 0700 "${S}"
	if use cracklib; then
		# sed literally later in src_prepare()
		# instead of
		#   epatch "${FILESDIR}"/${P}-cracklib.patch
		# because it causes a runtime error.
		# See the commit log 8c413e8 in detail.
		epatch "${FILESDIR}"/${PN}-glibc-2.4.patch
	fi
	epatch "${FILESDIR}"/${P}-crypt_password.patch

	sed -i 's,^#\(APG_CS_CLIBS += -lnsl\)$,\1,' Makefile \
		|| die "Sed failed"
	if [[ ${CHOST} == *-darwin* ]]; then
		sed -i 's,^APG_CLIBS += -lcrypt,APG_CLIBS += ,' Makefile \
		|| die "Sed failed"
	fi

	# comment out some lines in Makefile
	sed -i \
		'{
			s/^#CRACKLIB_DICTPATH/CRACKLIB_DICTPATH/
			s/^#STANDALONE_OPTIONS/STANDALONE_OPTIONS/
			s/^#CLISERV_OPTIONS/CLISERV_OPTIONS/
			s/^#APG_CLIBS/APG_CLIBS/
		}
		' \
		${WORKDIR}/${P}/Makefile || die "Sed failed"

	# refer the path of Gentoo Prefix in Makefile not /usr/local
	previous_cracklib_dictpath='/usr/local/lib/pw_dict'
	following_cracklib_dictpath="${EPREFIX}"'/usr/lib/pw_dict'
	sed -i \
		"s,$previous_cracklib_dictpath,$following_cracklib_dictpath," \
		${WORKDIR}/${P}/Makefile || die "Sed failed"

	# tune the clacklib_dictpath flag in Makefile
	cracklib_dictpath_option='-DCRACKLIB_DICTPATH=${CRACKLIB_DICTPATH}'
	sed -i \
		"s,$cracklib_dictpath_option'.*,$cracklib_dictpath_option'," \
		${WORKDIR}/${P}/Makefile || die "Sed failed"
}

src_compile() {
	emake \
		FLAGS="${CFLAGS} ${LDFLAGS}" CFLAGS="${CFLAGS} ${LDFLAGS}" \
		CC="$(tc-getCC)" \
		standalone || die "compile problem"
	emake FLAGS="${CFLAGS} ${LDFLAGS}" CC="$(tc-getCC)" \
		-C bfconvert || die "compile problem"
}

src_install() {
	dobin apg apgbfm bfconvert/bfconvert || die
	dodoc CHANGES INSTALL README THANKS TODO || die
	cd doc
	doman man/apg.1 man/apgbfm.1 || die
	dodoc APG_TIPS pronun.txt rfc0972.txt rfc1750.txt || die
}
