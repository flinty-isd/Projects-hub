using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class DefaultPage : Page
    {
        protected Repeater statsRepeater;
        protected Repeater healthRepeater;
        protected Repeater departmentProgressRepeater;
        protected Literal overallRagLiteral;
        protected Literal pageDeliverySummaryLiteral;
        protected GridView attentionGrid;
        protected GridView nextMigrationsGrid;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var kpis = service.GetProgrammeKpis();
            var health = service.GetProgrammeHealth();
            var sites = service.GetMigrationSites();
            var pages = service.GetPageDeliveryItems();
            var actions = service.GetActions();
            var raid = service.GetRaidItems();
            var decisions = service.GetDecisions();

            statsRepeater.DataSource = new[]
            {
                new StatTile { Value = kpis.SitesComplete.ToString(), Label = "Sites Complete (baseline)" },
                new StatTile { Value = kpis.RemainingSites.ToString(), Label = "Remaining Sites (sample)" },
                new StatTile { Value = kpis.PagesOutstanding.ToString(), Label = "Pages Outstanding" },
                new StatTile { Value = kpis.OverdueActions.ToString(), Label = "Overdue Actions" }
            };
            statsRepeater.DataBind();

            overallRagLiteral.Text = GetRagBadge(kpis.OverallRag);

            healthRepeater.DataSource = health;
            healthRepeater.DataBind();

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

            var inBuild = pages.Count(p => p.DeliveryStatus == "Build" || p.DeliveryStatus == "Content" || p.DeliveryStatus == "Design");
            var awaitingUatOrSignOff = pages.Count(p => p.DeliveryStatus == "UAT" || p.DeliveryStatus == "Sign-off");
            pageDeliverySummaryLiteral.Text = string.Format(
                "{0} pages outstanding &mdash; {1} in build/design/content, {2} awaiting UAT or sign-off. People (PAGE-001) is currently in <strong>Build</strong>.",
                kpis.PagesOutstanding, inBuild, awaitingUatOrSignOff);

            var attention = new List<AttentionRow>();
            attention.AddRange(raid
                .Where(r => r.Rag == "Red" && r.Status == "Open")
                .Select(r => new AttentionRow { Category = "Red RAID", Description = r.Description, Owner = r.Owner, Rag = "Red" }));
            attention.AddRange(actions
                .Where(a => a.IsOverdue)
                .Select(a => new AttentionRow { Category = "Overdue Action", Description = a.Action, Owner = a.Owner, Rag = "Red" }));
            attention.AddRange(sites
                .Where(s => s.Status == "Blocked")
                .Select(s => new AttentionRow { Category = "Blocked Site", Description = s.SiteTitle + " - " + s.BlockerDependency, Owner = s.MigrationOwner, Rag = "Red" }));
            attention.AddRange(decisions
                .Where(d => d.Status == "Pending")
                .Select(d => new AttentionRow { Category = "Decision Required", Description = d.DecisionText, Owner = d.Owner, Rag = "Amber" }));

            attentionGrid.DataSource = attention;
            attentionGrid.DataBind();

            nextMigrationsGrid.DataSource = sites
                .Where(s => s.Status != "Complete" && s.PlannedMigration.HasValue)
                .OrderBy(s => s.PlannedMigration)
                .Take(5)
                .ToList();
            nextMigrationsGrid.DataBind();
        }

        protected string GetRagBadge(string rag)
        {
            var cssClass = rag == "Red" ? "rag-red" : rag == "Amber" ? "rag-amber" : rag == "Green" ? "rag-green" : "rag-grey";
            return "<span class=\"rag-badge " + cssClass + "\">" + (rag ?? "Unknown") + "</span>";
        }

        private class StatTile
        {
            public string Value { get; set; }
            public string Label { get; set; }
        }

        private class BarChartRow
        {
            public string Label { get; set; }
            public string ValueText { get; set; }
            public double PercentWidth { get; set; }
        }

        private class AttentionRow
        {
            public string Category { get; set; }
            public string Description { get; set; }
            public string Owner { get; set; }
            public string Rag { get; set; }
        }
    }
}
