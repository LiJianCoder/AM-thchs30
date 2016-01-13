#!/bin/bash

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

# Acoustic model parameters
numLeavesTri=2000
numGaussTri=10000
numLeavesMLLT=2500
numGaussMLLT=15000
numLeavesSAT=2500
numGaussSAT=15000

numLeavesLargeSAT=4200
numGaussLargeSAT=40000

feats_nj=10
train_nj=10
decode_nj=10

# echo ============================================================================
# echo "                Lexicon & Language Preparation                     "
# echo ============================================================================
# utils/prepare_lang.sh --position_dependent_phones false data/local/dict "sil" data/local/lang_tmp data/lang


# echo ============================================================================
# echo "                G Preparation                     "
# echo ============================================================================
# local/thchs30_lang_test_prep.sh


echo ============================================================================
echo "MFCC Feature Extration & CMVN for Training and Test set"
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc

for x in train dev test; do 
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj data/$x exp/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done

echo ============================================================================
echo "   MonoPhone Training & Decoding   "
echo ============================================================================

steps/train_mono.sh --boost-silence 1.25 --nj "$train_nj" \
 --cmd "$train_cmd" data/train data/lang exp/mono || exit 1;

utils/mkgraph.sh --mono data/lang_test exp/mono exp/mono/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/mono/graph data/dev exp/mono/decode_dev

echo ============================================================================
echo "   tri1 : Deltas + Delta-Deltas Training & Decoding               "
echo ============================================================================

steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" \
 --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
 2000 10000 data/train data/lang exp/mono_ali exp/tri1

utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
 exp/tri1/graph data/dev exp/tri1/decode_dev

echo ============================================================================
echo "                 tri2 : LDA + MLLT Training & Decoding                    "
echo ============================================================================

# align tri1
steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
 data/train data/lang exp/tri1 exp/tri1_ali

# tri2:lda_mllt
steps/train_lda_mllt.sh --cmd "$train_cmd" \
--splice-opts "--left-context=3 --right-context=3" \
 2500 15000 data/train data/lang exp/tri1_ali exp/tri2

# decode tri2
utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph

steps/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" \
 exp/tri2/graph data/dev exp/tri2/decode_dev

echo ============================================================================
echo "              SAT Training & Decoding                 "
echo ============================================================================

#lda_mllt_ali
steps/align_si.sh  --nj "$train_nj" --cmd "$train_cmd" \
 --use-graphs false data/train data/lang exp/tri2 exp/tri2_ali

#sat
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
 data/train data/lang exp/tri2_ali exp/tri3

utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph

steps/decode_fmllr.sh --cmd "$decode_cmd" --nj "$decode_nj" \
 exp/tri3/graph data/dev exp/tri3/decode_dev

# Building a larger SAT system.

#sat_ali
steps/align_fmllr.sh --nj "$train_nj" --cmd "$train_cmd" \
 data/train data/lang exp/tri3 exp/tri3_ali

#quick
steps/train_quick.sh --cmd "$train_cmd" 4200 40000 \
 data/train data/lang exp/tri3_ali exp/tri4

utils/mkgraph.sh data/lang_test exp/tri4 exp/tri4/graph

steps/decode_fmllr.sh --cmd "$decode_cmd" --nj "$decode_nj" \
 exp/tri4/graph data/dev exp/tri4/decode_dev

steps/decode_fmllr.sh --cmd "$decode_cmd" --nj "$decode_nj" \
 exp/tri4/graph data/test exp/tri4/decode_test



# echo ============================================================================
# echo "               DNN Hybrid Training & Decoding (Karel's recipe)            "
# echo ============================================================================

# local/nnet/run_dnn.sh

echo "============The WER of dev and test=========="
bash RESULTS.sh

echo "run end"
