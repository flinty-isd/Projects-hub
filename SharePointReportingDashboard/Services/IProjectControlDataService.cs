using System.Collections.Generic;
using SharePointReportingDashboard.Models;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Everything the Control Centre pages need, mapped 1:1 to the six
    /// authoritative SharePoint Lists in the Implementation Specification
    /// (Migration Register, Page Delivery Register, Actions, RAID,
    /// Decisions, Project Updates). Implement this against SharePoint
    /// (CSOM/PnP/Graph) for the real tenant; MockProjectControlDataService
    /// is the only implementation shipped today.
    /// </summary>
    public interface IProjectControlDataService
    {
        ProgrammeKpis GetProgrammeKpis();
        List<ProgrammeHealthArea> GetProgrammeHealth();
        List<MigrationSite> GetMigrationSites();
        List<PageDeliveryItem> GetPageDeliveryItems();
        List<ActionItem> GetActions();
        List<RaidItem> GetRaidItems();
        List<Decision> GetDecisions();
        ProjectUpdateSnapshot GetLatestSnapshot();
        List<ProjectUpdateSnapshot> GetSnapshotHistory();
    }
}
