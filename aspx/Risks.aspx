<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Risks.aspx.cs" Inherits="RisksPage" MasterPageFile="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Risks &amp; issues</h2>
    <asp:GridView ID="RisksGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Title" />
            <asp:BoundField DataField="Severity" HeaderText="Severity" />
            <asp:BoundField DataField="Owner" HeaderText="Owner" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="Description" HeaderText="Description" />
        </Columns>
    </asp:GridView>

    <h3>Risks by severity</h3>
    <div id="severityChart" style="width: 700px; height: 350px;"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawSeverityChart);
        function drawSeverityChart() {
            var data = google.visualization.arrayToDataTable(<%= SeverityChartDataJson %>);
            var chart = new google.visualization.ColumnChart(document.getElementById('severityChart'));
            chart.draw(data, { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
