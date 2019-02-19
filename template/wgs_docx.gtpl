<html>
<head>
    <title>上传文件</title>
</head>
<body>
<form enctype="multipart/form-data" action="/wgs2docx" method="post">
    <input type="file" name="uploadfile" />
    <input type="hidden" name="token" value="{{.}}"/>
    <select name="type">
        <option value ="wgs">WGS</option>
        <option value ="pre_pregnancy">PP100</option>
    </select>
    <input type="submit" value="upload" />
</form>
</body>
</html>