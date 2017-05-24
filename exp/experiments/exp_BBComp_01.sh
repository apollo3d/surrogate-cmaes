#!/bin/bash
#
# Job-submitting experiment for the first 10D GP model testing
# It is expected to be located in exp/experiments/

export EXPID='exp_BBComp_01'

# Enable this option for using Matlab MCR compilated binaries:
export useMCR=1

# !!! THIS HAS TO BE HERE !!!
#     vvvvvvvvvvvvvvvvvvv
CWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $CWD/../bash_settings.sh
. $CWD/../metacentrum_bbcomp_common.sh
#     ^^^^^^^^^^^^^^^^^^^
# !!! THIS HAS TO BE HERE !!!

# job submittion can be done via the bash function:
#
# submit [JOBNAME_SUFFIX]
#
#     submits a job with current-set $INST and $OPTS

# critical characters has to be replaced in $OPTS:
# '|' with ',' and "%" with "'"
OPTS=""

QUEUE="4:00:00"

for INST in {22..23}; do
  submit
done

exit 0
