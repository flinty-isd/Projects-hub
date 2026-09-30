<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Risks.aspx.cs" Inherits="RiskRegisterPage" MasterPageFile="~/Site.Master" %>
<%@ MasterType VirtualPath="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>IT risk register</h2>

    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Risks tracked</span>
            <span class="kpi-value"><%= TotalRisks %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">High / extreme open</span>
            <span class="kpi-value <%= HighRisks > 0 ? "alert" : "good" %>"><%= HighRisks %></span>
        </div>
    </div>

    <asp:GridView ID="RisksGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid"
        EmptyDataText="No risks recorded.">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Risk" />
            <asp:BoundField DataField="Category" HeaderText="Category" />
            <asp:BoundField DataField="Owner" HeaderText="Owner" />
            <asp:BoundField DataField="Likelihood" HeaderText="L" />
            <asp:BoundField DataField="Impact" HeaderText="I" />
            <asp:BoundField DataField="Score" HeaderText="Score" />
            <asp:BoundField DataField="Treatment" HeaderText="Treatment" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
        </Columns>
    </asp:GridView>

    <h3>Heat map (open risks)</h3>
    <table class="heatmap">
        <asp:Literal ID="HeatMapRows" runat="server" />
    </table>
    <p class="empty-note">Likelihood (rows) &times; impact (columns), each cell showing the number of open risks.</p>

    <h3>Risks by category</h3>
    <div id="categoryChart" class="chart"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawCategoryChart);
        function drawCategoryChart() {
            var rows = <%= CategoryChartDataJson %>;
            if (rows.length < 2) { return; }
            var chart = new google.visualization.ColumnChart(document.getElementById('categoryChart'));
            chart.draw(google.visualization.arrayToDataTable(rows), { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
