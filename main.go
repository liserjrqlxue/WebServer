package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
)

var (
	port = flag.String(
		"port",
		":9091",
		"web server listen port",
	)
)

var StaticDir = make(map[string]string)

func main() {
	flag.Parse()
	// 设置访问的路由
	http.HandleFunc("/login", login)
	http.HandleFunc("/upload", upload)
	http.HandleFunc("/upload2", upload2)
	http.HandleFunc("/upload2debug", upload2debug)
	http.HandleFunc("/upload3", upload3)
	http.HandleFunc("/pp2docx", pre_pregnancy)
	http.HandleFunc("/mc2docx", multi_center)
	http.HandleFunc("/wgs2docx", wgs_docx)

	StaticDir["/static"] = "static"
	StaticDir["/public"] = "../public"

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// static file server
		for prefix, staticDir := range StaticDir {
			if strings.HasPrefix(r.URL.Path, prefix) {
				file := staticDir + r.URL.Path[len(prefix):]
				fmt.Println(file)
				http.ServeFile(w, r, file)
				return
			}
		}
	}) //设置访问的路由
	fmt.Println("start")
	err := http.ListenAndServe(*port, nil) //设置监听的端口
	if err != nil {
		log.Fatal(err)
	}
}
