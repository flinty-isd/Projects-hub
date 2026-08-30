using System;
using System.Text;
using SharePointPmDashboard.App_Code;

public partial class KpisPage : System.Web.UI.Page
{
    public int TotalTasks { get; set; }
    public double AvgPercentComplete { get; set; }
    public int OverdueTasks { get; set; }
    public int OpenRisks { get; set; }
    public string OwnerChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        OwnerChartDataJson = "[['Owner','Count']]";

        var data = DashboardDataProvider.Load();
        ((SiteMaster)Master).ShowStatus(data.IsLive, data.LoadError);

        var filteredTasks = FilterState.Apply(Session, data.Tasks);

        TotalTasks = filteredTasks.Count;
        AvgPercentComplete = Kpis.AveragePercentComplete(filteredTasks);
        OverdueTasks = Kpis.OverdueCount(filteredTasks, DateTime.Now);
        OpenRisks = Kpis.OpenRiskCount(data.Risks);

        var ownerCounts = Kpis.TasksByOwner(filteredTasks);
        var sb = new StringBuilder("[['Owner','Count']");
        foreach (var kv in ownerCounts)
        {
            sb.Append(",['").Append(kv.Key.Replace("'", "\\'")).Append("',").Append(kv.Value).Append("]");
        }
        sb.Append("]");
        OwnerChartDataJson = sb.ToString();
    }
}
