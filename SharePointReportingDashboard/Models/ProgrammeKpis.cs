namespace SharePointReportingDashboard.Models
{
    /// <summary>Programme KPIs shown on the Programme Control Centre (Implementation Specification 3.1).</summary>
    public class ProgrammeKpis
    {
        public int SitesComplete { get; set; }
        public int RemainingSites { get; set; }
        public string OverallRag { get; set; }
        public int PagesOutstanding { get; set; }
        public int OverdueActions { get; set; }
        public bool LmsBlocked { get; set; }
    }
}
