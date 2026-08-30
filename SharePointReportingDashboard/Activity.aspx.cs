using System;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class ActivityPage : Page
    {
        protected GridView activityGrid;
        protected Repeater topContributorsRepeater;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var activity = service.GetRecentActivity(50);

            activityGrid.DataSource = activity;
            activityGrid.DataBind();

            var contributors = activity
                .GroupBy(a => a.UserName)
                .Select(g => new { UserName = g.Key, Count = g.Count() })
                .OrderByDescending(g => g.Count)
                .Take(6)
                .ToList();

            var maxCount = contributors.Count > 0 ? contributors.Max(c => c.Count) : 1;

            topContributorsRepeater.DataSource = contributors.Select(c => new
            {
                Label = c.UserName,
                ValueText = c.Count + (c.Count == 1 ? " action" : " actions"),
                PercentWidth = Math.Round((double)c.Count / maxCount * 100, 1)
            }).ToList();
            topContributorsRepeater.DataBind();
        }
    }
}
