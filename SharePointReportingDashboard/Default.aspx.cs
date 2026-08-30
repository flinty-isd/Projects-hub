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
        protected Repeater storageChartRepeater;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var stats = service.GetDashboardStats();
            var sites = service.GetSites();

            statsRepeater.DataSource = new[]
            {
                new StatTile { Value = stats.TotalSites.ToString(), Label = "Sites" },
                new StatTile { Value = stats.TotalLists.ToString(), Label = "Lists & Libraries" },
                new StatTile { Value = stats.TotalItems.ToString("N0"), Label = "Items" },
                new StatTile { Value = (stats.TotalStorageMb / 1024.0).ToString("N1") + " GB", Label = "Storage Used" },
                new StatTile { Value = stats.ActiveUsers30Days.ToString(), Label = "Active Users (30d)" }
            };
            statsRepeater.DataBind();

            var maxStorage = sites.Count > 0 ? sites.Max(s => s.StorageUsedMb) : 1;
            if (maxStorage <= 0)
            {
                maxStorage = 1;
            }

            storageChartRepeater.DataSource = sites.Select(s => new BarChartRow
            {
                Label = s.Title,
                ValueText = (s.StorageUsedMb / 1024.0).ToString("N1") + " GB",
                PercentWidth = Math.Round(s.StorageUsedMb / maxStorage * 100, 1)
            }).ToList();
            storageChartRepeater.DataBind();
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
    }
}
