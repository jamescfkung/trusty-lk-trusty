$(info Include Trusty user tasks support)

#
# Input variables
#
#   TRUSTY_PREBUILT_USER_TASKS - list of precompiled user tasks to be included into final image
#   TRUSTY_ALL_USER_TASKS      - list of compiled from source user tasks to be included into final image
#

# generate user task build rule: $(1): user task
define user-task-build-rule
$(eval XBIN_NAME := $(notdir $(1)))\
$(eval XBIN_TOP_MODULE := $(1))\
$(eval XBIN_TYPE := USER_TASK)\
$(eval XBIN_ARCH := $(TRUSTY_USER_ARCH))\
$(eval XBIN_BUILDDIR := $(BUILDDIR)/user_tasks/$(1))\
$(eval XBIN_LINKER_SCRIPT := $(XBIN_BUILDDIR)/user_task.ld)\
$(eval XBIN_LDFLAGS := )\
$(eval include make/xbin.mk)
endef

# generate list of all user tasks we need to build

# sort and remove duplicates
TRUSTY_USER_TASKS := $(sort $(TRUSTY_USER_TASKS))

ALLUSER_TASK_OBJS := $(foreach t, $(TRUSTY_ALL_USER_TASKS),\
   $(addsuffix /$(notdir $(t)).elf, $(t)))

ALLUSER_TASK_OBJS := $(addprefix $(BUILDDIR)/user_tasks/,$(ALLUSER_TASK_OBJS))

# Add prebuilt user tasks
ALLUSER_TASK_OBJS += $(TRUSTY_PREBUILT_USER_TASKS)

#
# Generate build rules for each user task
#
$(foreach t,$(TRUSTY_ALL_USER_TASKS),\
   $(call user-task-build-rule,$(t)))

#
# Generate combined user task obj/bin if necessary
#
ifneq ($(strip $(ALLUSER_TASK_OBJS)),)

USER_TASKS_BIN := $(BUILDDIR)/user_tasks.bin
USER_TASKS_OBJ := $(BUILDDIR)/user_tasks.o

GENERATED += $(USER_TASKS_OBJ) $(USER_TASKS_BIN)

# Create a task.o from the concatenation of tasks to be made available.
# To control placement in the final LK image, the tasks .data section is
# renamed to .task.data, so it's picked up in a page-aligned part of the
# data section by the linker script (allowing tasks to run, in-place).

$(USER_TASKS_BIN): $(ALLUSER_TASK_OBJS)
	@$(MKDIR)
	@echo combining tasks into $@: $(ALLUSER_TASK_OBJS)
	$(NOECHO)cat $(ALLUSER_TASK_OBJS) > $@

$(USER_TASKS_OBJ): $(USER_TASKS_BIN)
	@$(MKDIR)
	@echo generating $@
	$(NOECHO)$(LD) -r -b binary -o $@ $<
	$(NOECHO)$(OBJCOPY) --prefix-sections=.task $@

# Append USER_TASKS_OBJ to EXTRA_OBJ
EXTRA_OBJS += $(USER_TASKS_OBJ)

endif

