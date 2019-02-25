<html>
<head>
    <title>Home Page</title>
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
                <a class="nav-link" href="#">Home<span class="sr-only">(current)</span></a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="autoReport">报告自动化<span class="sr-only">报告自动化</span></a>
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
            <h1 class="display-3">Hello, world!</h1>
            <p>This is a template for a simple marketing or informational website. It includes a large callout called a jumbotron and three supporting pieces of content. Use it as a starting point to create something more unique.</p>
            <p><a class="btn btn-primary btn-lg" href="#" role="button">Learn more &raquo;</a></p>
        </div>
    </div>

    <div class="container">
        <!-- Example row of columns -->
        <div class="row">
            <div class="col-md-4">
                <h2>孕前报告自动化</h2>
                <p>孕前报告自动化</p>
                <p><a class="btn btn-secondary" href="autoReport?type=pre_pregnancy" role="button">View details &raquo;</a></p>
            </div>
            <div class="col-md-4">
                <h2>WGS报告自动化</h2>
                <p>孕前报告自动化</p>
                <p><a class="btn btn-secondary" href="autoReport?type=wgs" role="button">View details &raquo;</a></p>
            </div>
            <div class="col-md-4">
                <h2>海外报告自动化</h2>
                <p>孕前报告自动化</p>
                <p><a class="btn btn-secondary" href="autoReport?type=hw" role="button">View details &raquo;</a></p>
            </div>
        </div>
        <hr/>
    </div> <!-- /container -->
</main>

<footer class="container">
    <p>&copy; BGI 2019</p>
</footer>

</body>
</html>