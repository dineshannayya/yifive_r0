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

set ::env(MERGED_LEF_UNPADDED) "../lef/merged_unpadded.lef"
set ::env(INPUT_DEF) "../def/$::env(DESIGN_NAME).def"
set ::env(SAVE_NETLIST) "netlist/$::env(DESIGN_NAME).v"


if {[catch {read_lef $::env(MERGED_LEF_UNPADDED)} errmsg]} {
    puts stderr $errmsg
    exit 1
}

if {[catch {read_def $::env(INPUT_DEF)} errmsg]} {
    puts stderr $errmsg
    exit 1
}

#write_verilog -include_pwr_gnd $::env(SAVE_POWER_NETLIST)
write_verilog $::env(SAVE_NETLIST)

