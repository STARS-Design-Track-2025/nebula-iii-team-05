TEAM_PROJECT_FOLDER := $(shell pwd)

#Extract the folder name (e.g. team_05_proj)
TEAM_PROJECT_FOLDER_NAME := $(notdir $(TEAM_PROJECT_FOLDER))

#If the yml does not exist in this directory, this generates it from the team_05_proj.sv file
.PHONY: generate_wb_yaml
generate_wb_yaml:
	@if [ ! -f $(TEAM_PROJECT_FOLDER_NAME).yml ]; then \
		python3 $(BUS_WRAP_ROOT)/scripts/v2yaml.py $(TEAM_PROJECT_FOLDER)/$(TEAM_PROJECT_FOLDER_NAME).sv $(TEAM_PROJECT_FOLDER_NAME) > $(TEAM_PROJECT_FOLDER_NAME).yml; \
    fi


# This removes the team_05_proj_WB.v file and generates a new one using the yml in this directory
# It also adds power pins to the generated wrapper
.PHONY: generate_wb_wrapper
generate_wb_wrapper:
	@python3 ../../../../scripts/team_configuration.py --yaml $(PWD)/team_05.yml --wrapper $(PWD)/team_05_Wrapper.sv
	@if [ -f $(TEAM_PROJECT_FOLDER_NAME)_WB.v ]; then \
		rm -f $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
	fi
	@echo "Generating WB Wrapper for team_05"; \
        python3 $(BUS_WRAP_ROOT)/scripts/bus_wrap.py $(TEAM_PROJECT_FOLDER_NAME).yml -wb > $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		echo "Adding power pins to WB wrapper..."; \
		sed '/^module team_05_WB/ a \
	`ifdef USE_POWER_PINS\
		inout vccd1,    // User area 1 1.8V supply\
		inout vssd1,    // User area 1 digital ground\
	`endif' $(TEAM_PROJECT_FOLDER_NAME)_WB.v > $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v; \
		rm $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		mv $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		sed '/team_05 instance_to_wrap/ a \
		`ifdef USE_POWER_PINS\
			.vccd1(vccd1),    // User area 1 1.8V power\
			.vssd1(vssd1),    // User area 1 digital ground\
		`endif' $(TEAM_PROJECT_FOLDER_NAME)_WB.v > $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v; \
		rm $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		mv $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		sed '/`include\s*"wb_wrapper\.vh"/d' $(TEAM_PROJECT_FOLDER_NAME)_WB.v > $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v; \
		rm $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		mv $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		sed '/wire\s\+nrst\s*=\s*(~rst_i);/d' $(TEAM_PROJECT_FOLDER_NAME)_WB.v > $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v; \
		rm $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		mv $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		sed 's/output\s\+wire\s\+\[34-1:0\]\s\+gpio_oeb/output wire [34-1:0] gpio_oeb,\ninput wire nrst/' $(TEAM_PROJECT_FOLDER_NAME)_WB.v > $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v; \
		rm $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \
		mv $(TEAM_PROJECT_FOLDER_NAME)_WB_modified.v $(TEAM_PROJECT_FOLDER_NAME)_WB.v; \

