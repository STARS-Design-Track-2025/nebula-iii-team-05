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

# ---- Test patterns for project striVe ----

.SUFFIXES:
.SILENT: clean all

PATTERNS := $(shell ls -d team_[0-9][0-9] 2>/dev/null)

all:  ${PATTERNS}

	for i in ${PATTERNS}; do \
		( cd $$i && make -f Makefile $${i}.vcd &> verify.log && grep Monitor verify.log) ; \
	done

DV_PATTERNS = $(foreach dv, $(PATTERNS), verify-$(dv))
$(DV_PATTERNS): verify-% : 
	cd $* && make

clean:  ${PATTERNS}
	for i in ${PATTERNS}; do \
		( cd $$i && \rm  -f *.elf *.hex *.bin *.o *.h *.vvp *.log *.vcd *.lst *.hexe ) ; \
	done
	for i in $(filter-out io_ports la_test1 la_test2 wb_port mprj_stimulus, $(PATTERNS)); do \
		( cd $$i && \cd module_tests && \make clean) ; \
	done
	rm -rf *.log
	
.PHONY: clean all

# Convert RISC-V assembly to list of RISC-V hexadecimal instructions
.PHONY: assy2hex_%
assy2hex_%:
	@if [ -f "$*/$*_cpu.asm" ]; then \
		$(GCC_PATH)/$(GCC_PREFIX)-as -march=rv32im -mabi=ilp32 -o $*/$*_cpu.o $*/$*_cpu.asm; \
		$(GCC_PATH)/$(GCC_PREFIX)-ld -m elf32lriscv -Ttext=0x0 -o $*/$*_cpu.elf $*/$*_cpu.o; \
		$(GCC_PATH)/$(GCC_PREFIX)-objcopy -O binary $*/$*_cpu.elf $*/$*_cpu.bin; \
		xxd -p -c 4 $*/$*_cpu.bin | awk '{print substr($$0,7,2) substr($$0,5,2) substr($$0,3,2) substr($$0,1,2)}' > $*/$*_cpu.hex; \
		echo "\nHEX memory file generated!\n"; \
		echo "uint32_t instructions[] = {" > $*/$*_cpu.h; \
		awk '{ lines[NR] = $$0 } END { for (i = 1; i <= NR; i++) printf "  0x%s%s\n", lines[i], (i < NR ? "," : "") }' $*/$*_cpu.hex >> $*/$*_cpu.h; \
		echo "};" >> $*/$*_cpu.h; \
		echo "C Header file created!\n"; \
	else \
		echo "\nERROR: No assembly file 'verilog/dv/$*/$*_cpu.asm' found!\n"; \
		false; \
	fi
