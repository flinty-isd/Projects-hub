<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Pages.aspx.cs" Inherits="SharePointReportingDashboard.PagesPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">People &amp; Pages - HPUK SharePoint Project Control Centre</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">People &amp; Page Delivery</h1>
    <p class="page-lead">
        The People page (<strong>PAGE-001</strong>) and other pages outside the original migration scope, managed
        as controlled deliverables &mdash; not as migration or LMS blockers.
    </p>

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
        <h2>People (PAGE-001) delivery timeline</h2>
        <div class="timeline">
            <asp:Repeater ID="timelineRepeater" runat="server">
                <ItemTemplate>
                    <div class='timeline-step <%# Eval("CssClass") %>'><%# Eval("Stage") %></div>
                </ItemTemplate>
            </asp:Repeater>
        </div>
    </div>

    <div class="card">
        <h2>Priority queue &mdash; Critical/High pages not complete</h2>
        <asp:GridView ID="priorityGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="PageId" HeaderText="Page ID" />
                <asp:BoundField DataField="PageName" HeaderText="Page" />
                <asp:BoundField DataField="Priority" HeaderText="Priority" />
                <asp:BoundField DataField="DeliveryStatus" HeaderText="Status" />
                <asp:BoundField DataField="DeliveryOwner" HeaderText="Delivery Owner" />
                <asp:BoundField DataField="TargetGoLive" HeaderText="Target Go-live" DataFormatString="{0:yyyy-MM-dd}" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Ownership gaps</h2>
        <asp:GridView ID="ownershipGapsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="PageId" HeaderText="Page ID" />
                <asp:BoundField DataField="PageName" HeaderText="Page" />
                <asp:TemplateField HeaderText="Content Owner">
                    <ItemTemplate><%# string.IsNullOrEmpty((string)Eval("ContentOwner")) ? "<span class=\"rag-badge rag-red\">Missing</span>" : Eval("ContentOwner") %></ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Delivery Owner">
                    <ItemTemplate><%# string.IsNullOrEmpty((string)Eval("DeliveryOwner")) ? "<span class=\"rag-badge rag-red\">Missing</span>" : Eval("DeliveryOwner") %></ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Page backlog &mdash; Out of Scope / Scope Change</h2>
        <asp:GridView ID="backlogGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="PageId" HeaderText="Page ID" />
                <asp:BoundField DataField="PageName" HeaderText="Page" />
                <asp:BoundField DataField="BusinessArea" HeaderText="Business Area" />
                <asp:BoundField DataField="ScopeClassification" HeaderText="Scope Classification" />
                <asp:BoundField DataField="Disposition" HeaderText="Disposition" />
                <asp:BoundField DataField="DeliveryStatus" HeaderText="Status" />
                <asp:BoundField DataField="ContentOwner" HeaderText="Content Owner" />
                <asp:BoundField DataField="DeliveryOwner" HeaderText="Delivery Owner" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Related RAID &amp; actions</h2>
        <asp:GridView ID="relatedGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="ItemType" HeaderText="Type" />
                <asp:BoundField DataField="ItemId" HeaderText="ID" />
                <asp:BoundField DataField="Description" HeaderText="Description" />
                <asp:BoundField DataField="RelatedPage" HeaderText="Related Page" />
                <asp:BoundField DataField="Owner" HeaderText="Owner" />
                <asp:TemplateField HeaderText="RAG">
                    <ItemTemplate><%# GetRagBadge((string)Eval("Rag")) %></ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
