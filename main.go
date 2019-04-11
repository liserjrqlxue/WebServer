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
	http.HandleFunc("/autoReport", autoReport)
	http.HandleFunc("/datatables", datatables)
	http.HandleFunc("/plotReadsLocal", plotReadsLocal)
	http.HandleFunc("/upload", upload)

	StaticDir["/static"] = "static"
	StaticDir["/public"] = "public"
	StaticDir["/ajax"] = "ajax"

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
		sayhelloName(w, r)
	}) //设置访问的路由
	fmt.Printf("start http://localhost%v\n", *port)
	err := http.ListenAndServe(*port, nil) //设置监听的端口
	if err != nil {
		log.Fatal(err)
	}
}
