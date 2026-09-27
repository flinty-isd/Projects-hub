import * as React from 'react';
import styles from './ProgrammeOverview.module.scss';
import type { IProgrammeOverviewProps } from './IProgrammeOverviewProps';
import type { IAttentionItem, IControlCentreKpis, Rag } from '../../../common/models';

function ragClass(rag: Rag): string {
  switch (rag) {
    case 'Red': return styles.ragRed;
    case 'Amber': return styles.ragAmber;
    default: return styles.ragGreen;
  }
}

export default function ProgrammeOverview(props: IProgrammeOverviewProps): React.ReactElement<IProgrammeOverviewProps> {
  const { title, dataService } = props;

  const [kpis, setKpis] = React.useState<IControlCentreKpis | undefined>(undefined);
  const [attention, setAttention] = React.useState<IAttentionItem[] | undefined>(undefined);
  const [error, setError] = React.useState<string | undefined>(undefined);

  React.useEffect(() => {
    let cancelled = false;

    Promise.all([dataService.getKpis(), dataService.getAttentionItems()])
      .then(([kpiResult, attentionResult]) => {
        if (cancelled) { return; }
        setKpis(kpiResult);
        setAttention(attentionResult);
      })
      .catch((err: Error) => {
        if (cancelled) { return; }
        setError(err.message);
      });

    return () => { cancelled = true; };
  }, [dataService]);

  return (
    <div className={styles.programmeOverview}>
      <h2 className={styles.title}>{title}</h2>

      {error && <div className={styles.error}>Could not load Control Centre data: {error}</div>}

      {!error && !kpis && <div className={styles.loading}>Loading&hellip;</div>}

      {kpis && (
        <div className={styles.kpiGrid}>
          <div className={styles.kpiTile}>
            <div className={styles.kpiValue}>{kpis.sitesComplete}</div>
            <div className={styles.kpiLabel}>Sites Complete (baseline)</div>
          </div>
          <div className={styles.kpiTile}>
            <div className={styles.kpiValue}>{kpis.remainingSites}</div>
            <div className={styles.kpiLabel}>Remaining Sites</div>
          </div>
          <div className={styles.kpiTile}>
            <div className={styles.kpiValue}>{kpis.pagesOutstanding}</div>
            <div className={styles.kpiLabel}>Pages Outstanding</div>
          </div>
          <div className={styles.kpiTile}>
            <div className={styles.kpiValue}>{kpis.overdueActions}</div>
            <div className={styles.kpiLabel}>Overdue Actions</div>
          </div>
        </div>
      )}

      {attention && (
        <div>
          <h3 className={styles.sectionHeading}>Attention required</h3>
          {attention.length === 0 ? (
            <div className={styles.emptyState}>No exceptions outstanding.</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Description</th>
                  <th>Owner</th>
                  <th>RAG</th>
                </tr>
              </thead>
              <tbody>
                {attention.map((item, index) => (
                  <tr key={index}>
                    <td>{item.category}</td>
                    <td>{item.description}</td>
                    <td>{item.owner}</td>
                    <td><span className={`${styles.ragBadge} ${ragClass(item.rag)}`}>{item.rag}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
