<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="PoliciesPage" MasterPageFile="~/Site.Master" %>
<%@ MasterType VirtualPath="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Policies &amp; standards</h2>

    <div class="kpi-row">
        <div class="kpi-tile">
            <span class="kpi-label">Total policies</span>
            <span class="kpi-value"><%= TotalPolicies %></span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Currency rate</span>
            <span class="kpi-value <%= CurrencyRateClass %>"><%= CurrencyRate.ToString("0.0") %>%</span>
        </div>
        <div class="kpi-tile">
            <span class="kpi-label">Due for review</span>
            <span class="kpi-value <%= DueForReview > 0 ? "warn" : "good" %>"><%= DueForReview %></span>
        </div>
    </div>

    <div class="filters">
        <div>
            <label for="<%= StatusFilter.ClientID %>">Status</label>
            <asp:ListBox ID="StatusFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
        <div>
            <label for="<%= CategoryFilter.ClientID %>">Category</label>
            <asp:ListBox ID="CategoryFilter" runat="server" SelectionMode="Multiple" Rows="4"
                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
        </div>
    </div>

    <asp:GridView ID="PoliciesGrid" runat="server" AutoGenerateColumns="false" CssClass="data-grid"
        EmptyDataText="No policies match the selected filters.">
        <Columns>
            <asp:BoundField DataField="Title" HeaderText="Policy" />
            <asp:BoundField DataField="Category" HeaderText="Category" />
            <asp:BoundField DataField="Owner" HeaderText="Owner" />
            <asp:BoundField DataField="Status" HeaderText="Status" />
            <asp:BoundField DataField="Version" HeaderText="Version" />
            <asp:BoundField DataField="LastReviewed" HeaderText="Last Reviewed" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="NextReview" HeaderText="Next Review" DataFormatString="{0:yyyy-MM-dd}" />
        </Columns>
    </asp:GridView>

    <h3>Policies by status</h3>
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
