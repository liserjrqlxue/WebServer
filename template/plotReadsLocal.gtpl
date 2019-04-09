<!doctype html>
<html>
<head>
    <title>本地集群画reads图</title>
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
                <a class="nav-link" href="">Home<span class="sr-only">Home</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="autoReport">报告自动化<span class="sr-only">报告自动化</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="datatables">生育研发MO<span class="sr-only">生育研发MO</span></a>
            </li>
            <li class="nav-item active">
                <a class="nav-link" href="plotReadsLocal">本地集群画reads图<span class="sr-only">本地集群画reads图</span></a>
            </li>
        </ul>
        <form class="form-inline my-2 my-lg-0">
            <input class="form-control mr-sm-2" type="text" placeholder="Search" aria-label="Search"/>
            <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Search</button>
        </form>
    </div>
</nav>
<main>
    <div class="jumbotron"></div>
    <form enctype="multipart/form-data" action="/plotReadsLocal" method="post" target="_blank">
        <div class="form-group row">
            <label for="bamPath" class="col-sm-2 col-form-label">Prefix</label>
            <div class="col-sm-10">
                <input type="text" class="form-control" id="prefix" name="prefix"
                       aria-describedby="prefixHelp" placeholder="Enter Prefix">
                </input>
            </div>
        </div>
        <div class="form-group row">
            <label for="bamPath" class="col-sm-2 col-form-label">Bam路径</label>
            <div class="col-sm-10">
                <input type="text" class="form-control" id="bamPath" name="path" required="required"
                       aria-describedby="bamPathHelp" placeholder="Enter Bam Path">
                </input>
            </div>
        </div>
        <div class="form-group row">
            <label for="chr" class="col-sm-2 col-form-label">Chromosome</label>
            <div class="col-sm-4">
                <select class="form-control" id="chr" name="chr" required="required">
                    <option value="chr1">chr1</option>
                    <option value="chr2">chr2</option>
                    <option value="chr3">chr3</option>
                    <option value="chr4">chr4</option>
                    <option value="chr5">chr5</option>
                    <option value="chr6">chr6</option>
                    <option value="chr7">chr7</option>
                    <option value="chr8">chr8</option>
                    <option value="chr9">chr9</option>
                    <option value="chr10">chr10</option>
                    <option value="chr11">chr11</option>
                    <option value="chr12">chr12</option>
                    <option value="chr13">chr13</option>
                    <option value="chr14">chr14</option>
                    <option value="chr15">chr15</option>
                    <option value="chr16">chr16</option>
                    <option value="chr17">chr17</option>
                    <option value="chr18">chr18</option>
                    <option value="chr19">chr19</option>
                    <option value="chr20">chr20</option>
                    <option value="chr21">chr21</option>
                    <option value="chr22">chr22</option>
                    <option value="chrX">chrX</option>
                    <option value="chrY">chrY</option>
                    <option value="chrM">chrM </option>
                </select>

            </div>
            <label for="readsLength" class="col-sm-2 col-form-label">Reads Length</label>
            <div class="col-sm-4">
                <select class="form-control" id="readsLength" name="Plotread_Length">
                    <option value="100">100bp</option>
                    <option value="150">150bp</option>
                </select>
            </div>
        </div>
        <div class="form-group row">
            <label for="startPos" class="col-sm-2 col-form-label">Start</label>
            <div class="col-sm-4">
                <input type="text" class="form-control" id="startPos" name="Start" required="required"
                       aria-describedby="StartHelp" placeholder="Enter Start Position">
                </input>
            </div>
            <label for="endPos" class="col-sm-2 col-form-label">End</label>
            <div class="col-sm-4">
                <input type="text" class="form-control" id="endPos" name="End"
                       aria-describedby="StartHelp" placeholder="Enter End Position">
                </input>
            </div>
        </div>
        <div class="form-group">
            <div class="form-check form-check-inline">
                <input class="form-check-input" type="radio" name="position" id="at" value="at" checked="checked">
                </input>
                <label class="form-check-label" for="at">
                    at
                </label>
            </div>
            <div class="form-check form-check-inline">
                <input class="form-check-input" type="radio" name="position" id="in" value="in">
                </input>
                <label class="form-check-label" for="in">
                    in
                </label>
            </div>
            <div class="form-check form-check-inline">
                <input class="form-check-input" type="radio" name="position" id="to" value="to">
                </input>
                <label class="form-check-label" for="to">
                    to
                </label>
            </div>
        </div>
        <button type="submit" class="btn btn-primary btn-block">Submit</button>
    </form>
    <div class="jumbotron">
        {{.Img}}
        <img src="{{.Src}}"/>
    </div>

</main>
<footer class="container">
    <p>&copy; BGI 2019</p>
</footer>
<script src="/static/js/jquery-3.3.1.js"></script>
<script type="text/javascript">
    //获取url中的参数
    function getUrlParam(name){
        var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)"); //构造一个含有目标参数的正则表达式对象
        var r = window.location.search.substr(1).match(reg);  //匹配目标参数
        if (r != null) return unescape(r[2]); return null; //返回参数值
    }
    $('input[name="path"]').val(getUrlParam("path"));
    $('select[name="chr"]').val(getUrlParam("chr"));
    $('select[name="Poltread_Length"]').val(getUrlParam("Plotread_Length"));
    $('input[name="Start"]').val(getUrlParam("Start"));
    if(getUrlParam("at"))
        $('input[value="at"]').click();
    if(getUrlParam("between"))
        $('input[value="between"]').click();
    if(getUrlParam("from"))
        $('input[value="from"]').click();
    $('input[name="End"]').val(getUrlParam("End"));
</script>


</body>

</html>