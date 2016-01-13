#!/usr/bin/env python2.7
# coding=utf8

import os
import sys
import shutil

# data preparation
print 'begin data preparation!'


#=====================step1=======================
# 准备wav.scp for train dev test,直接从doc/list读取

scp_thchs30 = '/archives/lyq/thchs30/doc/list/'
obj_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/data/local/data/'

cmdline = 'cat ' + scp_thchs30 + 'train.lst > ' + obj_path + 'train.wav.scp'
os.system(cmdline)

cmdline = 'cat ' + scp_thchs30 + 'cv.lst > ' + obj_path + 'dev.wav.scp'
os.system(cmdline)

cmdline = 'cat ' + scp_thchs30 + 'test.lst > ' + obj_path + 'test.wav.scp'
os.system(cmdline)

#=====================step2=======================
# 准备text for train dev test,直接从doc/trans读取
scp_thchs30 = '/archives/lyq/thchs30/doc/trans/'
obj_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/data/local/data/'

cmdline = 'cat ' + scp_thchs30 + 'train.phone.txt > ' + obj_path + 'train.text'
os.system(cmdline)

cmdline = 'cat ' + scp_thchs30 + 'cv.phone.txt > ' + obj_path + 'dev.text'
os.system(cmdline)

cmdline = 'cat ' + scp_thchs30 + 'test.phone.txt > ' + obj_path + 'test.text'
os.system(cmdline)

# =====================step3=======================
# 准备utt2spk for train dev test,从wav.scp获取
src_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/data/local/data/'

for x in ['train', 'test', 'dev']:
    f = open(src_path + x + '.wav.scp', 'r')
    result = list()
    for line in f.readlines():
        data = line.split(' ')
        spk, utt = data[0].split('_')
        result.append(data[0]+' '+spk+ '\n')
    f.close

    open(src_path + x + '.utt2spk', 'w').write('%s' % ('').join(result))

# =====================step4=======================
# 准备spk2utt

cmd_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30/s5/utils/'
sys.path.append(cmd_path)


for x in ['train', 'test', 'dev']:
    infile = src_path + x + '.utt2spk'
    outfile = src_path + x + '.spk2utt'
    cmdline = cmd_path + 'utt2spk_to_spk2utt.pl '
    cmdline += infile + ' > ' + outfile
    os.system(cmdline)

# =====================step5=======================
# 将整理train, test, dev, 形成单独的文件夹

cmd_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/utils/'
sys.path.append(cmd_path)

in_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/data/local/data/'
out_path = '/home/lyq/asr/kaldi-trunk/egs/thchs30_phone/s5/data/'

for temp in ['train', 'dev', 'test']:
    if not os.path.exists(out_path + temp):
        os.mkdir(out_path + temp)
    shutil.copy(in_path + temp + '.wav.scp', out_path + temp + '/wav.scp')
    shutil.copy(in_path + temp + '.text', out_path + temp + '/text')
    shutil.copy(in_path + temp + '.spk2utt', out_path + temp + '/spk2utt')
    shutil.copy(in_path + temp + '.utt2spk', out_path + temp + '/utt2spk')

for temp in ['train', 'dev', 'test']:
#     cmdline = cmd_path + 'fix_data_dir.sh ' + out_path + temp
#     os.system(cmdline)

    cmdline = cmd_path + 'validate_data_dir.sh --no-feats ' + out_path + temp
    os.system(cmdline)

print 'data preparation succeeded!'
