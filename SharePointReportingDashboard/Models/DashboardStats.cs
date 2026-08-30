using System;

namespace SharePointReportingDashboard.Models
{
    public class DashboardStats
    {
        public int TotalSites { get; set; }
        public int TotalLists { get; set; }
        public int TotalItems { get; set; }
        public double TotalStorageMb { get; set; }
        public int ActiveUsers30Days { get; set; }
        public DateTime GeneratedAtUtc { get; set; }
    }
}
