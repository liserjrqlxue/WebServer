package main

import (
	"archive/zip"
	"crypto/md5"
	"fmt"
	"github.com/liserjrqlxue/simple-util"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// os
var (
	ex, _        = os.Executable()
	exPath       = filepath.Dir(ex)
	pSep         = string(os.PathSeparator)
	templatePath = exPath + pSep + "template" + pSep
)

var (
	sep = regexp.MustCompile(`\s+`)
)

type Infos struct {
	Option  string
	Img     string
	Src     string
	Token   string
	Title   string
	Err     string
	Message string
	Href    string
	User    string
	Permission string
}

func md5sum(str string) string {
	byteStr := []byte(str)
	sum := md5.Sum(byteStr)
	sumStr := fmt.Sprintf("%x", sum)
	return sumStr
}

func createToken() string {
	// token
	return md5sum(strconv.FormatInt(time.Now().Unix(), 10))
}
func getUser(r *http.Request) (string,string){
	params := []string{
		"src/login.py",
		"-m", "check_login",
		"-ip", r.RemoteAddr,
	}
	log.Println(params)
	out,err := exec.Command("python", params...).Output()
	if string(out) != "N" && err == nil{
		username := strings.Split(string(out),"\t")[0]
		permission := strings.Split(string(out),"\t")[1]
		return username,permission
	}else{
		return "未登录",""
	}
}

func func_permission_check(Function_permission string , User_permission string) bool{
	if Function_permission == "" {
		return true
	}
	for _,f := range strings.Split(Function_permission,",") {
		for _,j := range strings.Split(User_permission,",") {
			if f == j {
			return true
			}
		}
	}
	return false
}

func get_permission(r *http.Request, function_name string) bool{
	params := []string{
		"src/login.py",
		"-m", "permission_check",
		"-ip", r.RemoteAddr,
		"-func", function_name,
	}
	if function_name == ""{
		return true
	}
	out,err := exec.Command("python", params...).Output()
	if string(out) == "Y" && err == nil{
		return true
	}else{
		return false
	}
}

// ZipFiles compresses one or many files into a single zip archive file
func ZipFiles(filename string, files []string) error {
	newfile, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer newfile.Close()

	zipWriter := zip.NewWriter(newfile)
	defer zipWriter.Close()

	// Add files to zip
	for _, file := range files {
		log.Println(file)
		zipFile, err := os.Open(file)
		if err != nil {
			return err
		}

		// Get the file information
		info, err := zipFile.Stat()
		if err != nil {
			return err
		}
		header, err := zip.FileInfoHeader(info)
		if err != nil {
			return err
		}

		// Change to deflate to gain better compression
		// see http://golang.org/pkg/archive/zip/#pkg-constants
		header.Method = zip.Deflate

		// UTC + 8huor(28800s)
		header.Modified = header.Modified.Add(time.Duration(28800 * 1e9))
		//header.SetModTime(header.ModTime().Add(time.Duration(28800 * 1e9)))

		writer, err := zipWriter.CreateHeader(header)
		if err != nil {
			return err
		}
		_, err = io.Copy(writer, zipFile)
		if err != nil {
			return err
		}
		zipFile.Close()
	}
	return nil
}
func sayhelloName(w http.ResponseWriter, r *http.Request) {
	r.ParseForm() //解析url传递的参数，对于POST则解析响应包的主体（request body）
	//注意:如果没有调用ParseForm方法，下面无法获取表单的数据
	fmt.Println(r.Form) //这些信息是输出到服务器端的打印信息
	fmt.Println("path", r.URL.Path)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Println("key:", k)
		fmt.Println("val:", strings.Join(v, ""))
	}
	//fmt.Fprintf(w, "<script>alert('good')</script>") //这个写入到w的是输出到客户端的
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"index.html")
	if err != nil {
		fmt.Fprint(w, err)
		return
	}
	var Info Infos
	UPer := ""
	Info.Title = "Home Page"
	Info.Token = createToken()
	Info.User,UPer = getUser(r)
	function_list := []string{}
	for function := range Permission{
		if func_permission_check(Permission[function],UPer){
			function_list = append(function_list,function)
		}
	}
	Info.Permission=strings.Join(function_list, ",")
	log.Println(Info.User)
     t.ExecuteTemplate(w, "index", Info)
}

func logRequest(r *http.Request) {
	log.Println(r.Form) //这些信息是输出到服务器端的打印信息
	log.Println("path", r.URL.Path)
	log.Println("scheme", r.URL.Scheme)
	log.Println(r.Form["url_long"])
	for k, v := range r.Form {
		log.Printf("key:%s\t", k)
		if len(v) < 1024 {
			log.Printf("key:[%s]\tval:[%v]\n", k, v)
		} else {
			log.Printf("key:[%s]\tval: large data!\n", k)
		}
	}
}


func login(w http.ResponseWriter, r *http.Request) {
	log.Println("method:", r.Method)
	var Info Infos
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html",templatePath+"login.html")
	simple_util.CheckErr(err)
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		username := r.FormValue("username")
		password := r.FormValue("password")
		ip := r.RemoteAddr
		params := []string{
			"src/login.py",
			"-m", "login",
			"-u", username,
			"-p", password,
			"-ip", ip,
			}
		log.Println(params)
		out,err := exec.Command("python", params...).Output()
		if string(out) == "Y" && err == nil{
			fmt.Fprintf(w, "<script>alert('登陆成功');window.location.href = '/';</script>")
		}else{
			Info.Message = "账号密码错误"
			t.ExecuteTemplate(w, "login", Info)
		}
	}else {
		r.ParseForm()
		t.ExecuteTemplate(w, "login", Info)
	}
	
}

var perl = "/home/liuqiang1/USR/soft/bin/perl"

func plotReadsLocal(w http.ResponseWriter, r *http.Request) {
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "本地集群画reads图"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["plotReadsLocal"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	log.Println("method:", r.Method)
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		prefix := r.FormValue("prefix")
		if r.Form["position"][0] != "at" && len(r.Form["End"]) > 0 {
			r.Form["Start"][0] = r.Form["Start"][0] + r.Form["position"][0] + r.Form["End"][0]
		}
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		err := os.MkdirAll("public" + pSep + "plotReadsLocal" + pSep + tag, 0755)
		simple_util.CheckErr(err)
		pngPrefix := prefix + "_" + Info.Token
		pngSuffix := "_" + r.Form["chr"][0] + "_" + r.Form["Start"][0] + ".png"
		pngName := pngPrefix + pngSuffix
		Info.Src = tag + "/" + pngName
		Info.Img = pngName
		var cmd = []string{
			"src" + pSep + "plotreads.sz.pl",
			"-Rs", "/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/Rscript",
			"-b", r.Form["path"][0],
			"-c", r.Form["chr"][0],
			"-p", r.Form["Start"][0], "-r",
			"-prefix", "public" + pSep + "plotReadsLocal" + pSep + tag + pSep + pngPrefix,
			"-f", "20", "-d", "-a", "-l", r.Form["Plotread_Length"][0],
		}
		log.Println(cmd)
		simple_util.RunCmd(perl, cmd...)
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "plotReadsLocal", Info)
	}
}

func upload(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	var Info Infos
	Info.Title = "上传文件"
	Info.Token = createToken()
	if r.Method == "GET" {
		t, err := template.ParseFiles(templatePath + "upload.html")
		simple_util.CheckErr(err)
		t.Execute(w, Info)
	} else {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		simple_util.CheckErr(err)
		defer file.Close()
		fmt.Fprintf(w, "%v", handler.Header)
		f, err := os.Create("public" + pSep + handler.Filename)
		simple_util.CheckErr(err)
		defer f.Close()
		io.Copy(f, file)
	}
}

func filterExcel(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "filter Excel"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["filterExcel"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			log.Println(err)
			Info.Err = err.Error()
			t.Execute(w, Info)
			return
		}
		defer file.Close()
		f, err := os.Create("public" + pSep + "filter" + pSep + handler.Filename)
		simple_util.CheckErr(err)
		defer f.Close()
		io.Copy(f, file)
		cmd := []string{
			filepath.Join(exPath,"src","genefilter.pl"),
			"-i", "public" + pSep + "filter" + pSep + handler.Filename,
			"-g", r.FormValue("gene"),
			"-o", "public" + pSep + "filter" + pSep + handler.Filename + ".filter.xlsx",
		}
		simple_util.RunCmd(perl, cmd...)
		log.Println(cmd)
		Info.Href = "/public/filter/" + handler.Filename + ".filter.xlsx"
		Info.Message = "Download"
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "filterExcel", Info)
	}
}
func filterKDNY(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "filter KDNY"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["filterKDNY"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "filter", Info.Token)
		os.MkdirAll(workdir, 0755)
		sample_list := sep.Split(r.FormValue("sample"),-1)
		for i := range sample_list {
			cmd := []string{
				"src/allgene.filter.sh",
				sample_list[i],
				"KDNY",
				workdir,
			}
			log.Println(cmd)
			simple_util.RunCmd("bash",cmd...)
		}
		Info.Href = "/public/filter/" + Info.Token
		Info.Message = "Open Dir"
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "filterExcel", Info)
	}
}

func filterInfertility(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "filter Infertility"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["filterInfertility"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "filter", Info.Token)
		os.MkdirAll(workdir, 0755)
		sample_list := sep.Split(r.FormValue("sample"),-1)
		for i := range sample_list {
			cmd := []string{
				"src/allgene.filter.sh",
				sample_list[i],
				"Infertility",
				workdir,
			}
			log.Println(cmd)
			simple_util.RunCmd("bash",cmd...)
		}
		Info.Href = "/public/filter/" + Info.Token
		Info.Message = "Open Dir"
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "filterExcel", Info)
	}
}

func BamExtractor(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Bam Extractor"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["BamExtractor"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "filter", Info.Token)
		os.MkdirAll(workdir, 0755)
		cmd := []string{
			"src/Bam_Extractor.sh",
			r.FormValue("sample"),
			r.FormValue("position"),
			workdir,
		}
		simple_util.RunCmd("bash",cmd...)
		log.Println(cmd)
		Info.Href = "/public/filter/" + Info.Token
		Info.Message = "Open Dir"
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "BamExtractor", Info)
	}
}

func ExomeDepthplot(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "ExomeDepth plot"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["ExomeDepthplot"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		cmd := []string{
			"src/ExomeDepth_plot.sh",
			r.FormValue("sample"),
			r.FormValue("gene"),
			r.Form["chr"][0],
			Info.Token,
		}
		simple_util.RunCmd("bash",cmd...)
		log.Println(cmd)
		Info.Href = "/public/ExomeDepth/" + Info.Token +".pdf"
		Info.Message = "Open plot"
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "ExomeDepthplot", Info)
	}
}

func plotExonCOV(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "exon coverage plot"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["plotExonCOV"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20) //分配获取信息内存
		logRequest(r)
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		workdir := filepath.Join("public", "exome_cnv", tag, Info.Token)
		os.MkdirAll(workdir, 0755)
		info := r.FormValue("info")
		infoPath := filepath.Join(workdir, "info")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		fmt.Fprint(infoF, info)
		fmt.Print(info)
		simple_util.CheckErr(infoF.Close())
		cmd := []string{
			filepath.Join("src", "gen_script_exon_CNV.pl"), infoPath, filepath.Join(exPath, workdir),
		}
		err = simple_util.RunCmd(perl, cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "plotExonCOV", Info)
	}
}

func plotCNVkit(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "CNVkit plot"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["plotCNVkit"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	script := filepath.Join("src", "gen_CNVkit_pic.pl")
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		workdir := filepath.Join("public", "geneCNVkit", tag, Info.Token)
		os.MkdirAll(workdir, 0755)
		info := r.FormValue("info")
		infoPath := filepath.Join(workdir, "info")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		fmt.Fprint(infoF, info)
		fmt.Print(info)
		simple_util.CheckErr(infoF.Close())
		cmd := []string{
			script, infoPath, filepath.Join(exPath, workdir),
		}
		err = simple_util.RunCmd(perl, cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "plotCNVkit", Info)
	}
}

func WGSlargeCNV(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "WGSlargeCNV"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["WGSlargeCNV"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "WGS_plot", Info.Token)
		os.MkdirAll(workdir, 0755)
		info := r.FormValue("info")
		infoPath := filepath.Join(workdir, "info")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		fmt.Fprint(infoF, info)
		fmt.Print(info)
		infoF.Close()
		cmd := []string{
			filepath.Join(exPath,"src","WGS_plot.sh"),
			r.FormValue("wgspath"),
			filepath.Join(workdir, "info"),
			workdir,
		}
		err = simple_util.RunCmd("bash", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)		
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "WGSlargeCNV", Info)
	}
}

func WESanno(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "WES annotation"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["WESanno"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		simple_util.CheckErr(r.ParseMultipartForm(32 << 20))
		logRequest(r)
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		workdir := filepath.Join("public", "wes_anno", tag, Info.Token)
		simple_util.CheckErr(os.MkdirAll(workdir, 0755))
		info := r.FormValue("info")
		sampleID := r.FormValue("sampleID")
		infoPath := filepath.Join(workdir, "HGMD")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		_, err = fmt.Fprint(infoF, info)
		simple_util.CheckErr(err)
		fmt.Print(info)
		simple_util.CheckErr(infoF.Close())
		cmd := []string{
			filepath.Join("src", "wes_anno.sh"), infoPath, sampleID,
		}
		err = simple_util.RunCmd("bash", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)		
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "WESanno", Info)
	}
}


func vcfanno(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "vcfanno"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["vcfanno"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "vcfanno", Info.Token)
		os.MkdirAll(workdir, 0755)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			log.Println(err)
			Info.Err = err.Error()
			t.Execute(w, Info)
			return
		}
		defer file.Close()
		f, err := os.Create(workdir + pSep + handler.Filename)
		simple_util.CheckErr(err)
		defer f.Close()
		io.Copy(f, file)
		cmd := []string{
			filepath.Join(exPath,"src","vcfanno.sh"),
			workdir + pSep + handler.Filename,
			r.FormValue("gender"),
		}
		err = simple_util.RunCmd("bash", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
	           http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "vcfanno", Info)
	}
}

func phoenix(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "phoenix"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["phoenix"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		//simple_util.CheckErr(r.ParseMultipartForm(32 << 20))
		logRequest(r)
		workdir := filepath.Join("public", "phoenix")
		//simple_util.CheckErr(os.MkdirAll(workdir, 0755))
		info := r.FormValue("info")
		chip := r.FormValue("chip")
		infoPath := filepath.Join(workdir, chip)
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		_, err = fmt.Fprint(infoF, info)
		simple_util.CheckErr(err)
		fmt.Print(info)
		simple_util.CheckErr(infoF.Close())
	} else {
		r.ParseForm() //暂时不支持get参数
		t.ExecuteTemplate(w, "phoenix", Info)
	}
}


func findfile(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Findfile"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["findfile"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		workdir := filepath.Join("public", "findfile", tag, Info.Token)
		os.MkdirAll(workdir, 0755)
		info := r.FormValue("info")
		infoPath := filepath.Join(workdir, "info")
		qc := r.Form["QC"][0]
		filetype := strings.Join(r.Form["filetype"],",")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		fmt.Fprint(infoF, info)
		fmt.Print(info,"\n")
		simple_util.CheckErr(infoF.Close())
		script := filepath.Join("src", "findfile.pl")
		var cmd = []string{
			script,
			"-list", infoPath,
			"-target", filepath.Join(exPath, workdir),
			"-QC", qc,
			"-filetype", filetype,
		}
		err = simple_util.RunCmd(perl, cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
	           http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		t.ExecuteTemplate(w, "findfile", Info)
	}
}

func Manual_Trio(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Manual_Trio"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["Manual_Trio"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		simple_util.CheckErr(r.ParseMultipartForm(32 << 20))
		logRequest(r)
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		workdir := filepath.Join("public", "Manual_Trio", tag, Info.Token)
		simple_util.CheckErr(os.MkdirAll(workdir, 0755))
		sampleID := r.FormValue("sampleID")
		info := r.FormValue("info")
		Q20 := r.FormValue("Q20")
		Q30 := r.FormValue("Q30")
		DEPTH := r.FormValue("DEPTH")
		COV20 := r.FormValue("COV20")
		QC := Q20 + "," + Q30 + "," + DEPTH + "," + COV20
		sample_Path := filepath.Join(workdir, "sampleID")
		infoF, err := os.Create(sample_Path)
		simple_util.CheckErr(err)
		_, err = fmt.Fprint(infoF, sampleID)  //往sample_Path里面写sampleID
		simple_util.CheckErr(err)
		fmt.Print(info)
		simple_util.CheckErr(infoF.Close())
		log.Printf("RunCmd:[%s] [%s] [%s] [%s] [%s]", perl, filepath.Join("src", "trio_family_manual_xgentic.pl"),sample_Path, filepath.Join(exPath, workdir),QC,info )
		var cmd = []string{
			filepath.Join("src", "trio_family_manual_xgentic.pl"), sample_Path, filepath.Join(exPath, workdir),QC,info,}
		err = simple_util.RunCmd(perl , cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, filepath.Join("public", "Manual_Trio", tag, Info.Token), http.StatusSeeOther)  //"public", "Manual_Trio"都是指向工作目录的
		}
	} else {
		t.ExecuteTemplate(w, "Manual_Trio", Info)
	}
}

func kinship(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Kinship"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["kinship"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		workdir := filepath.Join("public", "kinship", Info.Token)
		os.MkdirAll(workdir, 0755)
		info := r.FormValue("info")
		infoPath := filepath.Join(workdir, "info")
		infoF, err := os.Create(infoPath)
		simple_util.CheckErr(err)
		fmt.Fprint(infoF, info)
		fmt.Print(info,"\n")
		simple_util.CheckErr(infoF.Close())
		script := filepath.Join("src", "kinship.py")
		var cmd = []string{
			script, infoPath, filepath.Join(exPath, workdir),}
		err = simple_util.RunCmd("python", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, filepath.Join(workdir,  "kinship"), http.StatusSeeOther)
		}
	} else {
		t.ExecuteTemplate(w, "kinship", Info)
	}
}

func triploid(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Kinship"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["triploid"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		path := r.FormValue("path")
		workdir := filepath.Join("public", "triploid", Info.Token)
		os.MkdirAll(workdir, 0755)
		var cmd = []string{
			"src/triploid.sh",
			path,
			workdir,
		}
		err = simple_util.RunCmd("bash", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		t.ExecuteTemplate(w, "triploid", Info)
	}
}

func contamination(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Kinship"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["contamination"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		path := r.FormValue("path")
		workdir := filepath.Join("public", "contamination", Info.Token)
		os.MkdirAll(workdir, 0755)
		var cmd = []string{
			"src/contamination.sh",
			path,
			workdir,
		}
		err = simple_util.RunCmd("bash", cmd...)
		if err != nil {
			log.Println(cmd)
			log.Println(err)
		} else {
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		t.ExecuteTemplate(w, "contamination", Info)
	}
}

func Drug(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Drug"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["new"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		//new function
	} else {
		t.ExecuteTemplate(w, "Drug", Info)
	}
}


func new(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html" , templatePath + "toolkit.html")
	simple_util.CheckErr(err)
	var Info Infos
	Info.Title = "Kinship"
	Info.Token = createToken()
	Info.User,Info.Permission = getUser(r)
	if !get_permission(r,Permission["new"]) {
		fmt.Fprintf(w, "<script>alert('无权使用此网页');window.location.href = '/';</script>")
		return
	}
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		//new function
	} else {
		t.ExecuteTemplate(w, "new", Info)
	}
}

