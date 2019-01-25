<html>
<head>
	<title>肾病报告自动化</title>
</head>
<body>
<form enctype="multipart/form-data" action="/upload2" method="post">
  <input type="file" name="uploadfile" />
  <input type="hidden" name="token" value="{{.}}"/>
  <input type="submit" value="upload" />
</form>
