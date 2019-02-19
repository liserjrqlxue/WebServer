<html>
<head>
    <title>上传文件</title>
    <link rel="stylesheet" href="/static/css/bootstrap.css" />
</head>
<body>
<div class="container">
    <H1>自动化报告系统</H1>
    <form enctype="multipart/form-data" action="/wgs2docx" method="post" target="_blank">
        <div class="form-group row">
            <label for="type" class="col-sm-2 col-form-label">
                项目类型
            </label>
            <div class="col-sm-10">
                <select id="type" name="type" class="form-control">
                    <option value ="wgs">WGS</option>
                    <option value ="pre_pregnancy">PP100</option>
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

        <input type="hidden" name="token" value="{{.}}"/>
        <button type="submit" class="btn btn-primary">Submit</button>
    </form>
</div>

</body>
</html>