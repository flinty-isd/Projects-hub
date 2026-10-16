<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Kpis.aspx.cs" Inherits="KpisPage" MasterPageFile="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Progress &amp; KPIs</h2>
    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Total tasks</span>
            <span class="kpi-value"><%= TotalTasks %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Avg % complete</span>
            <span class="kpi-value"><%= AvgPercentComplete.ToString("0.0") %>%</span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Overdue tasks</span>
            <span class="kpi-value"><%= OverdueTasks %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Open risks</span>
            <span class="kpi-value"><%= OpenRisks %></span>
        </div>
    </div>

    <h3>Tasks by owner</h3>
    <div id="ownerChart" style="width: 700px; height: 350px;"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawOwnerChart);
        function drawOwnerChart() {
            var data = google.visualization.arrayToDataTable(<%= OwnerChartDataJson %>);
            var chart = new google.visualization.ColumnChart(document.getElementById('ownerChart'));
            chart.draw(data, { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
