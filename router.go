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
	"path"
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

func md5sum(str string) string {
	byteStr := []byte(str)
	sum := md5.Sum(byteStr)
	sumStr := fmt.Sprintf("%x", sum)
	return sumStr
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

var typeMap = map[string]string{
	"hw":            "report.py/pre_pregnancy/auto_report_hw.py",
	"wgs":           "report.py/pre_pregnancy/auto_report_wgs.py",
	"pre_pregnancy": "report.py/pre_pregnancy/auto_report.py",
	"multi_center":  "report.py/pre_pregnancy/auto_report_dzx.py",
}

type reportInfo struct {
	Option  string
	Token   string
	Err     string
	Message string
	Href    string
}

func reportErr(err error, w http.ResponseWriter, t *template.Template, info reportInfo) bool {
	if err != nil {
		log.Println(err)
		info.Err = fmt.Sprint(err)
		t.Execute(w, info)
		return true
	}
	return false
}

// 处理/autoReport 逻辑
func autoReport(w http.ResponseWriter, r *http.Request) {
	var info reportInfo
	t, err := template.ParseFiles(templatePath + "autoReport.gtpl")
	if reportErr(err, w, t, info) {
		return
	}
	log.Println("method:", r.Method) //获取请求的方法

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)
		info.Option = r.FormValue("type")
		info.Token = r.FormValue("token")

		file, handler, err := r.FormFile("uploadfile")
		if reportErr(err, w, t, info) {
			return
		}
		defer simple_util.DeferClose(file)

		info.Token = r.FormValue("token")
		info.Option = r.FormValue("type")

		reportFile := typeMap[info.Option]
		inputDir := path.Join("public", info.Option, "input")
		outputDir := path.Join("public", info.Option, "output")
		err = os.MkdirAll(inputDir, 0755)
		if reportErr(err, w, t, info) {
			return
		}
		err = os.MkdirAll(outputDir, 0755)
		if reportErr(err, w, t, info) {
			return
		}

		//fmt.Fprintf(w, "%v", handler.Header)
		uploadFileName := handler.Filename
		suffix := filepath.Ext(uploadFileName)
		filename := strings.TrimRight(uploadFileName, suffix)
		newName := md5sum(filename)
		saveFileName := path.Join(inputDir, newName+suffix)
		if _, err := os.Stat(saveFileName); err == nil {
			log.Println(saveFileName + "已存在，删除")
			err = os.Remove(saveFileName)
			if reportErr(err, w, t, info) {
				return
			}
		}
		f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666)
		if reportErr(err, w, t, info) {
			return
		}

		defer f.Close()
		io.Copy(f, file)
		cmd := exec.Command("python3", reportFile, "--data-file", saveFileName, "--out-dir", outputDir)
		out, err := cmd.CombinedOutput()
		info.Message = fmt.Sprintf("%s\n", out)
		if reportErr(err, w, t, info) {
			return
		}
		info.Message = info.Message + "create report done\n"

		outs := strings.Split(string(out), "\n")
		var files []string
		sampleNum := "NA"
		reportNum := "NA"
		p1 := `number of samples (\d+)`
		p2 := `number of reports (\d+)`
		ph := `final.result-`
		pe := `_BB.*`
		reg1 := regexp.MustCompile(p1)
		reg2 := regexp.MustCompile(p2)
		regh := regexp.MustCompile(ph)
		rege := regexp.MustCompile(pe)
		filename = regh.ReplaceAllString(filename, "")
		filename = rege.ReplaceAllString(filename, "_BB")
		for i := range outs {
			log.Println(outs[i])
			match1 := reg1.FindStringSubmatch(outs[i])
			match2 := reg2.FindStringSubmatch(outs[i])
			if match1 != nil {
				sampleNum = match1[1]
			}
			if match2 != nil {
				reportNum = match2[1]
			}
			if strings.HasSuffix(outs[i], "docx") || strings.HasSuffix(outs[i], "zip") || strings.HasSuffix(outs[i], "xlsx") {
				files = append(files, path.Join(outputDir, filepath.Base(outs[i])))
			}
		}
		output := "报告-" + filename + "-" + time.Now().Format("20060102") + "-" + sampleNum + "_" + reportNum + ".zip"
		err = ZipFiles(path.Join(outputDir, output), files)
		if err != nil {
			info.Message = info.Message + "<p>zip file fail!</p>"
			reportErr(err, w, t, info)
			return
		}
		info.Href = path.Join(outputDir, output)
		info.Message = info.Message + output
	} else {
		r.ParseForm()
		crutime := time.Now().Unix()
		h := md5.New()
		io.WriteString(h, strconv.FormatInt(crutime, 10))
		token := fmt.Sprintf("%x", h.Sum(nil))
		info.Token = token
		info.Option = r.FormValue("type")
	}
	t.Execute(w, info)
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
	//fmt.Fprintf(w, "Hello World!") //这个写入到w的是输出到客户端的
	t, err := template.ParseFiles(templatePath + "index.gtpl")
	if err != nil {
		fmt.Fprint(w, err)
		return
	}
	t.Execute(w, nil)
}

func logRequest(r *http.Request) {
	fmt.Println(r.Form) //这些信息是输出到服务器端的打印信息
	fmt.Println("path", r.URL.Path)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Printf("key:%s\t", k)
		if len(v) < 1024 {
			fmt.Printf("key:[%s]\tval:[%v]\n", k, v)
		} else {
			fmt.Printf("key:[%s]\tval: large data!\n", k)
		}
	}
}

func login(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()                    //解析url传递的参数，对于POST则解析响应包的主体（request body）
	fmt.Println("method:", r.Method) //获取请求的方法
	if r.Method == "GET" {
		t, _ := template.ParseFiles("template/login.gtpl")
		log.Println(t.Execute(w, nil))
	} else {
		//请求的是登录数据，那么执行登录的逻辑判断
		fmt.Println("username:", r.Form["username"])
		fmt.Println("password:", r.Form["password"])
	}
}

func datatables(w http.ResponseWriter, r *http.Request) {
	t, err := template.ParseFiles(templatePath + "datatables.gtpl")
	simple_util.CheckErr(err)
	t.Execute(w, nil)
}

type Img struct {
	Img   string
	Src   string
	Token string
}

func plotReadsLocal(w http.ResponseWriter, r *http.Request) {

	t, err := template.ParseFiles(templatePath + "plotReadsLocal.gtpl")
	simple_util.CheckErr(err)
	log.Println("method:", r.Method)

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)

		if len(r.Form["prefix"]) == 0 {
			r.Form["prefix"] = append(r.Form["prefix"], "prefix")
		}
		if r.Form["position"][0] != "at" && len(r.Form["End"]) > 0 {
			r.Form["Start"][0] = r.Form["Start"][0] + r.Form["position"][0] + r.Form["End"][0]
		}
		// token
		crutime := time.Now().Unix()
		token := md5sum(strconv.FormatInt(crutime, 10))
		fmt.Printf("token:\t%v\n", token)
		var img Img
		img.Token = token
		img.Src = "/public/plotReadsLocal/" + r.Form["prefix"][0] + token + "_" + r.Form["chr"][0] + "_" + r.Form["Start"][0] + ".png"
		img.Img = r.Form["prefix"][0] + token + "_" + r.Form["chr"][0] + "_" + r.Form["Start"][0] + ".png"
		simple_util.RunCmd(
			"/share/backup/wangyaoshen/perl5/perlbrew/perls/perl-5.26.2/bin/perl",
			"/ifs7/B2C_SGD/PROJECT/web_reads_picture/bin/plotreads.sz.pl",
			"-Rs", "/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/Rscript",
			"-b", r.Form["path"][0],
			"-c", r.Form["chr"][0],
			"-p", r.Form["Start"][0], "-r",
			"-prefix", "public/plotReadsLocal/"+r.Form["prefix"][0]+token,
			"-f", "20", "-d", "-a", "-l", r.Form["Plotread_Length"][0],
		)
		t.Execute(w, img)
	} else {
		r.ParseForm()
		logRequest(r)
		t.Execute(w, nil)
	}
}
