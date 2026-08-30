using System;

namespace SharePointReportingDashboard.Models
{
    public class ListSummary
    {
        public string SiteTitle { get; set; }
        public string ListName { get; set; }
        public string ListType { get; set; }
        public int ItemCount { get; set; }
        public double SizeMb { get; set; }
        public DateTime LastModifiedUtc { get; set; }
    }
}
