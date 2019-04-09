{{define "header"}}
<!doctype html>
<html>
<head>
    <title>{{.Title}}</title>
    <link rel="stylesheet" href="/static/css/bootstrap.css" />
</head>
<body>
<nav class="navbar navbar-expand-md navbar-dark fixed-top bg-dark">
    <a class="navbar-brand" href="#">Navbar</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarsExampleDefault" aria-controls="navbarsExampleDefault" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarsExampleDefault">
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home<span class="sr-only">Home</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="autoReport">报告自动化<span class="sr-only">报告自动化</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="datatables">生育研发MO<span class="sr-only">生育研发MO</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="plotReadsLocal">本地集群画reads图<span class="sr-only">本地集群画reads图</span></a>
            </li>
        </ul>
        <form class="form-inline my-2 my-lg-0">
            <input class="form-control mr-sm-2" type="text" placeholder="Search" aria-label="Search"/>
            <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Search</button>
        </form>
    </div>
</nav>
{{end}}