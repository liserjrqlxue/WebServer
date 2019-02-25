<html>
<head>
    <title>自动化报告系统</title>
    <link rel="stylesheet" href="/static/css/bootstrap.css" />

</head>
<body>
<div class="container">
    <H1>自动化报告系统</H1>
    <form enctype="multipart/form-data" action="/autoReport" method="post" target="_blank">
        <div class="form-group row">
            <label for="type" class="col-sm-2 col-form-label">
                项目类型
            </label>
            <div class="col-sm-10">
                <select id="type" name="type" class="form-control">
                    <option value ="pre_pregnancy">PP100</option>
                    <option value ="multi_center">多中心</option>
                    <option value ="wgs">WGS</option>
                    <option value ="hw">海外</option>
                </select>
            </div>
        </div>
        <div class="form-group row">
            <label for="uploadfile" class="col-sm-2 col-form-label">
                输入文件
            </label>
            <div class="col-sm-10">
                <input type="file" id="uploadfile" name="uploadfile" />
            </div>
        </div>

        <input type="hidden" name="token" value="{{.Token}}"/>
        <button type="submit" class="btn btn-primary">Submit</button>
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

<script>
    var select=document.getElementById("type")
    console.log({{.Token}})
    console.log({{.Option}})
    console.log({{.}})
    for(var i=0;i < select.length;i++){
        console.log(select[i].value)
        if(select[i].value=={{.Option}}){
        select.selectedIndex=i
        }
    }
</script>

</body>
</html>