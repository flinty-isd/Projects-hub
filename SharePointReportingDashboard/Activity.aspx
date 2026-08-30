<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Activity.aspx.cs" Inherits="SharePointReportingDashboard.ActivityPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Activity - SharePoint Reporting Dashboard</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">User Activity</h1>
    <p class="page-lead">Recent document and list activity across all sites.</p>

    <div class="two-col">
        <div class="card">
            <h2>Recent activity</h2>
            <asp:GridView ID="activityGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="TimestampUtc" HeaderText="When (UTC)" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
                    <asp:BoundField DataField="UserName" HeaderText="User" />
                    <asp:BoundField DataField="Action" HeaderText="Action" />
                    <asp:BoundField DataField="ItemName" HeaderText="Item" />
                    <asp:BoundField DataField="ListName" HeaderText="List" />
                    <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                </Columns>
            </asp:GridView>
        </div>

        <div class="card">
            <h2>Top contributors (30d)</h2>
            <asp:Repeater ID="topContributorsRepeater" runat="server">
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
    </div>

</asp:Content>
