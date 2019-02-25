# WebServer
go webserver

## install server
```
go get github.com/liserjrqlxue/WebServer
eval `go env|grep GOPATH`
cd $GOPATH/github.com/liserjrqlxue/WebServer
go build
```

## start server
```
./WebServer -port :9091
```

## autoReport
报告自动化系统
```
git clone http://192.168.136.114:8585/liser.jrqlxue/report.py
```
or
```
ln -sf /path/to/report.py .
```
open http://localhost:9091/autoReport and test
