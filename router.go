package main

import (
	"archive/zip"
	"crypto/md5"
	"encoding/json"
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

func reportErr(err error, w http.ResponseWriter, t *template.Template, info Infos) bool {
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
	var info Infos
	info.Token = createToken()

	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"autoReport.html")
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
		info.Option = r.FormValue("type")
	}
	t.ExecuteTemplate(w, "autoReport", info)
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
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"index.html")
	if err != nil {
		fmt.Fprint(w, err)
		return
	}

	var Info Infos
	Info.Title = "Home Page"
	Info.Token = createToken()
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

var plotReadsLocalDir = "public" + pSep + "plotReadsLocal"
var plotScript = "src" + pSep + "plotreads.sz.pl"

var perl = "/share/backup/wangyaoshen/perl5/perlbrew/perls/perl-5.26.2/bin/perl"

func plotReadsLocal(w http.ResponseWriter, r *http.Request) {
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"plotReadsLocal.html")
	simple_util.CheckErr(err)

	var Info Infos
	Info.Title = "本地集群画reads图"
	Info.Token = createToken()

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
		err := os.MkdirAll(plotReadsLocalDir+pSep+tag, 0755)
		simple_util.CheckErr(err)

		pngPrefix := prefix + "_" + Info.Token
		pngSuffix := "_" + r.Form["chr"][0] + "_" + r.Form["Start"][0] + ".png"
		pngName := pngPrefix + pngSuffix
		Info.Src = tag + "/" + pngName
		Info.Img = pngName
		var cmd = []string{
			plotScript,
			"-Rs", "/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/Rscript",
			"-b", r.Form["path"][0],
			"-c", r.Form["chr"][0],
			"-p", r.Form["Start"][0], "-r",
			"-prefix", plotReadsLocalDir + pSep + tag + pSep + pngPrefix,
			"-f", "20", "-d", "-a", "-l", r.Form["Plotread_Length"][0],
		}
		log.Println(perl, cmd)
		simple_util.RunCmd(perl, cmd...)
	} else {
		r.ParseForm()
		logRequest(r)
	}
	t.ExecuteTemplate(w, "plotReadsLocal", Info)
}

type PlotInfo struct {
	SampleID string   `json:"sample_name"`
	Bam      string   `json:"bam_path"`
	Variants []string `json:"variants"`
}

func plotMultiReadsLocal(w http.ResponseWriter, r *http.Request) {
	t, err := template.ParseFiles(templatePath+"header.html", templatePath+"footer.html", templatePath+"plotMultiReadsLocal.html")
	simple_util.CheckErr(err)

	var Info Infos
	Info.Title = "本地集群画reads图"
	Info.Token = createToken()

	log.Println("method:", r.Method)
	if r.Method == "POST" {
		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)
		var plotInfo PlotInfo
		decoder := json.NewDecoder(r.Body)
		decoder.Decode(&plotInfo)
		sampleID := plotInfo.SampleID
		bam := plotInfo.Bam
		variants := plotInfo.Variants
		pngPrefix := sampleID + "_" + Info.Token
		var varUrl []string
		for _, variant := range variants {
			item := strings.Split(variant, "-")
			if len(item) < 3 {
				varUrl = append(varUrl, "error!")
				fmt.Fprintf(w, "<h1>ERROR:<h1>\n<p>variant:%s can not parser!</p>\n", variant)
			} else {
				chr := item[0]
				start := item[1]
				stop := item[2]
				position := start
				if len(item) >= 5 {
					ref := item[3]
					alt := item[4]
					p1, err1 := strconv.Atoi(start)
					p2, err2 := strconv.Atoi(stop)
					if err1 == nil && err2 == nil {
						if p2-p1 == 1 && len(ref) == 1 && len(alt) == 1 {
						} else if ref == "." || len(alt) > 1 {
							position = start + "in" + stop
						} else {
							position = start + "to" + stop
						}
					}
				}
				pngSuffix := "_" + chr + "_" + position + ".png"
				varUrl = append(varUrl, pngPrefix+pngSuffix)
				var cmd = []string{
					plotScript,
					"-Rs", "/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/Rscript",
					"-b", bam,
					"-c", chr,
					"-p", position, "-r",
					"-prefix", plotReadsLocalDir + pSep + tag + pSep + pngPrefix,
					"-f", "20", "-d", "-a", "-l", "100",
				}
				log.Println(perl, cmd)
				simple_util.RunCmd(perl, cmd...)
				fmt.Fprintf(w, "<p>%s</p>\n<img src=\"%s\">%s</img>\n", pngPrefix+pngSuffix, tag+"/"+pngPrefix+pngSuffix, tag+"/"+pngPrefix+pngSuffix)
			}
		}
	} else {
		r.ParseForm()
		logRequest(r)
		t.ExecuteTemplate(w, "plotMultiReadsLocal", Info)
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

func fixHemi(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)

	var Info Infos
	Info.Title = "Hemi修復"
	Info.Token = createToken()

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		simple_util.CheckErr(err)
		defer file.Close()
		//fmt.Fprintf(w, "%v", handler.Header)
		f, err := os.Create("public" + pSep + handler.Filename)
		simple_util.CheckErr(err)
		defer f.Close()
		io.Copy(f, file)
		cmd := []string{
			"-input", "public" + pSep + handler.Filename,
			"-gender", r.FormValue("gender"),
			"-output", "public" + pSep + handler.Filename + "." + r.FormValue("gender") + ".xlsx",
		}
		simple_util.RunCmd(
			exPath+pSep+"hemiFix.exe", cmd...,
		)
		Info.Href = "/public/" + handler.Filename + "." + r.FormValue("gender") + ".xlsx"
		Info.Message = "Download"
	}
	t, err := template.ParseFiles(templatePath + "fixHemi.html")
	simple_util.CheckErr(err)
	t.Execute(w, Info)
}

func filterExcel(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)
	t, err := template.ParseFiles(templatePath + "filterExcel.html")
	simple_util.CheckErr(err)

	var Info Infos
	Info.Title = "filter Excel"
	Info.Token = createToken()

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			log.Println(err)
			Info.Err = err.Error()
			t.Execute(w, Info)
			return
		}
		defer file.Close()
		//fmt.Fprintf(w, "%v", handler.Header)
		f, err := os.Create("public" + pSep + handler.Filename)
		simple_util.CheckErr(err)
		defer f.Close()
		io.Copy(f, file)
		cmd := []string{
			"-input", "public" + pSep + handler.Filename,
			"-gene", "gene.list",
			"-output", "public" + pSep + handler.Filename + ".filter.xlsx",
		}
		log.Println(
			simple_util.RunCmd(
				exPath+pSep+"filterExcel", cmd...,
			),
		)
		Info.Href = "/public/" + handler.Filename + ".filter.xlsx"
		Info.Message = "Download"
	}
	t.Execute(w, Info)
}

func plotExonCnv(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)

	var Info Infos
	Info.Title = "exon cnv plot"
	Info.Token = createToken()

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
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
		err = simple_util.RunCmd(perl, filepath.Join("src", "gen_script_exon_CNV.pl"), infoPath, filepath.Join(exPath, workdir))
		if err != nil {
			fmt.Fprintln(w, "CMD:", perl, filepath.Join("src", "gen_script_exon_CNV.pl"), infoPath, filepath.Join(exPath, workdir))
			fmt.Fprintf(w, "Error:\n\t%+v\n", err)
			log.Println(err)
		} else {
			http.Redirect(w, r, strings.Join([]string{"public", "exome_cnv", tag, Info.Token}, "/"), http.StatusSeeOther)
		}
	} else {
		t, err := template.ParseFiles(templatePath + "plotExonCnv.html")
		simple_util.CheckErr(err)
		t.Execute(w, Info)
	}
}

func genCNVkit(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)

	var Info Infos
	Info.Title = "CNVkit plot"
	Info.Token = createToken()

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
		err = simple_util.RunCmd(perl, script, infoPath, filepath.Join(exPath, workdir))
		if err != nil {
			fmt.Fprintln(w, "CMD:", perl, script, infoPath, filepath.Join(exPath, workdir))
			fmt.Fprintf(w, "Error:\n\t%+v\n", err)
			log.Println(err)
		} else {
			//http.Redirect(w, r, strings.Join([]string{"public", "genCNVkit", tag, Info.Token}, "/"), http.StatusSeeOther)
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		t, err := template.ParseFiles(templatePath + "plotExonCnv.html")
		simple_util.CheckErr(err)
		t.Execute(w, Info)
	}
}

func WESanno(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)

	var Info Infos
	Info.Title = "WES annotation"
	Info.Token = createToken()

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
		log.Printf("RunCmd:[%s] [%s] [%s] [%s]", "bash", filepath.Join("src", "wes_anno.sh"), infoPath, sampleID)
		err = simple_util.RunCmd("bash", filepath.Join("src", "wes_anno.sh"), infoPath, sampleID)
		if err != nil {
			fmt.Fprintln(w, "CMD:", "bash", filepath.Join("src", "wes_anno.sh"), infoPath, sampleID)
			fmt.Fprintf(w, "Error:\n\t%+v\n", err)
			log.Println(err)
		} else {
			http.Redirect(w, r, filepath.Join("public", "wes_anno", tag, Info.Token), http.StatusSeeOther)
		}
	} else {
		t, err := template.ParseFiles(templatePath + "WESanno.html")
		simple_util.CheckErr(err)
		simple_util.CheckErr(t.Execute(w, Info))
	}
}

func plotCNVkit(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method)

	var Info Infos
	Info.Title = "plot CNVkit"
	Info.Token = createToken()

	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		logRequest(r)

		script := filepath.Join("src", "run_CNVkit_plot.sh")

		y, m, _ := time.Now().Date()
		tag := fmt.Sprintf("%d-%v", y, m)

		workdir := filepath.Join("public", "CNVkit", tag, Info.Token)
		os.MkdirAll(workdir, 0755)

		workDir := r.FormValue("workdir")
		sampleID := r.FormValue("sampleID")
		region := r.FormValue("region")
		regions := sep.Split(region, -1)
		var args = append([]string{script, sampleID, workDir, workdir}, regions...)

		err := simple_util.RunCmd("bash", args...)
		if err != nil {
			fmt.Fprintln(w, "CMD:", "bash", args)
			fmt.Fprintf(w, "Error:\n\t%+v\n", err)
			log.Println(err)
		} else {
			//http.Redirect(w, r, strings.Join([]string{"public", "CNVkit", tag, Info.Token}, "/"), http.StatusSeeOther)
			http.Redirect(w, r, workdir, http.StatusSeeOther)
		}
	} else {
		t, err := template.ParseFiles(templatePath + "plotCNVkit.html")
		simple_util.CheckErr(err)
		t.Execute(w, Info)
	}
}
