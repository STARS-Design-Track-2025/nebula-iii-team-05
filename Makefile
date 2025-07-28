# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
MAKEFLAGS+=--warn-undefined-variables

# Do the following when working in "eceprog" or in a Purdue ECE Lab
ifeq ($(shell bash -c '[ -n "$$HOSTNAME" ] && [[ "$$HOSTNAME" == ecelnx* || "$$HOSTNAME" == eceprog* ]] && echo yes'),yes)
# To have access to ECE 270 tool binaries
export PATH := /home/shay/a/ece270/bin:$(PATH)
export LD_LIBRARY_PATH := /home/shay/a/ece270/lib:$(LD_LIBRARY_PATH)
endif

export CARAVEL_ROOT?=$(PWD)/caravel
export UPRJ_ROOT?=$(PWD)
PRECHECK_ROOT?=${HOME}/mpw_precheck
export MCW_ROOT?=$(PWD)/mgmt_core_wrapper
SIM?=RTL

# Install lite version of caravel, (1): caravel-lite, (0): caravel
CARAVEL_LITE?=1

# PDK switch varient
export PDK?=sky130A
#export PDK?=gf180mcuC
export PDKPATH?=$(PDK_ROOT)/$(PDK)

PYTHON_BIN ?= python3

ROOTLESS ?= 0
USER_ARGS = -u $$(id -u $$USER):$$(id -g $$USER)
ifeq ($(ROOTLESS), 1)
	USER_ARGS =
endif

# export OPENLANE_ROOT?=$(PWD)/dependencies/openlane_src  # We are not using OpenLane1

# export OPENLANE2_ROOT?=${HOME}/STARS2024/openlane2-2.0.7  # for nanoHUB
export OPENLANE2_ROOT?=~/openlane2# Working somewhere else
export BUS_WRAP_ROOT?=$(PWD)/dependencies/BusWrap
export PDK_ROOT?=$(PWD)/dependencies/pdks
# export PDK_ROOT?=/apps/share64/rocky8/openlane2/openlane2-stars2024-20240613/PDKS   # for nanoHUB
export DISABLE_LVS?=0

export ROOTLESS

# Before Tapeout, we may want to consider using the following:
# export OPEN_PDKS_COMMIT?=78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc

ifeq ($(PDK),sky130A)
	SKYWATER_COMMIT=f70d8ca46961ff92719d8870a18a076370b85f6c
	export OPEN_PDKS_COMMIT_LVS?=6d4d11780c40b20ee63cc98e645307a9bf2b2ab8
	export OPEN_PDKS_COMMIT?=0fe599b2afb6708d281543108caf8310912f54af
	export OPENLANE_TAG?=2023.07.19-1
	MPW_TAG ?= CC2509-test

ifeq ($(CARAVEL_LITE),1)
	CARAVEL_NAME := caravel-lite
	CARAVEL_REPO := https://github.com/chipfoundry/caravel-lite
	CARAVEL_TAG := $(MPW_TAG)
else
	CARAVEL_NAME := caravel
	CARAVEL_REPO := https://github.com/chipfoundry/caravel
	CARAVEL_TAG := $(MPW_TAG)
endif

endif

ifeq ($(PDK),sky130B)
	SKYWATER_COMMIT=f70d8ca46961ff92719d8870a18a076370b85f6c
	export OPEN_PDKS_COMMIT_LVS?=6d4d11780c40b20ee63cc98e645307a9bf2b2ab8
	export OPEN_PDKS_COMMIT?=78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc
	export OPENLANE_TAG?=2023.07.19-1
	MPW_TAG ?= 2024.09.12-1

ifeq ($(CARAVEL_LITE),1)
	CARAVEL_NAME := caravel-lite
	CARAVEL_REPO := https://github.com/chipfoundry/caravel-lite
	CARAVEL_TAG := $(MPW_TAG)
else
	CARAVEL_NAME := caravel
	CARAVEL_REPO := https://github.com/chipfoundry/caravel
	CARAVEL_TAG := $(MPW_TAG)
endif

endif

ifeq ($(PDK),gf180mcuD)

	MPW_TAG ?= gfmpw-1c
	CARAVEL_NAME := caravel
	CARAVEL_REPO := https://github.com/chipfoundry/caravel-gf180mcu
	CARAVEL_TAG := $(MPW_TAG)
	#OPENLANE_TAG=ddfeab57e3e8769ea3d40dda12be0460e09bb6d9
	export OPEN_PDKS_COMMIT?=78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc
	export OPENLANE_TAG?=2023.07.19

endif

# Include Caravel Makefile Targets
.PHONY: % : check-caravel
%:
	export CARAVEL_ROOT=$(CARAVEL_ROOT) && export MPW_TAG=$(MPW_TAG) && $(MAKE) -f $(CARAVEL_ROOT)/Makefile $@

.PHONY: install
install:
	if [ -d "$(CARAVEL_ROOT)" ]; then\
		echo "Deleting exisiting $(CARAVEL_ROOT)" && \
		rm -rf $(CARAVEL_ROOT) && sleep 2;\
	fi
	echo "Installing $(CARAVEL_NAME).."
	git clone -b $(CARAVEL_TAG) $(CARAVEL_REPO) $(CARAVEL_ROOT) --depth=1

# Install DV setup
.PHONY: simenv
simenv:
	docker pull chipfoundry/dv:latest

# Install cocotb docker
.PHONY: simenv-cocotb
simenv-cocotb:
	docker pull chipfoundry/dv:cocotb

.PHONY: setup
setup: check_dependencies install check-env install_mcw openlane pdk-with-volare setup-timing-scripts setup-cocotb precheck

.PHONY: purdue-setup
purdue-setup: check_dependencies install check-env install_mcw pdk-with-volare bus-wrap-setup
	@echo "\033[0;32mSetup complete!!\n\033[0m"

# Openlane
blocks=$(shell cd openlane && find * -maxdepth 0 -type d)
.PHONY: $(blocks)
$(blocks): % :
	$(MAKE) -C openlane $*

dv_patterns=$(shell cd verilog/dv && find * -maxdepth 0 -type d)
cocotb-dv_patterns=$(shell cd verilog/dv/cocotb && find . -name "*.c"  | sed -e 's|^.*/||' -e 's/.c//')
dv-targets-rtl=$(dv_patterns:%=verify-%-rtl)
purdue-dv-targets-rtl=$(dv_patterns:%=purdue-verify-%-rtl)
cocotb-dv-targets-rtl=$(cocotb-dv_patterns:%=cocotb-verify-%-rtl)
dv-targets-gl=$(dv_patterns:%=verify-%-gl)
purdue-dv-targets-gl=$(dv_patterns:%=purdue-verify-%-gl)
cocotb-dv-targets-gl=$(cocotb-dv_patterns:%=cocotb-verify-%-gl)
dv-targets-gl-sdf=$(dv_patterns:%=verify-%-gl-sdf)
purdue-dv-targets-gl-sdf=$(dv_patterns:%=purdue-verify-%-gl-sdf)


TARGET_PATH=$(shell pwd)
verify_command="source ~/.bashrc && cd ${TARGET_PATH}/verilog/dv/$* && export SIM=${SIM} && make"
dv_base_dependencies=simenv
docker_run_verify=\
	docker run \
		$(USER_ARGS) \
		-v ${TARGET_PATH}:${TARGET_PATH} -v ${PDK_ROOT}:${PDK_ROOT} \
		-v ${CARAVEL_ROOT}:${CARAVEL_ROOT} \
		-v ${MCW_ROOT}:${MCW_ROOT} \
		-e TARGET_PATH=${TARGET_PATH} -e PDK_ROOT=${PDK_ROOT} \
		-e CARAVEL_ROOT=${CARAVEL_ROOT} \
		-e TOOLS=/foss/tools/riscv-gnu-toolchain-rv32i/217e7f3debe424d61374d31e33a091a630535937 \
		-e DESIGNS=$(TARGET_PATH) \
		-e USER_PROJECT_VERILOG=$(TARGET_PATH)/verilog \
		-e PDK=$(PDK) \
		-e CORE_VERILOG_PATH=$(TARGET_PATH)/mgmt_core_wrapper/verilog \
		-e CARAVEL_VERILOG_PATH=$(TARGET_PATH)/caravel/verilog \
		-e MCW_ROOT=$(MCW_ROOT) \
		chipfoundry/dv:latest \
		sh -c $(verify_command)

custom_run_verify =\
    export TARGET_PATH=${TARGET_PATH} &&\
    export PDK_ROOT=${PDK_ROOT} &&\
    export CARAVEL_ROOT=${CARAVEL_ROOT} &&\
    export DESIGNS=$(TARGET_PATH) &&\
    export USER_PROJECT_VERILOG=$(TARGET_PATH)/verilog &&\
    export PDK=$(PDK) &&\
    export CORE_VERILOG_PATH=$(TARGET_PATH)/mgmt_core_wrapper/verilog &&\
    export CARAVEL_VERILOG_PATH=$(TARGET_PATH)/caravel/verilog &&\
    export MCW_ROOT=$(MCW_ROOT) &&\
	export GCC_PREFIX=riscv64-unknown-elf &&\
	export GCC_PATH=/package/riscv-gnu-toolchain/bin &&\
	export USER_PROJECT_VERILOG=$(PWD)/verilog &&\
    cd verilog/dv/$* && export SIM=${SIM} && make
# If you're Aidan, use this:
# export GCC_PREFIX=riscv32-unknown-elf &&\
# export GCC_PATH=/opt/riscv32/bin &&\

# If working on asicfab (for some reason), use this:
# export GCC_PREFIX=riscv64-unknown-elf &&\
# export GCC_PATH=/package/asicfab/riscv-gcc/13.2.0/bin &&\

.PHONY: harden
harden: $(blocks)

.PHONY: verify
verify: $(dv-targets-rtl)

.PHONY: verify-all-rtl
verify-all-rtl: $(dv-targets-rtl)

.PHONY: verify-all-gl
verify-all-gl: $(dv-targets-gl)

.PHONY: verify-all-gl-sdf
verify-all-gl-sdf: $(dv-targets-gl-sdf)

$(dv-targets-rtl): SIM=RTL
$(dv-targets-rtl): verify-%-rtl: $(dv_base_dependencies)
	$(docker_run_verify)

$(purdue-dv-targets-rtl): SIM=RTL
$(purdue-dv-targets-rtl): purdue-verify-%-rtl: zicsr-fix nebula
	@$(custom_run_verify) || ( echo "Please check to ensure march=rv32i_zicsr not march=rv32i: mgmt_core_wrapper/verilog/dv/make/var.makefile"; exit 1 )

$(dv-targets-gl): SIM=GL
$(dv-targets-gl): verify-%-gl: $(dv_base_dependencies)
	$(docker_run_verify)

$(purdue-dv-targets-gl): SIM=GL
$(purdue-dv-targets-gl): purdue-verify-%-gl: zicsr-fix nebula
	$(custom_run_verify)

$(dv-targets-gl-sdf): SIM=GL_SDF
$(dv-targets-gl-sdf): verify-%-gl-sdf: $(dv_base_dependencies)
	$(docker_run_verify)

$(purdue-dv-targets-gl-sdf): SIM=GL_SDF
$(purdue-dv-targets-gl-sdf): purdue-verify-%-gl-sdf: zicsr-fix
	$(custom_run_verify)

clean-targets=$(blocks:%=clean-%)
.PHONY: $(clean-targets)
$(clean-targets): clean-% :
	rm -f ./verilog/gl/$*.v
	rm -f ./spef/$*.spef
	rm -f ./sdc/$*.sdc
	rm -f ./sdf/$*.sdf
	rm -f ./gds/$*.gds
	rm -f ./mag/$*.mag
	rm -f ./lef/$*.lef
	rm -f ./maglef/*.maglef

make_what=setup $(blocks) $(dv-targets-rtl) $(dv-targets-gl) $(dv-targets-gl-sdf) $(clean-targets)
.PHONY: what
what:
	# $(make_what)

# Install Openlane
.PHONY: openlane
openlane:
	@if [ "$$(realpath $${OPENLANE_ROOT})" = "$$(realpath $$(pwd)/openlane)" ]; then\
		echo "OPENLANE_ROOT is set to '$$(pwd)/openlane' which contains openlane config files"; \
		echo "Please set it to a different directory"; \
		exit 1; \
	fi
	cd openlane && $(MAKE) openlane

#### Not sure if the targets following are of any use

# Create symbolic links to caravel's main files
.PHONY: simlink
simlink: check-caravel
### Symbolic links relative path to $CARAVEL_ROOT
	$(eval MAKEFILE_PATH := $(shell realpath --relative-to=openlane $(CARAVEL_ROOT)/openlane/Makefile))
	$(eval PIN_CFG_PATH  := $(shell realpath --relative-to=openlane/user_project_wrapper $(CARAVEL_ROOT)/openlane/user_project_wrapper_empty/pin_order.cfg))
	mkdir -p openlane
	mkdir -p openlane/user_project_wrapper
	cd openlane &&\
	ln -sf $(MAKEFILE_PATH) Makefile
	cd openlane/user_project_wrapper &&\
	ln -sf $(PIN_CFG_PATH) pin_order.cfg

# Update Caravel
.PHONY: update_caravel
update_caravel: check-caravel
	cd $(CARAVEL_ROOT)/ && git checkout $(CARAVEL_TAG) && git pull

# Uninstall Caravel
.PHONY: uninstall
uninstall:
	rm -rf $(CARAVEL_ROOT)


# Install Pre-check
# Default installs to the user home directory, override by "export PRECHECK_ROOT=<precheck-installation-path>"
.PHONY: precheck
precheck:
	if [ -d "$(PRECHECK_ROOT)" ]; then\
		echo "Deleting exisiting $(PRECHECK_ROOT)" && \
		rm -rf $(PRECHECK_ROOT) && sleep 2;\
	fi
	@echo "Installing Precheck.."
	@git clone --depth=1 --branch $(MPW_TAG) https://github.com/chipfoundry/mpw_precheck.git $(PRECHECK_ROOT)
	@docker pull chipfoundry/mpw_precheck:latest

.PHONY: run-precheck
run-precheck: check-pdk check-precheck enable-lvs-pdk
	@if [ "$$DISABLE_LVS" = "1" ]; then\
		$(eval INPUT_DIRECTORY := $(shell pwd)) \
		cd $(PRECHECK_ROOT) && \
		docker run -it -v $(PRECHECK_ROOT):$(PRECHECK_ROOT) \
		-v $(INPUT_DIRECTORY):$(INPUT_DIRECTORY) \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(HOME)/.ipm:$(HOME)/.ipm \
		-e INPUT_DIRECTORY=$(INPUT_DIRECTORY) \
		-e PDK_PATH=$(PDK_ROOT)/$(PDK) \
		-e PDK_ROOT=$(PDK_ROOT) \
		-e PDKPATH=$(PDKPATH) \
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) \
		chipfoundry/mpw_precheck:latest bash -c "cd $(PRECHECK_ROOT) ; python3 mpw_precheck.py --input_directory $(INPUT_DIRECTORY) --pdk_path $(PDK_ROOT)/$(PDK) license makefile default documentation consistency gpio_defines xor magic_drc klayout_feol klayout_beol klayout_offgrid klayout_met_min_ca_density klayout_pin_label_purposes_overlapping_drawing klayout_zeroarea"; \
	else \
		$(eval INPUT_DIRECTORY := $(shell pwd)) \
		cd $(PRECHECK_ROOT) && \
		docker run -it -v $(PRECHECK_ROOT):$(PRECHECK_ROOT) \
		-v $(INPUT_DIRECTORY):$(INPUT_DIRECTORY) \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(HOME)/.ipm:$(HOME)/.ipm \
		-e INPUT_DIRECTORY=$(INPUT_DIRECTORY) \
		-e PDK_PATH=$(PDK_ROOT)/$(PDK) \
		-e PDK_ROOT=$(PDK_ROOT) \
		-e PDKPATH=$(PDKPATH) \
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) \
		chipfoundry/mpw_precheck:latest bash -c "cd $(PRECHECK_ROOT) ; python3 mpw_precheck.py --input_directory $(INPUT_DIRECTORY) --pdk_path $(PDK_ROOT)/$(PDK)"; \
	fi

.PHONY: enable-lvs-pdk
enable-lvs-pdk:
	$(UPRJ_ROOT)/venv/bin/volare enable $(OPEN_PDKS_COMMIT_LVS)

BLOCKS = $(shell cd lvs && find * -maxdepth 0 -type d)
LVS_BLOCKS = $(foreach block, $(BLOCKS), lvs-$(block))
$(LVS_BLOCKS): lvs-% : ./lvs/%/lvs_config.json check-pdk check-precheck
	@$(eval INPUT_DIRECTORY := $(shell pwd))
	@cd $(PRECHECK_ROOT) && \
	docker run -v $(PRECHECK_ROOT):$(PRECHECK_ROOT) \
	-v $(INPUT_DIRECTORY):$(INPUT_DIRECTORY) \
	-v $(PDK_ROOT):$(PDK_ROOT) \
	-u $(shell id -u $(USER)):$(shell id -g $(USER)) \
	chipfoundry/mpw_precheck:latest bash -c "export PYTHONPATH=$(PRECHECK_ROOT) ; cd $(PRECHECK_ROOT) ; python3 checks/lvs_check/lvs.py --pdk_path $(PDK_ROOT)/$(PDK) --design_directory $(INPUT_DIRECTORY) --output_directory $(INPUT_DIRECTORY)/lvs --design_name $* --config_file $(INPUT_DIRECTORY)/lvs/$*/lvs_config.json"

.PHONY: clean
clean:
	@find openlane/*/ -maxdepth 1 -type d -name runs -exec rm -rf {} + && \
	find verilog/rtl/team_projects/*/ -maxdepth 1 -type d -name build -exec rm -rf {} + && \
	cd ./verilog/dv/ && \
		$(MAKE) -j$(THREADS) clean

check-caravel:
	@if [ ! -d "$(CARAVEL_ROOT)" ]; then \
		echo "Caravel Root: "$(CARAVEL_ROOT)" doesn't exists, please export the correct path before running make. "; \
		exit 1; \
	fi

check-precheck:
	@if [ ! -d "$(PRECHECK_ROOT)" ]; then \
		echo "Pre-check Root: "$(PRECHECK_ROOT)" doesn't exists, please export the correct path before running make. "; \
		exit 1; \
	fi

check-pdk:
	@if [ ! -d "$(PDK_ROOT)" ]; then \
		echo "PDK Root: "$(PDK_ROOT)" doesn't exists, please export the correct path before running make. "; \
		exit 1; \
	fi

.PHONY: help
help:
	cd $(CARAVEL_ROOT) && $(MAKE) help
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: check_dependencies
check_dependencies:
	@if [ ! -d "$(PWD)/dependencies" ]; then \
		mkdir $(PWD)/dependencies; \
	fi


export CUP_ROOT=$(shell pwd)
export TIMING_ROOT?=$(shell pwd)/dependencies/timing-scripts
export PROJECT_ROOT=$(CUP_ROOT)
timing-scripts-repo=https://github.com/chipfoundry/timing-scripts.git

$(TIMING_ROOT):
	@mkdir -p $(CUP_ROOT)/dependencies
	@git clone $(timing-scripts-repo) $(TIMING_ROOT)

.PHONY: setup-timing-scripts
setup-timing-scripts: $(TIMING_ROOT)
	@( cd $(TIMING_ROOT) && git pull )
	@#( cd $(TIMING_ROOT) && git fetch && git checkout $(MPW_TAG); )

.PHONY: install-caravel-cocotb
install-caravel-cocotb:
	rm -rf ./venv-cocotb
	$(PYTHON_BIN) -m venv ./venv-cocotb
	./venv-cocotb/bin/$(PYTHON_BIN) -m pip install --upgrade --no-cache-dir pip
	./venv-cocotb/bin/$(PYTHON_BIN) -m pip install --upgrade --no-cache-dir caravel-cocotb

.PHONY: setup-cocotb-env
setup-cocotb-env:
	@(python3 $(PROJECT_ROOT)/verilog/dv/setup-cocotb.py $(CARAVEL_ROOT) $(MCW_ROOT) $(PDK_ROOT) $(PDK) $(PROJECT_ROOT))

.PHONY: setup-cocotb
setup-cocotb: install-caravel-cocotb setup-cocotb-env simenv-cocotb

.PHONY: cocotb-verify-all-rtl
cocotb-verify-all-rtl: 
	@(cd $(PROJECT_ROOT)/verilog/dv/cocotb && $(PROJECT_ROOT)/venv-cocotb/bin/caravel_cocotb -tl user_proj_tests/user_proj_tests.yaml )
	
.PHONY: cocotb-verify-all-gl
cocotb-verify-all-gl:
	@(cd $(PROJECT_ROOT)/verilog/dv/cocotb && $(PROJECT_ROOT)/venv-cocotb/bin/caravel_cocotb -tl user_proj_tests/user_proj_tests_gl.yaml -sim GL)

$(cocotb-dv-targets-rtl): cocotb-verify-%-rtl: 
	@(cd $(PROJECT_ROOT)/verilog/dv/cocotb && $(PROJECT_ROOT)/venv-cocotb/bin/caravel_cocotb -t $*  )
	
$(cocotb-dv-targets-gl): cocotb-verify-%-gl:
	@(cd $(PROJECT_ROOT)/verilog/dv/cocotb && $(PROJECT_ROOT)/venv-cocotb/bin/caravel_cocotb -t $* -sim GL)

./verilog/gl/user_project_wrapper.v:
	$(error you don't have $@)

./env/spef-mapping.tcl: 
	@echo "run the following:"
	@echo "make extract-parasitics"
	@echo "make create-spef-mapping"
	exit 1

.PHONY: create-spef-mapping
create-spef-mapping: ./verilog/gl/user_project_wrapper.v
	docker run \
		--rm \
		$(USER_ARGS) \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(CUP_ROOT):$(CUP_ROOT) \
		-v $(CARAVEL_ROOT):$(CARAVEL_ROOT) \
		-v $(MCW_ROOT):$(MCW_ROOT) \
		-v $(TIMING_ROOT):$(TIMING_ROOT) \
		-w $(shell pwd) \
		chipfoundry/timing-scripts:latest \
		python3 $(TIMING_ROOT)/scripts/generate_spef_mapping.py \
			-i ./verilog/gl/user_project_wrapper.v \
			-o ./env/spef-mapping.tcl \
			--pdk-path $(PDK_ROOT)/$(PDK) \
			--macro-parent chip_core/mprj \
			--project-root "$(CUP_ROOT)"


.PHONY: extract-parasitics
extract-parasitics: ./verilog/gl/user_project_wrapper.v
	docker run \
		--rm \
		$(USER_ARGS) \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(CUP_ROOT):$(CUP_ROOT) \
		-v $(CARAVEL_ROOT):$(CARAVEL_ROOT) \
		-v $(MCW_ROOT):$(MCW_ROOT) \
		-v $(TIMING_ROOT):$(TIMING_ROOT) \
		-w $(shell pwd) \
		chipfoundry/timing-scripts:latest \
		python3 $(TIMING_ROOT)/scripts/get_macros.py \
			-i ./verilog/gl/user_project_wrapper.v \
			-o ./tmp-macros-list \
			--project-root "$(CUP_ROOT)" \
			--pdk-path $(PDK_ROOT)/$(PDK)
	@cat ./tmp-macros-list | cut -d " " -f2 \
		| xargs -I % bash -c "$(MAKE) -C $(TIMING_ROOT) \
			-f $(TIMING_ROOT)/timing.mk rcx-% || echo 'Cannot extract %. Probably no def for this macro'"
	@$(MAKE) -C $(TIMING_ROOT) -f $(TIMING_ROOT)/timing.mk rcx-user_project_wrapper
	@cat ./tmp-macros-list
	@rm ./tmp-macros-list
	
.PHONY: caravel-sta
caravel-sta: ./env/spef-mapping.tcl
	@$(MAKE) -C $(TIMING_ROOT) -f $(TIMING_ROOT)/timing.mk caravel-timing-typ -j3
	@$(MAKE) -C $(TIMING_ROOT) -f $(TIMING_ROOT)/timing.mk caravel-timing-fast -j3
	@$(MAKE) -C $(TIMING_ROOT) -f $(TIMING_ROOT)/timing.mk caravel-timing-slow -j3
	@echo =============================================Summary=============================================
	@find $(PROJECT_ROOT)/signoff/caravel/openlane-signoff/timing/*/ -name "summary.log" | head -n1 \
		| xargs head -n5 | tail -n1
	@find $(PROJECT_ROOT)/signoff/caravel/openlane-signoff/timing/*/ -name "summary.log" \
		| xargs -I {} bash -c "head -n7 {} | tail -n1"
	@echo =================================================================================================
	@echo "You can find results for all corners in $(CUP_ROOT)/signoff/caravel/openlane-signoff/timing/"
	@echo "Check summary.log of a specific corner to point to reports with reg2reg violations" 
	@echo "Cap and slew violations are inside summary.log file itself"


#***************************************************************************
# Purdue-Only Targets Below
#***************************************************************************

.PHONY: zicsr-fix
zicsr-fix:
	cd $(MCW_ROOT)/verilog/dv/make &&\
	sed -i.bak 's/rv32i /rv32i_zicsr /g' var.makefile

#Clone BusWrap Repo
.PHONY: bus-wrap-setup
bus-wrap-setup: check_dependencies
	@pip install svmodule &&\
	cd $(PWD)/dependencies &&\
	if [ ! -d "BusWrap" ]; then \
		git clone https://github.com/efabless/BusWrap.git; \
		cd BusWrap; \
		git checkout e468b6b; \
	else \
		echo "\nBusWrap is already set up!\n"; \
	fi

#Generate Bus Wrap Verilog files for teams
.PHONY: bus-wrap-generate
bus-wrap-generate:
	cd $(PWD)/verilog/rtl &&\
	make generate

# Example target: tb-module-team_00-t00_flex_counter
# These testbenches must live within the dv/team_##/module_tests directory and will output there too
.PHONY: tb-module-%
tb-module-%: nebula
	@echo "\n------------"
	@echo "Team Folder: $(firstword $(subst -, ,$*))"
	@echo "Module Name: $(lastword $(subst -, ,$*))"
	@echo "------------\n"
	export USER_PROJECT_VERILOG=$(PWD)/verilog &&\
	cd $(PWD)/verilog/dv/$(firstword $(subst -, ,$*))/module_tests &&\
	make sim_$(lastword $(subst -, ,$*))_src


# Compilation and Simulation with Synopsys VCS
# The testbenches must live within the dv/team_##/module_tests directory and will output there too
# Example target: tbsim-source-team_00-t00_flex_counter
.PHONY: tbsim-source-%
tbsim-source-%: nebula
	@echo "\n------------"
	@echo "Team Folder: $(firstword $(subst -, ,$*))"
	@echo "Module Name: $(lastword $(subst -, ,$*))"
	@echo "------------\n"
	export USER_PROJECT_VERILOG=$(PWD)/verilog &&\
	cd $(PWD)/verilog/dv/$(firstword $(subst -, ,$*))/module_tests &&\
	make sim-source-$(lastword $(subst -, ,$*))


# Prototype design on iCE40 FPGA
# Example target: make cram_team_00
.PHONY: cram_%
cram_%:
	@export USER_PROJECT_VERILOG=$(UPRJ_ROOT)/verilog &&\
	export BUILD=$$USER_PROJECT_VERILOG/rtl/team_projects/$*/build &&\
	export ICE=$(UPRJ_ROOT)/fpga_support/ice40hx8k.sv &&\
	export UART=$(UPRJ_ROOT)/fpga_support/uart &&\
	export PINMAP=$(UPRJ_ROOT)/fpga_support/pinmap.pcf &&\
	export TEAM_DIR=$$USER_PROJECT_VERILOG/rtl/team_projects/$* &&\
	export SRC_DIR=$$USER_PROJECT_VERILOG/rtl/team_projects/$*/src &&\
	export SRAM_WRAPPER="$$USER_PROJECT_VERILOG/rtl/sram/sram_WB_Wrapper.sv" &&\
	export FPGA_TOP=$*_fpga_top &&\
	mkdir -p $$BUILD &&\
	sed -i 's/sram_for_FPGA/sky130_sram_8kbyte_1r1w_32x2048_8/' $$SRAM_WRAPPER &&\
	sed -i 's/sky130_sram_8kbyte_1r1w_32x2048_8/sram_for_FPGA/' $$SRAM_WRAPPER &&\
	yosys -p "read_verilog -sv -noblackbox $$ICE $$UART $$TEAM_DIR/*.sv $$SRC_DIR/*.sv \
		$$USER_PROJECT_VERILOG/rtl/wishbone_manager/wishbone_manager.sv $$SRAM_WRAPPER \
		$$USER_PROJECT_VERILOG/rtl/sram/sram_for_FPGA.v; \
		synth_ice40 -top ice40hx8k -json $$BUILD/$$FPGA_TOP.json" &&\
	nextpnr-ice40 --hx8k --package ct256 --pcf $$PINMAP --asc $$BUILD/$$FPGA_TOP.asc --json $$BUILD/$$FPGA_TOP.json &&\
	icepack $$BUILD/$$FPGA_TOP.asc $$BUILD/$$FPGA_TOP.bin &&\
	iceprog -S $$BUILD/$$FPGA_TOP.bin &&\
	sed -i 's/sram_for_FPGA/sky130_sram_8kbyte_1r1w_32x2048_8/' $$SRAM_WRAPPER

# KLayout Command
klayout_cmd = \
	"klayout $(PROJECT_ROOT)/gds/$*.gds \
	-l $(PDKPATH)/libs.tech/klayout/tech/$(PDK).lyp"

# Open GDSII of design in KLayout
# Example target: make gdsview_team_00_klayout
.PHONY: gdsview_%_klayout
gdsview_%_klayout:
	@if echo "$(blocks)" | grep -qw "$*"; then \
		if [ -f "$(PROJECT_ROOT)/gds/$*.gds" ]; then \
			echo "Opening GDSII layout of $* in KLayout..."; \
			nix-shell --run $(klayout_cmd) --pure $(OPENLANE2_ROOT)/shell.nix; \
		else \
			if [ -n "$(wildcard $(PROJECT_ROOT)/gds/$*.gds.gz*)" ]; then \
				echo "Error: Design $* has a compressed GDSII file. Run \"make uncompress\" to extract the original file"; \
				false; \
			else \
				echo "Error: Design $* exists, but no GDSII file found"; \
				false; \
			fi; \
		fi; \
	else \
		echo "Error: Design $* does not exist"; \
		false; \
	fi


# Convert design HDL code from SystemVerilog to Verilog
.PHONY: sv2v_%
# Example target: make sv2v_team_00
sv2v_%:
	@mkdir -p verilog/rtl/team_projects/$*/converted_modules && \
	sv2v -y verilog/rtl/team_projects/$*/src -w verilog/rtl/team_projects/$*/converted_modules verilog/rtl/team_projects/$*/$*.sv && \
	echo "\nConversion complete!\n"


# Lint a module
.PHONY: vlint-%
# Example targets: make vlint-team_00 (for top level module), make vlint-team_00-t00_flex_counter (for submodule)
vlint-%:
	@export USER_PROJECT_VERILOG=$(UPRJ_ROOT)/verilog &&\
	export TEAM_DIR=$$USER_PROJECT_VERILOG/rtl/team_projects/$(firstword $(subst -, ,$*)) &&\
	export SRC_DIR=$$TEAM_DIR/src &&\
	if [ "$(firstword $(subst -, ,$*))" = "$(lastword $(subst -, ,$*))" ]; then \
		verilator --lint-only --timing -Wall -Wno-EOFNEWLINE -Wno-TIMESCALEMOD -y $$SRC_DIR \
		-y $$USER_PROJECT_VERILOG/rtl/wishbone_manager \
		-y $$USER_PROJECT_VERILOG/rtl/sram \
		$$TEAM_DIR/$(lastword $(subst -, ,$*)).sv; \
	else \
		verilator --lint-only --timing -Wall -Wno-EOFNEWLINE -Wno-TIMESCALEMOD -y $$SRC_DIR \
		-y $$USER_PROJECT_VERILOG/rtl/wishbone_manager \
		-y $$USER_PROJECT_VERILOG/rtl/sram \
		$$SRC_DIR/$(lastword $(subst -, ,$*)).sv; \
	fi


# Assemble RISC-V assembly (.asm) file into a list of instructions in a C header file
# Useful for CPU teams so they can load RISC-V instructions into RAM
assemble_%:
	@export GCC_PREFIX=riscv64-unknown-elf &&\
	export GCC_PATH=/package/riscv-gnu-toolchain/bin &&\
	cd verilog/dv && make assy2hex_$*


# Use this if you wish to view your design's congestion
congestion_gui:
	nix-shell --run "openroad -exit -no_splash -gui -metrics $(PWD)/openlane/tmp.json" --pure $(OPENLANE2_ROOT)/shell.nix
	
# Thanks to ChatGPT and Aidan Jacobsen for the following target
# Examples:
# "make init_team_00": Creates the required files for team_00 if they don't exist
# "make init_team_00 pristine=1": Deletes and recreates the files for team_00
pristine ?= 0
.PHONY: init_team_%
init_team_%:
	@team_number=$(subst init_team_,,$@); \
	echo "Attempting to initialize team_$$team_number"; \
	pristine="$(pristine)"; \
	# Check for --pristine argument \
	if echo "$$pristine" | grep -q -- '1'; then \
		pristine=1; \
	fi; \
	# Validate team number format \
	if ! echo "$$team_number" | grep -qE '^[0-9][0-9]$$'; then \
		echo "\033[31mERROR\033[0m: The target must be of the format init_team_## with a 2-digit number."; \
		exit 1; \
	fi; \
	# If pristine is set and the directory exists, delete it \
	if [ $$pristine -eq 1 ] && [ -d "./verilog/rtl/team_projects/team_$$team_number" ]; then \
		echo "Deleting existing directory ./verilog/rtl/team_projects/team_$$team_number"; \
		rm -rf ./verilog/rtl/team_projects/team_$$team_number; \
	fi; \
	# If pristine is set and the directory exists, delete it \
	if [ $$pristine -eq 1 ] && [ -d "./verilog/dv/team_$$team_number" ]; then \
		echo "Deleting existing directory ./verilog/dv/team_$$team_number"; \
		rm -rf ./verilog/dv/team_$$team_number; \
	fi; \
	# If pristine is set and the directory exists, delete it \
	if [ $$pristine -eq 1 ] && [ -d "./openlane/team_$$team_number" ]; then \
		echo "Deleting existing directory ./openlane/team_$$team_number"; \
		rm -rf ./openlane/team_$$team_number; \
	fi; \
	# If the directory doesn't exist, create it and copy files \
	if [ ! -d "./verilog/rtl/team_projects/team_$$team_number" ]; then \
		if [ ! -d "./verilog/dv/team_$$team_number" ]; then \
			if [ ! -d "./openlane/team_$$team_number" ]; then \
				echo "Creating directory ./verilog/rtl/team_projects/team_$$team_number"; \
				mkdir -p ./verilog/rtl/team_projects/team_$$team_number; \
				echo "Creating directory ./verilog/rtl/team_projects/team_$$team_number/src"; \
				mkdir -p ./verilog/rtl/team_projects/team_$$team_number/src; \
				echo "Creating Makefile"; \
				sed "s/##/$$team_number/g" ./template_files/Makefile_rtl > ./verilog/rtl/team_projects/team_$$team_number/Makefile; \
				echo "Creating team_$$team_number.sv"; \
				sed "s/##/$$team_number/g" ./template_files/team.sv > ./verilog/rtl/team_projects/team_$$team_number/team_$$team_number.sv; \
				echo "Creating team_$$team_number"'_Wrapper.sv'; \
				sed "s/##/$$team_number/g" ./template_files/team_Wrapper.sv > "./verilog/rtl/team_projects/team_$$team_number/team_$$team_number"'_Wrapper.sv'; \
				echo "Creating team_$$team_number"'_fpga_top.sv'; \
				sed "s/##/$$team_number/g" ./template_files/fpga_top.sv > "./verilog/rtl/team_projects/team_$$team_number/team_$$team_number"'_fpga_top.sv'; \
				echo "Creating team_$$team_number.yml"; \
				sed "s/##/$$team_number/g" ./template_files/team.yml > ./verilog/rtl/team_projects/team_$$team_number/team_$$team_number.yml; \
				echo "Creating includes"; \
				sed "s/##/$$team_number/g" ./template_files/includes > ./verilog/rtl/team_projects/team_$$team_number/includes; \
				echo "Creating directory ./verilog/dv/team_$$team_number"; \
				mkdir -p ./verilog/dv/team_$$team_number; \
				echo "Creating directory ./verilog/dv/team_$$team_number/module_tests"; \
				mkdir -p ./verilog/dv/team_$$team_number/module_tests; \
				echo "Creating ./verilog/dv/team_$$team_number/Makefile"; \
				sed "s/##/$$team_number/g" ./template_files/Makefile_dv > ./verilog/dv/team_$$team_number/Makefile; \
				echo "Creating ./verilog/dv/team_$$team_number/module_tests/Makefile"; \
				sed "s/##/$$team_number/g" ./template_files/Makefile_dv_module > ./verilog/dv/team_$$team_number/module_tests/Makefile; \
				echo "Creating ./verilog/dv/team_$$team_number/team_$$team_number"'_tb.v'; \
				sed "s/##/$$team_number/g" ./template_files/team_tb.v > "./verilog/dv/team_$$team_number/team_$$team_number"'_tb.v'; \
				echo "Creating ./verilog/dv/team_$$team_number/team_$$team_number.c"; \
				sed "s/##/$$team_number/g" ./template_files/team.c > ./verilog/dv/team_$$team_number/team_$$team_number.c; \
				echo "Creating directory ./openlane/team_$$team_number"; \
				mkdir -p ./openlane/team_$$team_number; \
				echo "Creating ./openlane/team_$$team_number/config.json"; \
				sed "s/##/$$team_number/g" ./template_files/config.json > ./openlane/team_$$team_number/config.json; \
				echo "Creating directory ./docs/team_$$team_number"; \
				mkdir -p ./docs/team_$$team_number; \
				echo "Creating ./docs/team_$$team_number/README.md"; \
				sed "s/TEAM_ID/$$team_number/g" ./template_files/team_docs.md > ./docs/team_$$team_number/README.md; \
				echo "\033[32mSUCCESS\033[0m: Initialization complete for team_$$team_number"; \
			else \
				echo "\033[31mERROR\033[0m: Directory ./opnelane/team_$$team_number already exists."; \
				exit 1; \
			fi \
		else \
			echo "\033[31mERROR\033[0m: Directory ./verilog/dv/team_$$team_number already exists."; \
			exit 1; \
		fi \
	else \
		echo "\033[31mERROR\033[0m: Directory ./verilog/rtl/team_projects/team_$$team_number already exists."; \
		exit 1; \
	fi

# Create NEBULA top level files
.PHONY: nebula
nebula: bus-wrap-generate
	@python3 ./scripts/nebula_generation.py
	@python3 ./scripts/includes_generation.py
	@python3 ./scripts/config_generation.py
	
