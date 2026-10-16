<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Findings.aspx.cs" Inherits="FindingsPage" MasterPageFile="~/Site.Master" %>
<%@ MasterType VirtualPath="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Audit findings</h2>

    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Open findings</span>
            <span class="kpi-value"><%= OpenFindings %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Critical / High open</span>
            <span class="kpi-value <%= OpenHighSeverity > 0 ? "alert" : "good" %>"><%= OpenHighSeverity %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Overdue</span>
            <span class="kpi-value <%= OverdueFindings > 0 ? "alert" : "good" %>"><%= OverdueFindings %></span>
        </div>
    </div>

    <div class="filters">
        <div>
            <label for="<%= SeverityFilter.ClientID %>">Severity</label>
            <asp:ListBox ID="SeverityFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
        <div>
            <label for="<%= StatusFilter.ClientID %>">Status</label>
            <asp:ListBox ID="StatusFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
        <div>
            <label for="<%= SourceFilter.ClientID %>">Source</label>
            <asp:ListBox ID="SourceFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
    </div>

    <asp:GridView ID="FindingsGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid"
        EmptyDataText="No findings match the selected filters."
        OnRowDataBound="FindingsGrid_RowDataBound">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Finding" />
            <asp:BoundField DataField="Severity" HeaderText="Severity" />
            <asp:BoundField DataField="Source" HeaderText="Source" />
            <asp:BoundField DataField="Owner" HeaderText="Owner" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="RaisedDate" HeaderText="Raised" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="DueDate" HeaderText="Due" DataFormatString="{0:yyyy-MM-dd}" />
        </Columns>
    </asp:GridView>
    <p class="empty-note">Overdue open findings are highlighted in red.</p>

    <h3>Findings by severity</h3>
    <div id="severityChart" class="chart"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawSeverityChart);
        function drawSeverityChart() {
            var rows = <%= SeverityChartDataJson %>;
            if (rows.length < 2) { return; }
            var chart = new google.visualization.ColumnChart(document.getElementById('severityChart'));
            chart.draw(google.visualization.arrayToDataTable(rows), { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
