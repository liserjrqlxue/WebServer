package main

import (
	"archive/zip"
	"crypto/md5"
	"fmt"
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
		zipfile, err := os.Open(file)
		if err != nil {
			return err
		}
		defer zipfile.Close()

		// Get the file information
		info, err := zipfile.Stat()
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
		header.SetModTime(header.ModTime().Add(time.Duration(28800 * 1e9)))

		writer, err := zipWriter.CreateHeader(header)
		if err != nil {
			return err
		}
		_, err = io.Copy(writer, zipfile)
		if err != nil {
			return err
		}
	}
	return nil
}

func errPrint(w http.ResponseWriter, err error) {
	log.Println(err)
	fmt.Fprint(w, "<p>")
	fmt.Fprint(w, err)
	fmt.Fprint(w, "<p>")
}

// 处理/upload3 逻辑
func upload3(w http.ResponseWriter, r *http.Request) {
	log.Println("method:", r.Method) //获取请求的方法
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			log.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./test/" + newName + suffix
			if _, err := os.Stat(saveFileName); err == nil {
				log.Println(saveFileName + " 已存在，删除")
				err = os.Remove(saveFileName)
				if err != nil {
					errPrint(w, err)
				}
			}
			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666) // 此处假设当前目录下已存在test目录
			if err != nil {
				log.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("python", "../report.batch.py", saveFileName, "public")
				out, err := cmd.CombinedOutput()
				if err != nil {
					log.Println(err)
					log.Printf("%s", out)
					fmt.Fprint(w, "<p>")
					fmt.Fprintf(w, "<p><pre>%s</pre></p>", out)
				} else {
					fmt.Fprint(w, "<p>create report done:</p>")
					outs := strings.Split(string(out), "\n")
					for i := range outs {
						log.Println(outs[i])
						if strings.HasSuffix(outs[i], "docx") {
							fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", outs[i], outs[i])
						} else {
							fmt.Fprintf(w, "<p>%s</p>", outs[i])
						}
					}
				}
			}
		}
	}
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/upload3.gtpl")
	t.Execute(w, token)
}

// 处理/upload2debug 逻辑
func upload2debug(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method) //获取请求的方法
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			fmt.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./public/kindey/input/" + newName + suffix
			if _, err := os.Stat(saveFileName); err == nil {
				fmt.Println(saveFileName + "已存在，删除")
				err = os.Remove(saveFileName)
				if err != nil {
					errPrint(w, err)
				}
			}
			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666) // 此处假设当前目录下已存在test目录
			if err != nil {
				fmt.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("python", "../kindey/report.single.py", saveFileName, "public/kindey/output")
				out, err := cmd.CombinedOutput()
				if err != nil {
					fmt.Println(err)
					fmt.Printf("%s", out)
					fmt.Fprint(w, "<p>")
					fmt.Fprintf(w, "<p><pre>%s</pre></p>", out)
				} else {
					fmt.Fprint(w, "<p>create report done:</p>")
					outs := strings.Split(string(out), "\n")
					for i := range outs {
						fmt.Println(outs[i])
						if strings.HasSuffix(outs[i], "docx") {
							fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", outs[i], filepath.Base(outs[i]))
						} else {
							fmt.Fprintf(w, "<p>%s</p>", outs[i])
						}
					}
				}
			}
		}
	}
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/upload2debug.gtpl")
	t.Execute(w, token)
}

// 处理/upload2 逻辑
func upload2(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method) //获取请求的方法
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/upload2.gtpl")
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			t.Execute(w, token)
			fmt.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./public/kindey/input/" + newName + suffix
			if _, err := os.Stat(saveFileName); err == nil {
				fmt.Println(saveFileName + "已存在，删除")
				err = os.Remove(saveFileName)
				if err != nil {
					t.Execute(w, token)
					errPrint(w, err)
				}
			}
			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666) // 此处假设当前目录下已存在test目录
			if err != nil {
				t.Execute(w, token)
				fmt.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("/share/udata/wangyaoshen/local/bin/python", "../kindey/report.single.pyc", saveFileName, "public/kindey/output")
				out, err := cmd.CombinedOutput()
				if err != nil {
					t.Execute(w, token)
					fmt.Println(err)
					fmt.Printf("%s", out)
					fmt.Fprint(w, "<p>")
					fmt.Fprintf(w, "<p><pre>%s</pre></p>", out)
				} else {
					t.Execute(w, token)
					fmt.Fprint(w, "<p>create report done:</p>")
					outs := strings.Split(string(out), "\n")
					for i := range outs {
						fmt.Println(outs[i])
						if strings.HasSuffix(outs[i], "docx") {
							fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", outs[i], filepath.Base(outs[i]))
						} else {
							fmt.Fprintf(w, "<p>%s</p>", outs[i])
						}
					}
				}
			}
		}
	} else {
		t.Execute(w, token)
	}
}

// 处理/upload 逻辑
func upload(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method) //获取请求的方法
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			fmt.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./test/" + newName + suffix

			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666) // 此处假设当前目录下已存在test目录
			if err != nil {
				fmt.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("python", "../report.py", saveFileName, "public")
				out, err := cmd.Output()
				if err != nil {
					fmt.Println(err)
					fmt.Println(out)
					fmt.Fprint(w, "<p>")
					fmt.Fprint(w, err)
					fmt.Fprint(w, "</p>")
				} else {
					fmt.Fprint(w, "<p>create report done:</p>")
					outs := strings.Split(string(out), "\n")
					for i := range outs {
						fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", outs[i], outs[i])
					}
				}
			}
		}
	}
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/upload.gtpl")
	t.Execute(w, token)
}

// 处理/pre_pregnancy 逻辑
func pre_pregnancy(w http.ResponseWriter, r *http.Request) {
	log.Println("method:", r.Method) //获取请求的方法
	reporType := "pre_pregnancy"
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			log.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./public/" + reporType + "/input/" + newName + suffix
			if _, err := os.Stat(saveFileName); err == nil {
				log.Println(saveFileName + "已存在，删除")
				err = os.Remove(saveFileName)
				if err != nil {
					errPrint(w, err)
				}
			}
			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666)
			if err != nil {
				log.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("python3", "../"+reporType+"/auto_report.py", "--data-file", saveFileName, "--out-dir", "public/"+reporType+"/output")
				out, err := cmd.CombinedOutput()
				if err != nil {
					log.Println(err)
					log.Printf("%s", out)
					fmt.Fprint(w, "<p>")
					fmt.Fprintf(w, "<p><pre>%s</pre></p>", out)
				} else {
					fmt.Fprint(w, "<p>create report done:</p>")
				}
				outs := strings.Split(string(out), "\n")
				var files = []string{}
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
						//fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", "public/"+reporType+"/output/"+filepath.Base(outs[i]), filepath.Base(outs[i]))
						files = append(files, "public/"+reporType+"/output/"+filepath.Base(outs[i]))
					} else {
						//fmt.Fprintf(w, "<p>%s</p>", outs[i])
					}
				}
				output := "报告-" + filename + "-" + time.Now().Format("20060102") + "-" + sampleNum + "_" + reportNum + ".zip"
				err = ZipFiles("public/"+reporType+"/output/"+output, files)
				if err != nil {
					log.Println(err)
					fmt.Fprintf(w, "<p>%s</p>", err)
					fmt.Fprint(w, "<p>zip file fail!</p>")
				} else {
					fmt.Fprintf(w, "<p>打包</p><a href='%s' target='_blank'>%s</a><br/>", "public/"+reporType+"/output/"+output, output)
				}
			}
		}
	}
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/pre_pregnancy.gtpl")
	t.Execute(w, token)
}

// 处理/multi_center 逻辑
func multi_center(w http.ResponseWriter, r *http.Request) {
	fmt.Println("method:", r.Method) //获取请求的方法
	reporType := "multi_center"
	if r.Method == "POST" {
		r.ParseMultipartForm(32 << 20)
		file, handler, err := r.FormFile("uploadfile")
		if err != nil {
			fmt.Println(err)
			fmt.Fprint(w, "<p>")
			fmt.Fprint(w, err)
			fmt.Fprint(w, "</p>")
		} else {
			defer file.Close()
			//fmt.Fprintf(w, "%v", handler.Header)
			uploadFileName := handler.Filename
			suffix := filepath.Ext(uploadFileName)
			filename := strings.TrimRight(uploadFileName, suffix)
			newName := md5sum(filename)
			saveFileName := "./public/" + reporType + "/input/" + newName + suffix
			if _, err := os.Stat(saveFileName); err == nil {
				fmt.Println(saveFileName + "已存在，删除")
				err = os.Remove(saveFileName)
				if err != nil {
					errPrint(w, err)
				}
			}
			f, err := os.OpenFile(saveFileName, os.O_WRONLY|os.O_CREATE, 0666)
			if err != nil {
				fmt.Println(err)
				fmt.Fprint(w, "<p>")
				fmt.Fprint(w, err)
				fmt.Fprint(w, "</p>")
			} else {
				defer f.Close()
				io.Copy(f, file)
				cmd := exec.Command("python3", "../pre_pregnancy/auto_report_dzx.py", "--data-file", saveFileName, "--out-dir", "public/"+reporType+"/output")
				out, err := cmd.CombinedOutput()
				if err != nil {
					fmt.Println(err)
					fmt.Printf("%s", out)
					fmt.Fprint(w, "<p>")
					fmt.Fprintf(w, "<p><pre>%s</pre></p>", out)
				} else {
					fmt.Fprint(w, "<p>create report done:</p>")
				}
				outs := strings.Split(string(out), "\n")
				var files = []string{}
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
					fmt.Println(outs[i])
					match1 := reg1.FindStringSubmatch(outs[i])
					match2 := reg2.FindStringSubmatch(outs[i])
					if match1 != nil {
						sampleNum = match1[1]
					}
					if match2 != nil {
						reportNum = match2[1]
					}
					if strings.HasSuffix(outs[i], "docx") || strings.HasSuffix(outs[i], "zip") || strings.HasSuffix(outs[i], "xlsx") {
						//fmt.Fprintf(w, "<a href='%s' target='_blank'>%s</a><br/>", "public/"+reporType+"/output/"+filepath.Base(outs[i]), filepath.Base(outs[i]))
						files = append(files, "public/"+reporType+"/output/"+filepath.Base(outs[i]))
					} else {
						//fmt.Fprintf(w, "<p>%s</p>", outs[i])
					}
				}
				output := "报告-" + filename + "-" + time.Now().Format("20060102") + "-" + sampleNum + "_" + reportNum + ".zip"
				err = ZipFiles("public/"+reporType+"/output/"+output, files)
				if err != nil {
					fmt.Println(err)
					fmt.Fprintf(w, "<p>%s</p>", err)
					fmt.Fprint(w, "<p>zip file fail!</p>")
				} else {
					fmt.Fprintf(w, "<p>打包</p><a href='%s' target='_blank'>%s</a><br/>", "public/"+reporType+"/output/"+output, output)
				}
			}
		}
	}
	crutime := time.Now().Unix()
	h := md5.New()
	io.WriteString(h, strconv.FormatInt(crutime, 10))
	token := fmt.Sprintf("%x", h.Sum(nil))
	t, _ := template.ParseFiles("template/multi_center.gtpl")
	t.Execute(w, token)
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
	fmt.Fprintf(w, "Hello astaxie!") //这个写入到w的是输出到客户端的
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
