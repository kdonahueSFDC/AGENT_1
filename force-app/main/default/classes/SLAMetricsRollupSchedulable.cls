/**
 * Schedulable wrapper for SLAMetricsRollupBatch.
 * Runs daily at midnight to calculate previous day's SLA metrics.
 *
 * Schedule via:
 * System.schedule('Daily SLA Metrics Rollup', '0 0 0 * * ?', new SLAMetricsRollupSchedulable());
 *
 * Or via Setup > Scheduled Jobs
 * Cron: Daily at 12:00 AM
 */
public class SLAMetricsRollupSchedulable implements Schedulable {
  public void execute(SchedulableContext sc) {
    // Execute batch with default (yesterday) date
    SLAMetricsRollupBatch batch = new SLAMetricsRollupBatch();
    Database.executeBatch(batch, 200);
  }
}
