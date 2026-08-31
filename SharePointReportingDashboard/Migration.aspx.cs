using System;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class MigrationPage : Page
    {
        protected Repeater departmentProgressRepeater;
        protected GridView next30Grid;
        protected GridView blockedGrid;
        protected GridView remainingGrid;
        protected GridView completedGrid;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var sites = service.GetMigrationSites();

            var departments = sites.Select(s => s.Department).Distinct().OrderBy(d => d);
            departmentProgressRepeater.DataSource = departments.Select(dept =>
            {
                var deptSites = sites.Where(s => s.Department == dept).ToList();
                var completePercent = Math.Round(deptSites.Count(s => s.Status == "Complete") * 100.0 / deptSites.Count, 0);
                return new BarChartRow
                {
                    Label = dept,
                    ValueText = completePercent + "%",
                    PercentWidth = completePercent
                };
            }).ToList();
            departmentProgressRepeater.DataBind();

            var now = DateTime.UtcNow;
            next30Grid.DataSource = sites
                .Where(s => s.PlannedMigration.HasValue && s.PlannedMigration.Value <= now.AddDays(30))
                .OrderBy(s => s.PlannedMigration)
                .ToList();
            next30Grid.DataBind();

            blockedGrid.DataSource = sites
                .Where(s => s.Status == "Blocked" || s.Readiness == "Amber" || s.Readiness == "Red")
                .OrderBy(s => s.Readiness == "Red" ? 0 : 1)
                .ToList();
            blockedGrid.DataBind();

            remainingGrid.DataSource = sites.Where(s => s.Status != "Complete").OrderBy(s => s.SiteId).ToList();
            remainingGrid.DataBind();

            completedGrid.DataSource = sites
                .Where(s => s.Status == "Complete")
                .OrderByDescending(s => s.ActualMigration)
                .ToList();
            completedGrid.DataBind();
        }

        protected string GetRagBadge(string rag)
        {
            var cssClass = rag == "Red" ? "rag-red" : rag == "Amber" ? "rag-amber" : rag == "Green" ? "rag-green" : "rag-grey";
            return "<span class=\"rag-badge " + cssClass + "\">" + (rag ?? "Unknown") + "</span>";
        }

        private class BarChartRow
        {
            public string Label { get; set; }
            public string ValueText { get; set; }
            public double PercentWidth { get; set; }
        }
    }
}
