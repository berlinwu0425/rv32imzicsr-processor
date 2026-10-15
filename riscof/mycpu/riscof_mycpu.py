import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class mycpu(pluginTemplate):
    __model__ = "mycpu"
    __version__ = "XXX"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        self.dut_exe = "/home/berlinwu/RV32I_CPU/obj_dir/Vcpu_tb"
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath = os.path.abspath(config['pluginpath'])
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        if 'target_run' in config and config['target_run'] == '0':
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):
        self.work_dir = work_dir
        self.suite_dir = suite

        self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} -mabi=ilp32 \
          -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
          -T ' + self.pluginpath + '/env/link.ld\
          -I ' + self.pluginpath + '/env/\
          -I ' + archtest_env + ' {2} -o {3} {4}'

        # 指向剛剛建立的 run_dut.py 輔助腳本
        self.run_dut_script = self.pluginpath + '/env/run_dut.py'

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        self.isa = 'rv' + self.xlen
        if "I" in ispec["ISA"]:
            self.isa += 'i'
        if "M" in ispec["ISA"]:
            self.isa += 'm'
        if "F" in ispec["ISA"]:
            self.isa += 'f'
        if "D" in ispec["ISA"]:
            self.isa += 'd'
        if "C" in ispec["ISA"]:
            self.isa += 'c'
        # 多字母擴充 (Zifencei, Zicsr...) 要用底線接在單字母擴充後面
        # 例如 rv32i_zifencei，不能像單字母那樣直接串接
        if "Zifencei" in ispec["ISA"]:
            self.isa += '_zifencei'
        if "Zicsr" in ispec["ISA"]:
            self.isa += '_zicsr'

    def runTests(self, testList):
        if os.path.exists(self.work_dir + "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir + "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = 'make -k -j' + self.num_jobs

        for testname in testList:
            testentry = testList[testname]
            test = testentry['test_path']
            test_dir = testentry['work_dir']

            elf = 'my.elf'

            # RISCOF 規定的 signature 檔名：DUT-<dutname>.signature
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            compile_macros = ' -D' + " -D".join(testentry['macros'])

            # testentry['isa'] 是 RISCOF 自己算出來的，但它不會帶上
            # Zifencei 這種多字母擴充，這裡手動補上，確保 -march= 正確
            march_str = testentry['isa'].lower()
            if '_zifencei' in self.isa and 'zifencei' not in march_str:
                march_str += '_zifencei'
            if '_zicsr' in self.isa and 'zicsr' not in march_str:
                march_str += '_zicsr'
            cmd = self.compile_cmd.format(march_str, self.xlen, test, elf, compile_macros)

            if self.target_run:
                simcmd = 'python3 {0} {1} {2} {3}'.format(
                    self.run_dut_script, elf, sig_file, self.dut_exe)
            else:
                simcmd = 'echo "NO RUN"'

            execute = '@cd {0} && {1} && {2}'.format(testentry['work_dir'], cmd, simcmd)

            make.add_target(execute)

        make.execute_all(self.work_dir)

        if not self.target_run:
            raise SystemExit(0)
