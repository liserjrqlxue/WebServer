function login_check(){
		res=document.getElementById("user").innerHTML;
		if (res == "未登录"){
			alert("未登录无法使用此功能");
			return false; 
		}else{
			return true;
}}
function login_check2(){
		res=document.getElementById("user").innerHTML;
		if (res == "未登录"){
			return true; 
		}else{
			alert("您已登录")
			return false;
}}
