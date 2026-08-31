<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Governance.aspx.cs" Inherits="SharePointReportingDashboard.GovernancePage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Governance - HPUK SharePoint Project Control Centre</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Governance / Control Board</h1>
    <p class="page-lead">RAID, actions, decisions and the latest Project Update snapshot &mdash; the Control Board meeting landing page.</p>

    <div class="card">
        <h2>Latest Project Update snapshot</h2>
        <p>
            <strong><asp:Literal ID="snapshotDateLiteral" runat="server" /></strong> &mdash;
            Sites Complete: <strong><asp:Literal ID="snapshotSitesLiteral" runat="server" /></strong>,
            Remaining: <strong><asp:Literal ID="snapshotRemainingLiteral" runat="server" /></strong>,
            Overall RAG: <asp:Literal ID="snapshotRagLiteral" runat="server" />,
            Open Risks: <strong><asp:Literal ID="snapshotRisksLiteral" runat="server" /></strong>,
            Overdue Actions: <strong><asp:Literal ID="snapshotOverdueLiteral" runat="server" /></strong>,
            Pages Outstanding: <strong><asp:Literal ID="snapshotPagesLiteral" runat="server" /></strong>
        </p>
        <p><asp:Literal ID="snapshotCommentaryLiteral" runat="server" /></p>
    </div>

    <div class="two-col">
        <div class="card">
            <h2>Red / Amber RAID</h2>
            <asp:GridView ID="raidGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="RaidId" HeaderText="ID" />
                    <asp:BoundField DataField="Type" HeaderText="Type" />
                    <asp:BoundField DataField="Area" HeaderText="Area" />
                    <asp:BoundField DataField="Description" HeaderText="Description" />
                    <asp:TemplateField HeaderText="RAG">
                        <ItemTemplate><%# GetRagBadge((string)Eval("Rag")) %></ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Owner" HeaderText="Owner" />
                </Columns>
            </asp:GridView>
        </div>

        <div class="card">
            <h2>Overdue actions</h2>
            <asp:GridView ID="overdueActionsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="ActionId" HeaderText="ID" />
                    <asp:BoundField DataField="Action" HeaderText="Action" />
                    <asp:BoundField DataField="Owner" HeaderText="Owner" />
                    <asp:BoundField DataField="DueDate" HeaderText="Due Date" DataFormatString="{0:yyyy-MM-dd}" />
                    <asp:BoundField DataField="RelatedSitePage" HeaderText="Related" />
                </Columns>
            </asp:GridView>
        </div>
    </div>

    <div class="two-col">
        <div class="card">
            <h2>Pending decisions</h2>
            <asp:GridView ID="pendingDecisionsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="DecisionId" HeaderText="ID" />
                    <asp:BoundField DataField="DecisionText" HeaderText="Decision" />
                    <asp:BoundField DataField="Owner" HeaderText="Owner" />
                    <asp:BoundField DataField="RelatedSitePage" HeaderText="Related" />
                </Columns>
            </asp:GridView>
        </div>

        <div class="card">
            <h2>Scope changes</h2>
            <asp:GridView ID="scopeChangesGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="PageId" HeaderText="Page ID" />
                    <asp:BoundField DataField="PageName" HeaderText="Page" />
                    <asp:BoundField DataField="Disposition" HeaderText="Disposition" />
                    <asp:BoundField DataField="DeliveryStatus" HeaderText="Status" />
                </Columns>
            </asp:GridView>
        </div>
    </div>

    <div class="card">
        <h2>Weekly snapshot history</h2>
        <asp:GridView ID="snapshotHistoryGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SnapshotDate" HeaderText="Date" DataFormatString="{0:yyyy-MM-dd}" />
                <asp:BoundField DataField="SitesComplete" HeaderText="Sites Complete" />
                <asp:BoundField DataField="RemainingSites" HeaderText="Remaining" />
                <asp:TemplateField HeaderText="Overall RAG">
                    <ItemTemplate><%# GetRagBadge((string)Eval("OverallRag")) %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="OpenRisks" HeaderText="Open Risks" />
                <asp:BoundField DataField="OverdueActions" HeaderText="Overdue Actions" />
                <asp:BoundField DataField="PagesOutstanding" HeaderText="Pages Outstanding" />
                <asp:BoundField DataField="Commentary" HeaderText="Commentary" />
            </Columns>
        </asp:GridView>
        <p class="kpi-note">Append-only per the Project Updates list &mdash; never overwrite historical status.</p>
    </div>

</asp:Content>
