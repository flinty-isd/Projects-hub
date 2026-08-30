using System;
using System.Linq;
using System.Text;
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
            .Select(g => new { Severity = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .ToList();

        var sb = new StringBuilder("[['Severity','Count']");
        foreach (var sc in severityCounts)
        {
            sb.Append(",['").Append(sc.Severity.Replace("'", "\\'")).Append("',").Append(sc.Count).Append("]");
        }
        sb.Append("]");
        SeverityChartDataJson = sb.ToString();
    }
}
