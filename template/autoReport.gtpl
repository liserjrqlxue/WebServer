<html>
<head>
    <title>自动化报告系统</title>
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
            <li class="nav-item active">
                <a class="nav-link" href="/">Home<span class="sr-only">Home Page</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#">报告自动化<span class="sr-only">(current)</span></a>
            </li>
        </ul>
        <form class="form-inline my-2 my-lg-0">
            <input class="form-control mr-sm-2" type="text" placeholder="Search" aria-label="Search"/>
            <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Search</button>
        </form>
    </div>
</nav>
<main role="main">
    <!-- Main jumbotron for a primary marketing message or call to action -->
    <div class="jumbotron">
        <div class="container">
            <h1 class="display-3">自动化报告系统</h1>
        </div>
    </div>

    <div class="container">
        <form enctype="multipart/form-data" action="/autoReport" method="post" target="_blank">
            <div class="form-group row">
                <label for="type" class="col-md-2 col-form-label">
                    项目类型
                </label>
                <div class="col-md-10">
                    <select id="type" name="type" class="form-control form-control-lg">
                        <option value ="pre_pregnancy">PP100</option>
                        <option value ="multi_center">多中心</option>
                        <option value ="wgs">WGS</option>
                        <option value ="hw">海外</option>
                    </select>
                </div>
            </div>
            <div class="form-group row">
                <label for="uploadfile" class="col-md-2 col-form-label">
                    输入文件
                </label>
                <div class="col-md-10">
                    <input type="file" class="form-control-file form-control-lg" id="uploadfile" name="uploadfile" />
                </div>
            </div>

            <input type="hidden" name="token" value="{{.Token}}"/>
            <button type="submit" class="btn btn-primary btn-block btn-lg">Submit</button>
        </form>
        <div>
            {{if eq .Href ""}}
            {{else}}
            <div>
                <p><a href="{{.Href}}">报告下载</a></p>
            </div>
            {{end}}
            {{if eq .Err ""}}
            {{else}}
            <div>
                <p>Error:</p>
                <pre>{{.Err}}</pre>
            </div>
            {{end}}
            {{if eq .Message ""}}
            {{else}}
            <div>
                <p>Message:</p>
                <pre>{{.Message}}</pre>
            </div>
            {{end}}

        </div>
    </div>

</main>


<script>
    console.log({{.}})
    var select=document.getElementById("type")
    for(var i=0;i < select.length;i++){
        console.log(select[i].value)
        if(select[i].value=={{.Option}}){
            select.selectedIndex=i
        }
    }
</script>

</body>
</html>