<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Migration.aspx.cs" Inherits="SharePointReportingDashboard.MigrationPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Migration - HPUK SharePoint Project Control Centre</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Migration</h1>
    <p class="page-lead">Residual site migration only. This page tracks the Migration Register, not page delivery.</p>

    <div class="info-banner">
        LMS is <strong>complete and is not shown here as a current blocker</strong>. The People page and other
        out-of-scope pages are tracked separately on <a href="Pages.aspx">People &amp; Pages</a>.
    </div>

    <div class="card">
        <h2>Completion by department</h2>
        <asp:Repeater ID="departmentProgressRepeater" runat="server">
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
        <p class="kpi-note">Based on the illustrative Migration Register sample, not the full 209-site baseline.</p>
    </div>

    <div class="card">
        <h2>Next 30 days</h2>
        <asp:GridView ID="next30Grid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteId" HeaderText="Site ID" />
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="Department" HeaderText="Department" />
                <asp:BoundField DataField="Wave" HeaderText="Wave" />
                <asp:BoundField DataField="PlannedMigration" HeaderText="Planned Migration" DataFormatString="{0:yyyy-MM-dd}" />
                <asp:TemplateField HeaderText="Readiness">
                    <ItemTemplate><%# GetRagBadge((string)Eval("Readiness")) %></ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Blocked / Amber sites</h2>
        <asp:GridView ID="blockedGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteId" HeaderText="Site ID" />
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="Status" HeaderText="Status" />
                <asp:TemplateField HeaderText="Readiness">
                    <ItemTemplate><%# GetRagBadge((string)Eval("Readiness")) %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="BlockerDependency" HeaderText="Blocker / Dependency" />
                <asp:BoundField DataField="MigrationOwner" HeaderText="Migration Owner" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Remaining sites</h2>
        <asp:GridView ID="remainingGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteId" HeaderText="Site ID" />
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="Department" HeaderText="Department" />
                <asp:BoundField DataField="Wave" HeaderText="Wave" />
                <asp:BoundField DataField="Status" HeaderText="Status" />
                <asp:TemplateField HeaderText="Readiness">
                    <ItemTemplate><%# GetRagBadge((string)Eval("Readiness")) %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="BusinessOwner" HeaderText="Business Owner" />
                <asp:BoundField DataField="MigrationOwner" HeaderText="Migration Owner" />
                <asp:BoundField DataField="PlannedMigration" HeaderText="Planned Migration" DataFormatString="{0:yyyy-MM-dd}" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Completed sites</h2>
        <asp:GridView ID="completedGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteId" HeaderText="Site ID" />
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="Department" HeaderText="Department" />
                <asp:BoundField DataField="ActualMigration" HeaderText="Actual Migration" DataFormatString="{0:yyyy-MM-dd}" />
                <asp:BoundField DataField="UatStatus" HeaderText="UAT Status" />
                <asp:BoundField DataField="BusinessSignOff" HeaderText="Business Sign-off" />
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
