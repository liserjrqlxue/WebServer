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
var Permission = make(map[string]string)

func main() {
	flag.Parse()
	// 设置访问的路由
	//http.HandleFunc("/Web_url_name", func_name)
	http.HandleFunc("/login", login)
	http.HandleFunc("/plotReadsLocal", plotReadsLocal)
	http.HandleFunc("/filterExcel", filterExcel)
	http.HandleFunc("/filterKDNY", filterKDNY)
	http.HandleFunc("/filterInfertility", filterInfertility)
	http.HandleFunc("/BamExtractor",BamExtractor)
	http.HandleFunc("/ExomeDepthplot",ExomeDepthplot)
	http.HandleFunc("/plotExonCOV", plotExonCOV)
	http.HandleFunc("/WESanno", WESanno)
	http.HandleFunc("/plotCNVkit", plotCNVkit)
	http.HandleFunc("/findfile",findfile)
	http.HandleFunc("/Manual_Trio",Manual_Trio)
	http.HandleFunc("/phoenix",phoenix)
	http.HandleFunc("/kinship",kinship)
	http.HandleFunc("/vcfanno",vcfanno)
	http.HandleFunc("/WGSlargeCNV",WGSlargeCNV)
	http.HandleFunc("/triploid",triploid)
	http.HandleFunc("/contamination",contamination)
	http.HandleFunc("/qingdaoWGS",qingdaoWGS)
	http.HandleFunc("/drug_report",drug_report)
	http.HandleFunc("/thalassemia_report",thalassemia_report)
	http.HandleFunc("/deaf_report",deaf_report)
	http.HandleFunc("/changsha_deaf",changsha_deaf)
	http.HandleFunc("/tianjin_deaf",tianjin_deaf)
	http.HandleFunc("/shenzhen_deaf",shenzhen_deaf)
	http.HandleFunc("/shenzhen_thalassemia",shenzhen_thalassemia)
	http.HandleFunc("/Nifty3",Nifty3)

	StaticDir["/static"] = "static"
	StaticDir["/public"] = "public"
	//StaticDir["/ajax"] = "ajax"
	
	Permission["plotReadsLocal"] = "wes,wgs"
	Permission["filterExcel"] = "wes"
	Permission["filterKDNY"] = "wes"
	Permission["filterInfertility"] = "wes"
	Permission["BamExtractor"] = "wes,wgs"
	Permission["ExomeDepthplot"] = "wes"
	Permission["plotExonCOV"] = "wes"
	Permission["WESanno"] = ""
	Permission["plotCNVkit"] = "wes"
	Permission["findfile"] = "wes"
	Permission["Manual_Trio"] = "wes"
	Permission["phoenix"] = ""
	Permission["kinship"] = "wes"
	Permission["vcfanno"] = ""
	Permission["WGSlargeCNV"] = "wgs"
	Permission["triploid"] = ""
	Permission["contamination"] = ""
	Permission["qingdaoWGS"] = "wgs"
	Permission["drug_report"] = ""
	Permission["thalassemia_report"] = ""
	Permission["deaf_report"] = ""
	Permission["changsha_deaf"] = "changsha_deaf"
	Permission["tianjin_deaf"] = "tianjin_deaf"
	Permission["shenzhen_deaf"] = "shenzhen_deaf"
	Permission["shenzhen_thalassemia"] = "shenzhen_thalassemia"
	Permission["Nifty3"] = ""
	

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
