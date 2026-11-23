<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Timeline.aspx.cs" Inherits="TimelinePage" MasterPageFile="~/Site.Master" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Project timeline</h2>
    <asp:Literal ID="EmptyMessage" runat="server" Visible="false" Text="No tasks with both a start and due date to plot." />
    <asp:Repeater ID="TimelineRepeater" runat="server">
        <ItemTemplate>
            <div class="gantt-row">
                <div class="gantt-label"><%# Eval("Title") %></div>
                <div class="gantt-track">
                    <div class="gantt-bar gantt-<%# Eval("StatusClass") %>"
                         style="left: <%# Eval("OffsetPercent") %>%; width: <%# Eval("WidthPercent") %>%;"
                         title="<%# Eval("Status") %>"></div>
                </div>
            </div>
        </ItemTemplate>
    </asp:Repeater>
</asp:Content>
