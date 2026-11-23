<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" MasterPageFile="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Tasks</h2>
    <div class="filters">
        <div>
            <label>Status</label>
            <asp:ListBox ID="StatusFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
        <div>
            <label>Owner</label>
            <asp:ListBox ID="OwnerFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
    </div>

    <asp:GridView ID="TasksGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Title" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="AssignedTo" HeaderText="Assigned To" />
            <asp:BoundField DataField="StartDate" HeaderText="Start Date" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="DueDate" HeaderText="Due Date" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="PercentComplete" HeaderText="% Complete" DataFormatString="{0:P0}" />
            <asp:BoundField DataField="Priority" HeaderText="Priority" />
        </Columns>
    </asp:GridView>

    <h3>Tasks by status</h3>
    <div id="statusChart" style="width: 700px; height: 350px;"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawStatusChart);
        function drawStatusChart() {
            var data = google.visualization.arrayToDataTable(<%= StatusChartDataJson %>);
            var chart = new google.visualization.ColumnChart(document.getElementById('statusChart'));
            chart.draw(data, { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
