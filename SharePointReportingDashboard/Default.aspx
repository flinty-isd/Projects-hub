<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SharePointReportingDashboard.DefaultPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Overview - SharePoint Reporting Dashboard</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Tenant Overview</h1>
    <p class="page-lead">Snapshot across all sites in the mock <code>contoso.sharepoint.com</code> tenant.</p>

    <div class="stat-grid">
        <asp:Repeater ID="statsRepeater" runat="server">
            <ItemTemplate>
                <div class="stat-tile">
                    <div class="stat-value"><%# Eval("Value") %></div>
                    <div class="stat-label"><%# Eval("Label") %></div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
    </div>

    <div class="two-col">
        <div class="card">
            <h2>Storage used by site</h2>
            <asp:Repeater ID="storageChartRepeater" runat="server">
                <ItemTemplate>
                    <div class="bar-chart-row">
                        <div class="bar-chart-label"><%# Eval("Label") %></div>
                        <div class="bar-chart-track">
                            <div class="bar-chart-fill" style='width: <%# Eval("PercentWidth") %>%;'></div>
                        </div>
                        <div class="bar-chart-value"><%# Eval("ValueText") %></div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
        </div>

        <div class="card">
            <h2>Quick links</h2>
            <p><a href="Sites.aspx">Site &amp; list inventory &rarr;</a></p>
            <p><a href="Activity.aspx">Recent user activity &rarr;</a></p>
            <p><a href="Permissions.aspx">Permissions overview &rarr;</a></p>
        </div>
    </div>

</asp:Content>
