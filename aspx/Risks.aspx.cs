using System;
using System.Linq;
using System.Collections.Generic;
using SharePointPmDashboard.App_Code;

public partial class RisksPage : System.Web.UI.Page
{
    public string SeverityChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        SeverityChartDataJson = "[['Severity','Count']]";

        var data = DashboardDataProvider.Load();
        ((SiteMaster)Master).ShowStatus(data.IsLive, data.LoadError);

        RisksGrid.DataSource = data.Risks;
        RisksGrid.DataBind();

        var severityCounts = data.Risks
            .GroupBy(r => r.Severity ?? "")
            .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
            .OrderByDescending(kv => kv.Value)
            .ToList();

        SeverityChartDataJson = ChartData.ToJsArray("Severity", "Count", severityCounts);
    }
}
