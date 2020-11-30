# coding=utf-8
from sys import argv
import os
import time,sys
import cx_Oracle

input_dir = "/ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/public/phoenix"
day10=os.popen('date "+%Y%m%d" -d "10 days ago"').readline().strip()
db=cx_Oracle.connect('lims_interface/cCcRn625HXT@192.168.225.133:1521/orcl',encoding='gb2312')
cr=db.cursor()
cr.execute(f"select MAIN_SAMPLE_NUM,LIBRARY_NUM,HYBRID_LIBRARY_NUM,CHIP_CODE,COMPUTER_TIME,ANALYZE_STATUS,PRODUCT_CODE from LIMS.view_l_forxxfx2_mainsample where to_char(COMPUTER_TIME,'YYYYMMDD')>={day10} and ANALYZE_STATUS='未分析' and HYBRID_LIBRARY_NUM LIKE 'BGIV4__SZ%'")
rs=cr.fetchall()
#[样本号,子文库号,杂交文库号,芯片号,上机时间,分析状态,产品编号]
sycamore=['DX0458','DX1515','DX1616','DX0700','DX1335','DX1680']
samplelist=list()
for limsline in rs:
    if limsline[6] in sycamore:samplelist.append(f"{limsline[3]}-{limsline[1]}\t{limsline[0]}")

weslist=os.popen(f'cat {input_dir}/V*').read().splitlines()
lostlist=list()
for i in samplelist:
    if i.split('\t')[0] not in weslist:
        lostlist.append(i)
if lostlist:
    chiplist=[x.split('-')[0] for x in lostlist]
    chiplist=list(set(chiplist))

user="zhanghuaijin@genomics.cn"
passwd="Zqq123321B"
to2="yehaodong@bgi.com,zhanghuaijin@bgi.com"
cc2="yujingtang@bgi.com"
#to2="zhanghuaijin@bgi.com"
#cc2="zhanghuaijin@bgi.com"
title="sycamore fail to receive these chips and samples"
body='<html><body><p>lost chips: <br> %s <br>were attached<br><br> %s</p></body></html>'%('<br>'.join(chiplist),'<br>'.join(lostlist))
if lostlist:
    os.system(f"/home/liuqiang1/USR/soft/bin/perl send_mail.pl -u {user} -p {passwd} -t {to2} -c '{cc2}' -s '{title}' -b '{body}'")
