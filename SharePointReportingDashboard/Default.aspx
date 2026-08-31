<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SharePointReportingDashboard.DefaultPage" %>
<asp:Content ID="TitleContent" ContentPlaceHolderID="TitleContent" runat="server">Programme Control Centre - HPUK SharePoint Project Control Centre</asp:Content>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class="page-title">Programme Control Centre</h1>
    <p class="page-lead">Executive live status across site migration and page delivery.</p>

    <div class="info-banner">
        Validated baseline: <strong>209 sites complete</strong>. LMS is <strong>complete and not a current programme blocker</strong>.
        The current delivery gap is the <strong>People page</strong> and other pages outside the original migration scope, tracked on
        <a href="Pages.aspx">People &amp; Pages</a>.
    </div>

    <div class="stat-grid">
        <asp:Repeater ID="statsRepeater" runat="server">
            <ItemTemplate>
                <div class="stat-tile">
                    <div class="stat-value"><%# Eval("Value") %></div>
                    <div class="stat-label"><%# Eval("Label") %></div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <div class="stat-tile">
            <div class="stat-value"><asp:Literal ID="overallRagLiteral" runat="server" /></div>
            <div class="stat-label">Overall Programme RAG</div>
        </div>
    </div>

    <div class="card">
        <h2>Programme Health</h2>
        <asp:Repeater ID="healthRepeater" runat="server">
            <ItemTemplate>
                <div class="bar-chart-row" style="grid-template-columns: 160px 90px 1fr;">
                    <div class="bar-chart-label"><%# Eval("Area") %></div>
                    <div><%# GetRagBadge((string)Eval("Rag")) %></div>
                    <div class="bar-chart-value" style="text-align: left;"><%# Eval("Commentary") %></div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
    </div>

    <div class="two-col">
        <div class="card">
            <h2>Migration progress by department</h2>
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
            <h2>Page delivery</h2>
            <p><asp:Literal ID="pageDeliverySummaryLiteral" runat="server" /></p>
            <p><a href="Pages.aspx">Open People &amp; Pages &rarr;</a></p>
        </div>
    </div>

    <div class="card">
        <h2>Attention required</h2>
        <asp:GridView ID="attentionGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="Category" HeaderText="Type" />
                <asp:BoundField DataField="Description" HeaderText="Description" />
                <asp:BoundField DataField="Owner" HeaderText="Owner" />
                <asp:TemplateField HeaderText="RAG">
                    <ItemTemplate>
                        <%# GetRagBadge((string)Eval("Rag")) %>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <div class="card">
        <h2>Next migrations</h2>
        <asp:GridView ID="nextMigrationsGrid" runat="server" CssClass="data-table" AutoGenerateColumns="false" GridLines="None">
            <Columns>
                <asp:BoundField DataField="SiteTitle" HeaderText="Site" />
                <asp:BoundField DataField="Department" HeaderText="Department" />
                <asp:BoundField DataField="PlannedMigration" HeaderText="Planned Migration" DataFormatString="{0:yyyy-MM-dd}" />
                <asp:TemplateField HeaderText="Readiness">
                    <ItemTemplate>
                        <%# GetRagBadge((string)Eval("Readiness")) %>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
