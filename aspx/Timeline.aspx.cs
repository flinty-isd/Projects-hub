using System;
using System.Collections.Generic;
using System.Linq;
using SharePointPmDashboard.App_Code;

public partial class TimelinePage : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        var data = DashboardDataProvider.Load();
        ((SiteMaster)Master).ShowStatus(data.IsLive, data.LoadError);

        var filteredTasks = FilterState.Apply(Session, data.Tasks);
        var dated = filteredTasks.Where(t => t.StartDate.HasValue && t.DueDate.HasValue).ToList();

        if (dated.Count == 0)
        {
            EmptyMessage.Visible = true;
            TimelineRepeater.DataSource = new List<object>();
            TimelineRepeater.DataBind();
            return;
        }

        var minDate = dated.Min(t => t.StartDate.Value);
        var maxDate = dated.Max(t => t.DueDate.Value);
        var totalDays = Math.Max(1.0, (maxDate - minDate).TotalDays);

        var rows = dated.Select(t => new
        {
            Title = t.Title,
            Status = t.Status,
            StatusClass = (t.Status ?? "").Replace(" ", "").ToLowerInvariant(),
            OffsetPercent = Math.Round((t.StartDate.Value - minDate).TotalDays / totalDays * 100, 1),
            WidthPercent = Math.Max(1.0, Math.Round((t.DueDate.Value - t.StartDate.Value).TotalDays / totalDays * 100, 1)),
        }).ToList();

        TimelineRepeater.DataSource = rows;
        TimelineRepeater.DataBind();
    }
}
