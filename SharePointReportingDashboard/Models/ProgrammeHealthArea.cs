namespace SharePointReportingDashboard.Models
{
    /// <summary>One row of the Programme Health view (Implementation Specification 3.1) - Schedule, Scope, Technical, Resources, Business Readiness.</summary>
    public class ProgrammeHealthArea
    {
        public string Area { get; set; }
        public string Rag { get; set; }
        public string Commentary { get; set; }
    }
}
