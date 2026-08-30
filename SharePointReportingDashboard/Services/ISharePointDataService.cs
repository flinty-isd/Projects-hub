using System.Collections.Generic;
using SharePointReportingDashboard.Models;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Everything the dashboard pages need from SharePoint. Implement this
    /// against CSOM/PnP for a real tenant; MockSharePointDataService is the
    /// only implementation shipped today.
    /// </summary>
    public interface ISharePointDataService
    {
        DashboardStats GetDashboardStats();
        List<SiteSummary> GetSites();
        List<ListSummary> GetLists(string siteTitle);
        List<ActivityRecord> GetRecentActivity(int count);
        List<PermissionEntry> GetPermissions();
    }
}
