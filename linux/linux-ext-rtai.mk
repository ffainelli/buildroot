################################################################################
#
# Patch the linux kernel with RTAI extension
#
################################################################################

LINUX_EXTENSIONS += rtai

ifeq ($(KERNEL_ARCH),i386)
RTAI_ARCH = x86
else ifeq ($(KERNEL_ARCH),x86_64)
RTAI_ARCH = x86
else ifeq ($(KERNEL_ARCH),powerpc)
RTAI_ARCH = ppc
else
RTAI_ARCH = $(KERNEL_ARCH)
endif

# Prepare kernel patch
define RTAI_PREPARE_KERNEL
	kver=`$(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) --no-print-directory -s kernelversion` ; \
	if test -f $(RTAI_SRCDIR)/base/arch/$(RTAI_ARCH)/patches/hal-linux-$${kver}-*patch ; then \
		$(APPLY_PATCHES) $(@D) \
			$(RTAI_SRCDIR)/base/arch/$(RTAI_ARCH)/patches/ \
			hal-linux-$${kver}-*patch ; \
	else \
		echo "No RTAI patch for your kernel version" ; \
		exit 1 ; \
	fi
endef
