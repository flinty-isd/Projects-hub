using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using ItGovernanceSite.App_Code;

public partial class ExceptionsPage : System.Web.UI.Page
{
    private const int ExpiryWindowDays = 90;

    public int ActiveExceptions { get; set; }
    public int ExpiringSoon { get; set; }
    public string StatusChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        StatusChartDataJson = "[]";

        var data = DashboardDataProvider.Load();
        Master.ShowStatus(data.IsLive, data.LoadError);

        var exceptions = data.Exceptions
            .OrderBy(x => x.ExpiryDate ?? DateTime.MaxValue)
            .ToList();

        ExceptionsGrid.DataSource = exceptions;
        ExceptionsGrid.DataBind();

        var today = DateTime.Today;
        ActiveExceptions = GovernanceKpis.ActiveExceptionCount(exceptions);
        ExpiringSoon = GovernanceKpis.ExpiringSoonCount(exceptions, today, ExpiryWindowDays);

        var byStatus = exceptions
            .GroupBy(x => x.Status ?? "")
            .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
            .OrderByDescending(kv => kv.Value)
            .ToList();
        StatusChartDataJson = ChartData.ToJsArray("Status", "Count", byStatus);
    }

    protected void ExceptionsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType != DataControlRowType.DataRow)
        {
            return;
        }
        var item = e.Row.DataItem as ExceptionItem;
        if (item == null)
        {
            return;
        }

        var today = DateTime.Today;
        var isActive = string.Equals(item.Status, "Active", StringComparison.OrdinalIgnoreCase);
        if (isActive && item.ExpiryDate.HasValue &&
            item.ExpiryDate.Value >= today &&
            item.ExpiryDate.Value <= today.AddDays(ExpiryWindowDays))
        {
            e.Row.Style["background-color"] = "#fffbeb";
            e.Row.Style["color"] = "#92400e";
        }
    }
}
