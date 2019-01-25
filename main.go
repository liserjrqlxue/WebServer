package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	// Files to Zip
	files := []string{"example.csv", "data.csv"}
	output := "done.zip"

	err := ZipFiles(output, files)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Zipped File: " + output)
	http.HandleFunc("/login", login) //设置访问的路由
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
	//http.HandleFunc("/", sayhelloName)         //设置访问的路由
	fmt.Println("start")
	err = http.ListenAndServe(":9091", nil) //设置监听的端口
	if err != nil {
		log.Fatal(err)
	}
}
