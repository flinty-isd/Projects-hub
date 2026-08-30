<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Permissions.aspx.cs" Inherits="SharePointReportingDashboard.PermissionsPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Permissions - SharePoint Reporting Dashboard</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Permissions Overview</h1>
    <p class="page-lead">Who has access to what, across every site, list, and library.</p>

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

    <div class="card">
        <h2>Permission assignments</h2>
        <asp:GridView ID="permissionsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="ObjectName" HeaderText="Object" />
                <asp:BoundField DataField="ObjectType" HeaderText="Type" />
                <asp:BoundField DataField="PrincipalName" HeaderText="Principal" />
                <asp:BoundField DataField="PrincipalType" HeaderText="Principal Type" />
                <asp:BoundField DataField="PermissionLevel" HeaderText="Level" />
                <asp:TemplateField HeaderText="Inheritance">
                    <ItemTemplate>
                        <%# GetInheritanceBadge((bool)Eval("InheritsPermissions")) %>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="External?">
                    <ItemTemplate>
                        <%# GetExternalBadge((bool)Eval("IsExternalUser")) %>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
