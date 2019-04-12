{{define "datatables"}}
{{template "header" .}}

<script src="/static/js/jquery-3.3.1.js"></script>
<link rel="stylesheet" type="text/css"
      href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.css" />
<script type="text/javascript" charset="utf8"
        src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.js">
</script>
<div class="container">
    <div class="form-inline">
        <label for="searchNo">项目编号</label>
        <input type="text" id="searchNo" name="searchNo" class="form-control col-sm-6" placeholder="Search 项目编号" aria-label="Search"></input>
    </div>
    <div class="form-inline">
        <label for="searchName">项目名称</label>
        <input type="text" id="searchName" name="searchName" class="form-control col-sm-6" placeholder="Search 项目名称" aria-label="Search"></input>
    </div>
</div>
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
</table>
<script>
    $(document).ready(function() {
        // DataTable
        var table = $('#example').DataTable({
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

        table.columns(0).search("MO").draw()

        $('#searchNo').on('keyup click',function() {
           table.columns(0).search("^"+$('#searchNo').val().trim()+"$",true).draw()
        });
        $('#searchName').on('keyup click',function() {
           table.columns(1).search("^"+$('#searchName').val().trim()+"$",true).draw()
        });
    });
</script>
</body>
</html>
{{end}}