<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Compliance.aspx.cs" Inherits="CompliancePage" MasterPageFile="~/Site.Master" %>
<%@ MasterType VirtualPath="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Control compliance</h2>

    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Controls tracked</span>
            <span class="kpi-value"><%= TotalControls %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Compliance rate</span>
            <span class="kpi-value <%= ComplianceRateClass %>"><%= ComplianceRate.ToString("0.0") %>%</span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Non-compliant</span>
            <span class="kpi-value <%= NonCompliant > 0 ? "alert" : "good" %>"><%= NonCompliant %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Not assessed</span>
            <span class="kpi-value <%= NotAssessed > 0 ? "warn" : "good" %>"><%= NotAssessed %></span>
        </div>
    </div>

    <div class="filters">
        <div>
            <label for="<%= FrameworkFilter.ClientID %>">Framework</label>
            <asp:ListBox ID="FrameworkFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
        <div>
            <label for="<%= StatusFilter.ClientID %>">Status</label>
            <asp:ListBox ID="StatusFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
    </div>

    <asp:GridView ID="ControlsGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid"
        EmptyDataText="No controls match the selected filters.">
        <Columns>
            <asp:BoundField DataField="ControlId" HeaderText="Control" />
            <asp:BoundField DataField="Title" HeaderText="Description" />
            <asp:BoundField DataField="Framework" HeaderText="Framework" />
            <asp:BoundField DataField="Owner" HeaderText="Owner" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="LastAssessed" HeaderText="Last Assessed" DataFormatString="{0:yyyy-MM-dd}" />
        </Columns>
    </asp:GridView>

    <h3>Controls by status</h3>
    <div id="statusChart" class="chart"></div>

    <h3>Controls by framework</h3>
    <div id="frameworkChart" class="chart"></div>

    <script src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', { packages: ['corechart'] });
        google.charts.setOnLoadCallback(drawCharts);
        function drawCharts() {
            drawColumn('statusChart', <%= StatusChartDataJson %>);
            drawColumn('frameworkChart', <%= FrameworkChartDataJson %>);
        }
        function drawColumn(elementId, rows) {
            if (rows.length < 2) { return; }
            var chart = new google.visualization.ColumnChart(document.getElementById(elementId));
            chart.draw(google.visualization.arrayToDataTable(rows), { legend: { position: 'none' } });
        }
    </script>
</asp:Content>
