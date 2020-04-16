##
# Test proof of concept: to show programs built in a container can use files in an external filestore
##

import os
import hashlib
import sys

try:
	os.chdir("/nemo_exp")
except OSError:
	print("Directory doesn't exist; can't continue")
	sys.exit(1)

# read config file
with open("config.txt", "r") as cf:
	s = cf.readline()

# write results file
results_dir = "/nemo_results"

if not os.path.isdir(results_dir):
	os.mkdir(results_dir)

os.chdir(results_dir)
with open("results.txt", "w") as rf:
	rf.write(hashlib.sha256(s).hexdigest())
