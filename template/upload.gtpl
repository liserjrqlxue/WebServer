<html>
<head>
    <title>{{.Title}}</title>
</head>
<body>
<form enctype="multipart/form-data" action="/upload" method="post">
    <input type="file" name="uploadfile"></input>
    <input type="hidden" name="token" value="{{.Token}}"></input>
    <input type="submit" value="upload"></input>
</form>
</body>
</html>