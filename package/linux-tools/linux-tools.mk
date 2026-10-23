################################################################################
#
# linux-tools
#
################################################################################

# Vampirising sources from the kernel tree, so no source nor site specified.
# Instead, we directly build in the sources of the linux package. We can do
# that, because we're not building in the same location and the same files.
#
# So, all tools refer to $(LINUX_TOOLS_KDIR) to build, instead of $(@D).
#
# Which tools can be built, though, is checked against the kernel sources
# in $(LINUX_SRCDIR), which is not $(LINUX_DIR), the kernel build directory,
# when the kernel is built out of tree.
#
# The tools build in-tree, and we do not want to pollute the kernel sources
# of an out-of-tree build. So in that case, we build in a shadow of the
# kernel sources, which is a tree of real directories with symlinks to the
# files.
LINUX_TOOLS_KSRC = $(LINUX_SRCDIR)/tools
LINUX_TOOLS_KDIR = $(if $(LINUX_OUT_OF_TREE),$(LINUX_TOOLS_BUILDDIR)/linux,$(LINUX_DIR))

define LINUX_TOOLS_SHADOW_SOURCES
	$(if $(LINUX_OUT_OF_TREE),\
		support/scripts/symlink-tree -f tools $(LINUX_SRCDIR) $(LINUX_TOOLS_KDIR))
endef
# Must come first, before the hooks that tweak the kernel sources
LINUX_TOOLS_PRE_CONFIGURE_HOOKS += LINUX_TOOLS_SHADOW_SOURCES

# Note: we need individual tools makefiles to be included *before* we build
# the list of build and install hooks below to guarantee that each tool has
# a chance to register itself once, and only once. Therefore, the makefiles
# are named linux-tool-*.mk.in, so they won't be picked up by the top-level
# Makefile, but can be included here, guaranteeing the single inclusion and
# the proper ordering.

include $(sort $(wildcard package/linux-tools/*.mk.in))

# Prevent the kernel from being compiled in parallel with linux-tools. The
# kernel and some linux-tools (such as perf) use fixdep to manage kconfig
# dependencies. There is a race condition where the kernel and linux-tools try
# to build fixdep while the other tries to use fixdep, resulting in the use of
# fixdep failing.
LINUX_TOOLS_DEPENDENCIES = linux

# Install Linux kernel tools in the staging directory since some tools
# may install shared libraries and headers (e.g. cpupower).
LINUX_TOOLS_INSTALL_STAGING = YES

LINUX_TOOLS_DEPENDENCIES += $(foreach tool,$(LINUX_TOOLS),\
	$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
		$($(call UPPERCASE,$(tool))_DEPENDENCIES)))

LINUX_TOOLS_POST_BUILD_HOOKS += $(foreach tool,$(LINUX_TOOLS),\
	$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
		$(call UPPERCASE,$(tool))_BUILD_CMDS))

LINUX_TOOLS_POST_INSTALL_STAGING_HOOKS += $(foreach tool,$(LINUX_TOOLS),\
	$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
		$(call UPPERCASE,$(tool))_INSTALL_STAGING_CMDS))

LINUX_TOOLS_POST_INSTALL_TARGET_HOOKS += $(foreach tool,$(LINUX_TOOLS),\
	$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
		$(call UPPERCASE,$(tool))_INSTALL_TARGET_CMDS))

define LINUX_TOOLS_LINUX_CONFIG_FIXUPS
	$(foreach tool,$(LINUX_TOOLS),\
		$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
			$($(call UPPERCASE,$(tool))_LINUX_CONFIG_FIXUPS))
	)
endef

define LINUX_TOOLS_INSTALL_INIT_SYSTEMD
	$(foreach tool,$(LINUX_TOOLS),\
		$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
			$($(call UPPERCASE,$(tool))_INSTALL_INIT_SYSTEMD))
	)
endef

define LINUX_TOOLS_INSTALL_INIT_SYSV
	$(foreach tool,$(LINUX_TOOLS),\
		$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
			$($(call UPPERCASE,$(tool))_INSTALL_INIT_SYSV))
	)
endef

define LINUX_TOOLS_INSTALL_INIT_OPENRC
	$(foreach tool,$(LINUX_TOOLS),\
		$(if $(BR2_PACKAGE_LINUX_TOOLS_$(call UPPERCASE,$(tool))),\
			$(or $($(call UPPERCASE,$(tool))_INSTALL_INIT_OPENRC),\
			     $($(call UPPERCASE,$(tool))_INSTALL_INIT_SYSV)))
	)
endef

$(eval $(generic-package))
