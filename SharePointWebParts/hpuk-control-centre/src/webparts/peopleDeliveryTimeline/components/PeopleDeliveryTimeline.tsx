import * as React from 'react';
import styles from './PeopleDeliveryTimeline.module.scss';
import type { IPeopleDeliveryTimelineProps } from './IPeopleDeliveryTimelineProps';
import { PEOPLE_DELIVERY_STAGES } from '../../../common/models';
import type { IPageDeliveryStatus } from '../../../common/models';

export default function PeopleDeliveryTimeline(props: IPeopleDeliveryTimelineProps): React.ReactElement<IPeopleDeliveryTimelineProps> {
  const { title, pageId, dataService } = props;

  const [status, setStatus] = React.useState<IPageDeliveryStatus | undefined>(undefined);
  const [error, setError] = React.useState<string | undefined>(undefined);

  React.useEffect(() => {
    let cancelled = false;

    dataService.getPageDeliveryStatus(pageId)
      .then((result) => {
        if (!cancelled) { setStatus(result); }
      })
      .catch((err: Error) => {
        if (!cancelled) { setError(err.message); }
      });

    return () => { cancelled = true; };
  }, [dataService, pageId]);

  let currentIndex = -1;
  if (status && status.found) {
    if (status.deliveryStatus === 'Complete') {
      currentIndex = PEOPLE_DELIVERY_STAGES.length; // past the last stage - all done
    } else {
      currentIndex = PEOPLE_DELIVERY_STAGES.indexOf(status.deliveryStatus);
    }
  }

  return (
    <div className={styles.peopleDeliveryTimeline}>
      <h2 className={styles.title}>{title}</h2>

      {error && <div className={styles.error}>Could not load {pageId}: {error}</div>}
      {!error && !status && <div className={styles.loading}>Loading&hellip;</div>}
      {!error && status && !status.found && <div className={styles.error}>No Page Delivery Register item found with Page ID &ldquo;{pageId}&rdquo;.</div>}

      {status && status.found && (
        <React.Fragment>
          <p className={styles.subtitle}>{status.pageName} ({status.pageId}) &mdash; current status: <strong>{status.deliveryStatus}</strong></p>
          <div className={styles.timeline}>
            {PEOPLE_DELIVERY_STAGES.map((stage, index) => {
              const cls = index < currentIndex ? styles.stepDone : index === currentIndex ? styles.stepCurrent : styles.step;
              return (
                <div key={stage} className={`${styles.step} ${cls}`}>
                  {stage}
                </div>
              );
            })}
          </div>
        </React.Fragment>
      )}
    </div>
  );
}
