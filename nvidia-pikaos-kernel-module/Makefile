DRIVER=$(shell cat ${./DRIVER})
KERNEL=$(shell cat ${./KERNEL})
VERSION=$(shell cat ${./VERSION})
CARCH=x86_64

.PHONY: install
all:
	true

install:
		fakeroot dkms build --dkmstree "$(shell ./get_pwd.sh)" -m nvidia/"${DRIVER}" -k "${KERNEL}"
		install -Dt "$(DESTDIR)/usr/lib/modules/"${KERNEL}"/extramodules" -m644 nvidia/"${DRIVER}"/"${KERNEL}"/"${CARCH}"/module/*
		find "$(DESTDIR)" -name '*.ko' -exec xz -T1 {} +