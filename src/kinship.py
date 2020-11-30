import sys,glob,os
samplelist=open(sys.argv[1]).read().splitlines()
outdir=sys.argv[2]
if len(samplelist) != 3 : sys.exit("sample num must be 3")
vcfpathlist=list()

for i in samplelist:
    resultpath=os.popen('perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl %s|head -1'%(i.strip())).read().split('\t')[1].strip()
    vcfpath=glob.glob(resultpath+"/*vcf*")
    if len(vcfpath):
        vcfpathlist.append(vcfpath[0])
    else:
        sys.exit("%s no vcf"%(i))

vcflistfile=os.path.join(outdir,"vcflist")
with open(vcflistfile,'w') as L:
    for i in vcfpathlist:
        if i :L.write(i+"\n")
os.system('sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/kinship.sh %s %s'%(vcflistfile,outdir))
