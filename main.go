package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
)

var (
	port = flag.String(
		"port",
		":9091",
		"web server listen port",
	)
)

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
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		Path := r.URL.Path
		path := fmt.Sprintf("%s", Path)
		fmt.Println(Path)
		//		if Path[len(Path)-1] == '/' {
		//			http.ServeFile(w, r, "public/")
		//		} else {
		http.ServeFile(w, r, "public/"+path)
		//		}

	}) //设置访问的路由
	fmt.Println("start")
	err := http.ListenAndServe(*port, nil) //设置监听的端口
	if err != nil {
		log.Fatal(err)
	}
}
