using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using ItGovernanceSite.App_Code;

public partial class RiskRegisterPage : System.Web.UI.Page
{
    public int TotalRisks { get; set; }
    public int HighRisks { get; set; }
    public string CategoryChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        CategoryChartDataJson = "[]";

        var data = DashboardDataProvider.Load();
        Master.ShowStatus(data.IsLive, data.LoadError);

        var risks = data.Risks.OrderByDescending(r => r.Score).ThenBy(r => r.Title).ToList();

        RisksGrid.DataSource = risks;
        RisksGrid.DataBind();

        TotalRisks = risks.Count;
        HighRisks = GovernanceKpis.HighRiskCount(risks);
        CategoryChartDataJson = ChartData.ToJsArray("Category", "Count", GovernanceKpis.RisksByCategory(risks));

        HeatMapRows.Text = BuildHeatMap(risks);
    }

    /// <summary>Renders a 5x5 likelihood (rows, 5 at top) by impact (columns) grid,
    /// counting open risks in each cell.</summary>
    private static string BuildHeatMap(List<GovernanceRiskItem> risks)
    {
        var open = risks
            .Where(r => !string.Equals(r.Status, "Closed", StringComparison.OrdinalIgnoreCase))
            .ToList();

        var sb = new StringBuilder();
        sb.Append("<tr><th></th>");
        for (var impact = 1; impact <= 5; impact++)
        {
            sb.Append("<th class=\"axis-label\">I").Append(impact).Append("</th>");
        }
        sb.Append("</tr>");

        for (var likelihood = 5; likelihood >= 1; likelihood--)
        {
            sb.Append("<tr><th class=\"axis-label\">L").Append(likelihood).Append("</th>");
            for (var impact = 1; impact <= 5; impact++)
            {
                var l = likelihood;
                var i = impact;
                var cellRisks = open.Where(r => r.Likelihood == l && r.Impact == i).ToList();
                var score = likelihood * impact;
                var tooltip = cellRisks.Count == 0
                    ? ""
                    : " title=\"" + HttpUtility.HtmlAttributeEncode(
                        string.Join("; ", cellRisks.Select(r => r.Title))) + "\"";

                sb.Append("<td class=\"").Append(HeatClass(score)).Append("\"").Append(tooltip).Append(">");
                if (cellRisks.Count > 0)
                {
                    sb.Append("<span class=\"heat-count\">").Append(cellRisks.Count).Append("</span>");
                }
                sb.Append("</td>");
            }
            sb.Append("</tr>");
        }
        return sb.ToString();
    }

    private static string HeatClass(int score)
    {
        if (score >= 15) return "heat-extreme";
        if (score >= 10) return "heat-high";
        if (score >= 5) return "heat-moderate";
        return "heat-low";
    }
}
