#! /ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/python3
# coding=utf-8
import os,sys,time
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('-mode', dest='mode', required=True, type=str, help='mode: triploid or contamination ')
parser.add_argument('-i', dest='sample', required=True, type=str, help='input sample')
parser.add_argument('-o', dest='outdir', required=True, type=str, help='output dir ')
args = parser.parse_args()

if args.mode == "triploid":
    tsv = os.popen(f'find `perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl {args.sample}|head -1|cut -f 1 `/annotation/*.out.*tsv|xargs ls -t|head -1').read().strip()
    print(f'sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/triploid.sh {tsv} {args.outdir}')
    os.system(f'sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/triploid.sh {tsv} {args.outdir}')
elif args.mode == "contamination":
    vcf = os.popen(f'find `perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl {args.sample}|head -1|cut -f 1 `/annotation/*.final.vcf.gz|xargs ls -t|head -1').read().strip()
    print(f'sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/contamination.sh {vcf} {args.outdir}')
    os.system(f'sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/contamination.sh {vcf} {args.outdir}')
