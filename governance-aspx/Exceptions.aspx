<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Exceptions.aspx.cs" Inherits="ExceptionsPage" MasterPageFile="~/Site.Master" %>
<%@ MasterType VirtualPath="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Policy exceptions &amp; waivers</h2>

    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Active exceptions</span>
            <span class="kpi-value"><%= ActiveExceptions %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Expiring in 90 days</span>
            <span class="kpi-value <%= ExpiringSoon > 0 ? "warn" : "good" %>"><%= ExpiringSoon %></span>
        </div>
    </div>

    <asp:GridView ID="ExceptionsGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid"
        EmptyDataText="No exceptions recorded."
        OnRowDataBound="ExceptionsGrid_RowDataBound">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Exception" />
            <asp:BoundField DataField="PolicyRef" HeaderText="Against Policy" />
            <asp:BoundField DataField="RequestedBy" HeaderText="Requested By" />
            <asp:BoundField DataField="Approver" HeaderText="Approver" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="ExpiryDate" HeaderText="Expires" DataFormatString="{0:yyyy-MM-dd}" />
        </Columns>
    </asp:GridView>
    <p class="empty-note">Active exceptions expiring within 90 days are highlighted in amber.</p>

    <h3>Exceptions by status</h3>
    <div id="statusChart" class="chart"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawStatusChart);
        function drawStatusChart() {
            var rows = <%= StatusChartDataJson %>;
            if (rows.length < 2) { return; }
            var chart = new google.visualization.ColumnChart(document.getElementById('statusChart'));
            chart.draw(google.visualization.arrayToDataTable(rows), { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
