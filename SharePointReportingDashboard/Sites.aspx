<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Sites.aspx.cs" Inherits="SharePointReportingDashboard.SitesPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Sites &amp; Lists - SharePoint Reporting Dashboard</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Site &amp; List Inventory</h1>
    <p class="page-lead">All site collections and their lists/libraries, with item counts and storage.</p>

    <div class="card">
        <h2>Sites</h2>
        <asp:GridView ID="sitesGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false"
            GridLines="None" DataKeyNames="Title">
            <Columns>
                <asp:BoundField DataField="Title" HeaderText="Site" />
                <asp:BoundField DataField="Url" HeaderText="URL" />
                <asp:BoundField DataField="Owner" HeaderText="Owner" />
                <asp:BoundField DataField="Template" HeaderText="Template" />
                <asp:BoundField DataField="ListCount" HeaderText="Lists" />
                <asp:BoundField DataField="ItemCount" HeaderText="Items" DataFormatString="{0:N0}" />
                <asp:BoundField DataField="StorageUsedMb" HeaderText="Storage (MB)" DataFormatString="{0:N1}" />
                <asp:BoundField DataField="LastModifiedUtc" HeaderText="Last Modified (UTC)" DataFormatString="{0:yyyy-MM-dd}" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Lists &amp; Libraries</h2>
        <div class="filter-bar">
            <label for="<%= siteFilter.ClientID %>">Filter by site:</label>
            <asp:DropDownList ID="siteFilter" runat="server" AutoPostBack="true" OnSelectedIndexChanged="siteFilter_SelectedIndexChanged" />
        </div>
        <asp:GridView ID="listsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="ListName" HeaderText="List / Library" />
                <asp:BoundField DataField="ListType" HeaderText="Type" />
                <asp:BoundField DataField="ItemCount" HeaderText="Items" DataFormatString="{0:N0}" />
                <asp:BoundField DataField="SizeMb" HeaderText="Size (MB)" DataFormatString="{0:N1}" />
                <asp:BoundField DataField="LastModifiedUtc" HeaderText="Last Modified (UTC)" DataFormatString="{0:yyyy-MM-dd}" />
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
