#!/bin/bash

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e


echo ============================================================================
echo "   view some parameters and results   "
echo ============================================================================

gmm-copy --binary=false exp/mono/final.mdl mono_final.mdl.txt
gmm-copy --binary=false exp/tri1/final.mdl tri1_final.mdl.txt
gmm-copy --binary=false exp/tri2/final.mdl tri2_final.mdl.txt
gmm-copy --binary=false exp/tri3/final.mdl tri3_final.mdl.txt

# gmm-copy --binary=false exp/tri1/final.mdl tri1.mdl.txt

# gmm-copy --binary=false exp/tri2/final.mdl tri2.mdl.txt
