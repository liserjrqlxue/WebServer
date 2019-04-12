{{define "updateMO"}}
{{template "header" .}}
<main>
    <div class="text-center">
        上传文件"生育研发MO.xlsx"更新：<a href="datatables" target="_blank">生育研发MO</a>
    </div>
    <div class="container">
        <form enctype="multipart/form-data" action="/updateMO" method="post">
            <input type="hidden" name="token" value="{{.Token}}"></input>
            <input type="file" id="i-file" name="uploadfile" style="display:none" required="required"
                   onchange="$('#localtion').val($('#i-file').val());" >
            </input>
            <div class="input-group-append">
                <input id="localtion" class="form-control" disabled="disabled"></input>
                <a type="button" id="i-check" class="btn"
                   onclick="$('#i-file').click();">
                    Browse
                </a>
            </div>
            <button type="submit" class="btn btn-primary btn-block">upload</button>
        </form>
    </div>

</main>
<script src="/static/js/jquery-3.3.1.js"></script>
<footer class="container">
<p>&copy; BGI 2019</p>
</footer>
</body>
</html>
{{end}}