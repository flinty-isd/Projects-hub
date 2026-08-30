using System;

namespace SharePointReportingDashboard.Models
{
    public class ActivityRecord
    {
        public DateTime TimestampUtc { get; set; }
        public string UserName { get; set; }
        public string Action { get; set; }
        public string ItemName { get; set; }
        public string ListName { get; set; }
        public string SiteTitle { get; set; }
    }
}
