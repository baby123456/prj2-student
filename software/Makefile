
ifneq (${DTC_LOC}, )
TEMP_PATH := $(COMPILER_PATH):$(DTC_LOC)
else
TEMP_PATH := $(COMPILER_PATH)
endif

EXPORT_CC_PATH := export PATH=$(TEMP_PATH):$$PATH
SW_LOC := $(shell pwd)

# BL31: ARM Trusted Firmware (ATF)
ATF_LOC := $(SW_LOC)/atf
include scripts/atf.mk
ATF_CROSS_COMPILE_FLAGS += BUILD_BASE=$(ATF_LOC)

ifneq (${TOS}, none)
ATF_CROSS_COMPILE_FLAGS += SPD=$(TOS)d
endif

ATF_BIN_GEN := $(ATF_LOC)/$(ATF_PLAT)/release/bl31/bl31.elf
ATF_BIN := $(ATF_LOC)/bl31.elf

# BL32: Trusted OS (TOS)

# Using OP-TEE TOS 
OPTEE_OS_LOC := $(SW_LOC)/optee_os
include scripts/tos/optee.mk
OPTEE_OS_CROSS_COMPILE_FLAGS += O=$(OPTEE_OS_LOC)

OPTEE_OS_BIN := $(OPTEE_OS_LOC)/core/tee.elf

ifneq (${TOS}, none)
TOS_LOC := $(SW_LOC)/$(TOS)_os
TOS_BIN := $(TOS_LOC)/bl32.elf
else
TOS_LOC := 
TOS_BIN :=
endif

# BL33: U-Boot
UBOOT_LOC := $(SW_LOC)/uboot
include scripts/uboot.mk
UBOOT_CROSS_COMPILE_FLAGS += KBUILD_OUTPUT=$(UBOOT_LOC)

UBOOT_CONFIGED := $(UBOOT_LOC)/.config

UBOOT_BIN := $(UBOOT_LOC)/u-boot.elf

# BL33: Linux kernel image
KERN_NAME ?= phys_os
KERN_LOC := $(SW_LOC)/kernel
include scripts/kernel/$(KERN_NAME).mk
KERN_CROSS_COMPILE_FLAGS += O=$(KERN_LOC)_$(KERN_NAME)

KERN_CONFIGED := $(KERN_LOC)_$(KERN_NAME)/.config

KERN_IMAGE_GEN := $(KERN_LOC)_$(KERN_NAME)/arch/$(KERN_PLAT)/boot/Image
KERN_DTB_GEN := $(KERN_LOC)_$(KERN_NAME)/arch/$(KERN_PLAT)/boot/dts/xilinx/$(KERN_DT).dtb

ifneq (${INSTALL_LOC}, )
KERN_INSTALL_LOC := $(INSTALL_LOC)/kernel_$(KERN_NAME)
endif
KERN_INSTALL_LOC ?= $(KERN_LOC)_$(KERN_NAME)

KERN_IMAGE := $(KERN_INSTALL_LOC)/Image
KERN_DTB := $(KERN_INSTALL_LOC)/system.dtb

# User-level applications (with source files in this project repositary)
APP_ALL := $(patsubst $(SW_LOC)/app_srcs/%,%,$(wildcard $(SW_LOC)/app_srcs/*))

APP_ALL_MK := $(patsubst %,scripts/apps/%.mk,$(APP_ALL))
include $(APP_ALL_MK)

# Set output directory as a command line parameter for each application 
define set_output_dir
$(2) += O=$(SW_LOC)/apps/$(1)
endef
$(foreach obj, $(APP_ALL), \
	$(eval $(call set_output_dir,$(obj),\
	$(shell echo $(obj) | tr a-z A-Z)_COMPILE_FLAGS)))

# NOTE: You can also append names to $(APP_ALL) and 
# set specific .mk and output directory for other user-level 
# application frameworks located in code bases 
# outside this project

APP ?= none

.PHONY: FORCE

#==========================================
# ARM Trusted Firmware compilation 
#==========================================
atf: $(ATF_BIN)
	@echo "Compiled ARM Trusted Firmware"

$(ATF_BIN): FORCE
	@cd $(ATF_REPO_PATH) && git checkout $(ATF_VERSION)
	$(EXPORT_CC_PATH) && $(MAKE) -C $(ATF_REPO_PATH) $(ATF_CROSS_COMPILE_FLAGS) $(ATF_TARGET)
	@cp $(ATF_BIN_GEN) $(ATF_BIN)

atf_clean:
	$(MAKE) -C $(ATF_REPO_PATH) $(ATF_CROSS_COMPILE_FLAGS) clean
	@rm -f $(ATF_BIN)

atf_distclean: atf_clean
	@rm -rf $(ATF_LOC)

#==========================================
# OP-TEE Trusted OS compilation
#==========================================
optee: $(OPTEE_OS_BIN)
	@echo "Compiled OP-TEE Trusted OS"

$(OPTEE_OS_BIN): FORCE
	@cd $(OPTEE_OS_REPO_PATH) && git checkout $(OPTEE_OS_VERSION)
	$(EXPORT_CC_PATH) && $(MAKE) -C $(OPTEE_OS_REPO_PATH) $(OPTEE_OS_CROSS_COMPILE_FLAGS) $(OPTEE_OS_TARGET)
	@cp $(OPTEE_OS_BIN) $(TOS_BIN)

optee_clean:
	$(MAKE) -C $(OPTEE_OS_REPO_PATH) $(OPTEE_OS_CROSS_COMPILE_FLAGS) clean
	@rm -f $(TOS_BIN)

optee_distclean: optee_clean
	@rm -rf $(OPTEE_OS_LOC)

#==========================================
# U-Boot compilation
#==========================================
uboot: $(UBOOT_BIN)
	@echo "Compiled u-boot"

$(UBOOT_BIN): $(UBOOT_CONFIGED) FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C $(UBOOT_REPO_PATH) $(UBOOT_CROSS_COMPILE_FLAGS) $(UBOOT_TARGET) -j 10

$(UBOOT_CONFIGED): $(UBOOT_CONFIG_FILE)
	@cd $(UBOOT_REPO_PATH) && git checkout $(UBOOT_VERSION)
	$(EXPORT_CC_PATH) && $(MAKE) -C $(UBOOT_REPO_PATH) $(UBOOT_CROSS_COMPILE_FLAGS) $(UBOOT_CONFIG)

uboot_clean:
	$(EXPORT_CC_PATH) && $(MAKE) -C $(UBOOT_REPO_PATH) $(UBOOT_CROSS_COMPILE_FLAGS) clean

uboot_distclean:
	$(EXPORT_CC_PATH) && $(MAKE) -C $(UBOOT_REPO_PATH) $(UBOOT_CROSS_COMPILE_FLAGS) distclean
	@rm -rf $(UBOOT_LOC)

#==========================================
# Linux kernel compilation
#==========================================
kernel_image: $(KERN_IMAGE)
	@echo "Compiled Linux kernel image for $(KERN_NAME)"

kernel_config: FORCE
	@cd $(KERN_REPO_PATH) && git checkout $(KERN_VERSION)
	$(EXPORT_CC_PATH) && $(MAKE) -C $(KERN_REPO_PATH) $(KERN_CROSS_COMPILE_FLAGS) $(KERN_CONFIG) menuconfig 

$(KERN_IMAGE): $(KERN_CONFIGED) FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C $(KERN_REPO_PATH) $(KERN_CROSS_COMPILE_FLAGS) $(KERN_TARGET) -j 10
	@mkdir -p $(KERN_INSTALL_LOC)
	@cp $(KERN_IMAGE_GEN) $(KERN_IMAGE)
	@cp $(KERN_DTB_GEN) $(KERN_DTB)

$(KERN_CONFIGED): $(KERN_CONFIG_FILE)
	@cd $(KERN_REPO_PATH) && git checkout $(KERN_VERSION)
	$(EXPORT_CC_PATH) && $(MAKE) -C $(KERN_REPO_PATH) $(KERN_CROSS_COMPILE_FLAGS) $(KERN_CONFIG) menuconfig 

kernel_clean:
	$(EXPORT_CC_PATH) && $(MAKE) -C $(KERN_REPO_PATH) $(KERN_CROSS_COMPILE_FLAGS) clean
	@rm -f $(KERN_IMAGE_GEN) $(KERN_DTB_GEN)

kernel_distclean:
	$(EXPORT_CC_PATH) && $(MAKE) -C $(KERN_REPO_PATH) $(KERN_CROSS_COMPILE_FLAGS) distclean
	@rm -rf $(KERN_LOC)_$(KERN_NAME) $(KERN_INSTALL_LOC)

#==========================================
# Applications compilation
#==========================================
ifeq (${APP},all)
apps: $(APP_ALL)
else
apps: $(APP)
endif
	@echo "Finished compilation of all user-level applications"

ifeq (${APP},all)
apps_clean: $(patsubst %,%_clean,$(APP_ALL))
else
apps_clean: $(patsubst %,%_clean,$(APP))
endif
	@echo ""

ifeq (${APP},all)
apps_distclean: $(patsubst %,%_distclean,$(APP_ALL))
else
apps_distclean: $(patsubst %,%_distclean,$(APP))
endif
	@rm -rf $(SW_LOC)/apps
	@echo ""

mips_elf_loader: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$@ $(MIPS_ELF_LOADER_COMPILE_FLAGS) $(MIPS_ELF_LOADER_TARGET)

mips_elf_loader_clean: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$(patsubst %_clean,%,$@) $(MIPS_ELF_LOADER_COMPILE_FLAGS) clean 

mips_elf_loader_distclean: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$(patsubst %_distclean,%,$@) $(MIPS_ELF_LOADER_COMPILE_FLAGS) distclean 

xvc_server: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$@ $(XVC_SERVER_COMPILE_FLAGS) $(XVC_SERVER_TARGET)

xvc_server_clean: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$(patsubst %_clean,%,$@) $(XVC_SERVER_COMPILE_FLAGS) clean 

xvc_server_distclean: FORCE
	$(EXPORT_CC_PATH) && $(MAKE) -C ./app_srcs/$(patsubst %_distclean,%,$@) $(XVC_SERVER_COMPILE_FLAGS) distclean 

