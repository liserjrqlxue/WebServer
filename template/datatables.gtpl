<html>
<head>
    <title>DataTables</title>
    <link rel="stylesheet" href="/static/css/bootstrap.css" />
</head>
<body>
<script src="https://code.jquery.com/jquery-3.3.1.js"
        integrity="sha256-2Kok7MbOyxpgUVvAk/HJ2jigOSYS2auK4Pfzbm7uH60="
        crossorigin="anonymous">
</script>
<link rel="stylesheet" type="text/css"
      href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.css" />
<script type="text/javascript" charset="utf8"
        src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.js">
</script>

<table id="example" class="display" style="width:100%">
    <thead>
    <tr>
        <th>工单对应的研发项目编码（必填）</th>
        <th>工单对应的研发项目名称（必填）</th>
        <th>项目负责人</th>
        <th>天津华大医学检验所有限公司
            A230(已上线领料系统)</th>
        <th>武汉华大医学检验所有限公司
            A080(已上线领料系统)</th>
        <th>深圳华大基因科技服务有限公司
            A040(已上线领料系统)</th>
        <th>深圳华大基因科技服务有限公司天津分公司
            A520(已上线领料系统</th>
        <th>深圳华大基因股份有限公司
            A000(未上线领料系统)</th>
    </tr>
    </thead>
    <tfoot>
    <tr>
        <th>工单对应的研发项目编码（必填）</th>
        <th>工单对应的研发项目名称（必填）</th>
        <th>项目负责人</th>
        <th>天津华大医学检验所有限公司
            A230(已上线领料系统)</th>
        <th>武汉华大医学检验所有限公司
            A080(已上线领料系统)</th>
        <th>深圳华大基因科技服务有限公司
            A040(已上线领料系统)</th>
        <th>深圳华大基因科技服务有限公司天津分公司
            A520(已上线领料系统</th>
        <th>深圳华大基因股份有限公司
            A000(未上线领料系统)</th>
    </tr>
    </tfoot>
</table>
<script>
    $(document).ready(function() {
    $('#example').DataTable({
        //"ajax":"/ajax/data/arrays.txt"
        "ajax":"/public/生育研发MO.xlsx.Sheet1.json",
        "columns":[
            {"data":"工单对应的研发项目编码（必填）"},
            {"data":"工单对应的研发项目名称（必填）"},
            {"data":"项目负责人"},
            {"data":"天津华大医学检验所有限公司\nA230(已上线领料系统)"},
            {"data":"武汉华大医学检验所有限公司\nA080(已上线领料系统)"},
            {"data":"深圳华大基因科技服务有限公司\nA040(已上线领料系统)"},
            {"data":"深圳华大基因科技服务有限公司天津分公司\nA520(已上线领料系统)"},
            {"data":"深圳华大基因股份有限公司\nA000(未上线领料系统)"},
        ]
    });
    } );
</script>
</body>
</html>