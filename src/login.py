import os,sys,time
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('-m', dest='mode', required=True, type=str, help='mode: login check_login change_password ')
parser.add_argument('-u', dest='username', required=False, type=str, help='username ')
parser.add_argument('-p', dest='password', required=False, type=str, help='password ')
parser.add_argument('-np', dest='new_password', required=False, type=str, help='new password ')
parser.add_argument('-ip', dest='ipaddress', required=False, type=str, help='ip address ')
parser.add_argument('-func', dest='function', required=False, type=str, help='function permission_check ')
args = parser.parse_args()
args.ipaddress=args.ipaddress.split(":")[0]

#init
user_dict=dict()
for line in open('user.pass').read().splitlines():
    txt=line.split('\t')
    if int(time.time()) - int(txt[3]) <= 1800:
        user_dict[txt[0]]=[txt[1],txt[2],txt[3],txt[4]]
    else:
        user_dict[txt[0]]=[txt[1],'0','0',txt[4]]

def check_ipaddress(user_dict,ip):
    for us,pa in user_dict.items():
        if pa[1] == ip:
            user_dict[us][2] = str(int(time.time()))
            return us
    return False

if args.mode == 'login':
    if not (args.username and args.password and args.ipaddress):
        sys.exit()
    if args.username in user_dict.keys() and user_dict[args.username][0] == args.password:
        us = check_ipaddress(user_dict,args.ipaddress) 
        if us and us != args.username :
            user_dict[us][1] = ""
        user_dict[args.username][1] = args.ipaddress
        user_dict[args.username][2] = str(int(time.time()))
        print('Y',end="")
        with open('user.pass','w') as U:
            for us,pa in user_dict.items():
                U.write('\t'.join([us,pa[0],pa[1],pa[2],pa[3]])+'\n')  
    else:
        print('N',end="")
elif args.mode == 'check_login':
    if not (args.ipaddress):
        sys.exit()
    us=check_ipaddress(user_dict,args.ipaddress)
    if us:
        print(us + '\t' + user_dict[us][3],end="")
    else:
        print('N',end="")
elif args.mode == 'change_password':
    if not (args.username and args.password and args.ipaddress and args.new_password):
        sys.exit()
    if args.username in user_dict.keys() and user_dict[args.username][0] == args.password:
        user_dict[args.username][0] = args.new_password
        print('Y',end="")
        with open('user.pass','w') as U:
            for us,pa in user_dict.items():
                U.write('\t'.join([us,pa[0],pa[1],pa[2],pa[3]])+'\n')  
    else:
        print('N',end="")
        
      
        
elif args.mode == 'permission_check':
    if not (args.ipaddress and args.function):
        sys.exit()
    us=check_ipaddress(user_dict,args.ipaddress)
    if us and ( set(args.function.split(',')) & set(user_dict[us][3].split(',')) ):
        print('Y',end="")
    else:
         print('N',end="")
    
#end
