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
<form>
    <div class="form-group">
        <label for="bamPath">BamPath</label>
        <input type="text" class="form-control" id="bamPath" name="path"
               aria-describedby="bamPathHelp" placeholder="Enter Bam Path"></input>
    </div>
    <div class="form-group">
        <label for="chr">Chr</label>
        <select class="form-control" id="chr" name="chr">
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
    <div class="form-group">
        <label for="readsLength">Reads Length</label>
        <select class="form-control" id="readsLength" name="Plotread_Length">
            <option value="100">100bp</option>
            <option value="150">150bp</option>
        </select>
    </div>
    <div class="form-group">
        <label for="startPos">Start</label>
        <input type="text" class="form-control" id="startPos" name="Start"
               aria-describedby="StartHelp" placeholder="Enter Start Position"></input>
    </div>
    <div class="form-check form-check-inline">
        <input class="form-check-input" type="radio" name="position" id="at" value="at" checked></input>
        <label class="form-check-label" for="at">
            at
        </label>
    </div>
    <div class="form-check form-check-inline">
        <input class="form-check-input" type="radio" name="position" id="between" value="between"></input>
        <label class="form-check-label" for="between">
            between
        </label>
    </div>
    <div class="form-check form-check-inline">
        <input class="form-check-input" type="radio" name="position" id="from" value="from"></input>
        <label class="form-check-label" for="from">
            from
        </label>
    </div>
    <div class="form-group">
        <label for="endPos">End</label>
        <input type="text" class="form-control" id="endPos" name="End"
               aria-describedby="StartHelp" placeholder="Enter End Position"></input>
    </div>
    <button type="submit" class="btn btn-primary">Submit</button>
</form>
</main>
<footer class="container">
    <p>&copy; BGI 2019</p>
</footer>

</body>

</html>