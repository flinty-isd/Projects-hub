using System;

namespace SharePointReportingDashboard.Models
{
    public class PermissionEntry
    {
        public string SiteTitle { get; set; }
        public string ObjectName { get; set; }
        public string ObjectType { get; set; }
        public string PrincipalName { get; set; }
        public string PrincipalType { get; set; }
        public string PermissionLevel { get; set; }
        public bool InheritsPermissions { get; set; }
        public bool IsExternalUser { get; set; }
    }
}
