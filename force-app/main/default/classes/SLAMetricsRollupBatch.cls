/**
 * Batch job to calculate and rollup daily SLA metrics by tier.
 * Queries resolved IT Requests from a specific date (default: yesterday)
 * and aggregates metrics into SLA_Metrics__c records.
 *
 * Schedule: Daily at midnight via SLAMetricsRollupSchedulable
 * Scope: 200 records per batch (standard best practice)
 */
public class SLAMetricsRollupBatch implements Database.Batchable<sObject>, Database.Stateful {
  private Date metricsDate;
  // Map to accumulate metrics by tier across batches
  private Map<String, TierMetrics> tierMetricsMap = new Map<String, TierMetrics>();

  /**
   * Inner class to hold metrics per tier
   */
  private class TierMetrics {
    public Decimal totalCount = 0;
    public Decimal totalResolutionHours = 0;
    public Decimal metCount = 0;
    public Decimal missedCount = 0;
  }

  /**
   * Default constructor - processes yesterday's data
   */
  public SLAMetricsRollupBatch() {
    this.metricsDate = Date.today().addDays(-1);
  }

  /**
   * Constructor with explicit date
   * @param metricsDate The date for which to calculate metrics
   */
  public SLAMetricsRollupBatch(Date metricsDate) {
    this.metricsDate = metricsDate;
  }

  /**
   * Start method - returns query locator for resolved requests
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    // Calculate date range for the target date (midnight to midnight)
    DateTime startDateTime = DateTime.newInstance(
      metricsDate.year(),
      metricsDate.month(),
      metricsDate.day(),
      0,
      0,
      0
    );
    DateTime endDateTime = startDateTime.addDays(1);

    // Query resolved requests from the target date
    return Database.getQueryLocator(
      [
        SELECT Assigned_Tier__c, SLA_Status__c, Time_To_Resolution_Hours__c
        FROM IT_Request__c
        WHERE
          Resolved_At__c >= :startDateTime
          AND Resolved_At__c < :endDateTime
          AND Status__c = 'Resolved'
          AND Assigned_Tier__c != NULL
        WITH USER_MODE
      ]
    );
  }

  /**
   * Execute method - accumulates metrics across all batches
   */
  public void execute(Database.BatchableContext bc, List<IT_Request__c> scope) {
    for (IT_Request__c request : scope) {
      String tier = request.Assigned_Tier__c;

      // Initialize tier metrics if needed
      if (!tierMetricsMap.containsKey(tier)) {
        tierMetricsMap.put(tier, new TierMetrics());
      }

      TierMetrics metrics = tierMetricsMap.get(tier);

      // Increment counters
      metrics.totalCount++;
      metrics.totalResolutionHours += (request.Time_To_Resolution_Hours__c !=
        null
        ? request.Time_To_Resolution_Hours__c
        : 0);

      if (request.SLA_Status__c == 'Met') {
        metrics.metCount++;
      } else if (request.SLA_Status__c == 'Missed') {
        metrics.missedCount++;
      }
    }
  }

  /**
   * Finish method - upserts accumulated metrics
   */
  public void finish(Database.BatchableContext bc) {
    List<SLA_Metrics__c> metricsToUpsert = new List<SLA_Metrics__c>();

    for (String tier : tierMetricsMap.keySet()) {
      TierMetrics metrics = tierMetricsMap.get(tier);

      // Calculate average resolution time
      Decimal avgResolution = 0;
      if (metrics.totalCount > 0) {
        avgResolution = metrics.totalResolutionHours / metrics.totalCount;
        avgResolution = avgResolution.setScale(2, RoundingMode.HALF_UP);
      }

      // Create unique key for upsert
      String uniqueKey = String.valueOf(metricsDate) + '-' + tier;

      // Create metrics record (will be upserted on Unique_Key__c)
      SLA_Metrics__c metric = new SLA_Metrics__c(
        Metric_Date__c = metricsDate,
        Tier__c = tier,
        Unique_Key__c = uniqueKey,
        Total_Requests__c = metrics.totalCount,
        Met_Count__c = metrics.metCount,
        Missed_Count__c = metrics.missedCount,
        Breached_Count__c = metrics.missedCount,
        Avg_Resolution_Hours__c = avgResolution
      );

      metricsToUpsert.add(metric);
    }

    // Upsert using external ID field (Unique_Key__c = Date + Tier)
    if (!metricsToUpsert.isEmpty()) {
      try {
        Database.UpsertResult[] results = Database.upsert(
          metricsToUpsert,
          SLA_Metrics__c.Unique_Key__c,
          false
        );

        // Log any failures
        for (Integer i = 0; i < results.size(); i++) {
          if (!results[i].isSuccess()) {
            String errorMsg =
              'Failed to upsert SLA_Metrics__c for ' +
              metricsToUpsert[i].Tier__c +
              ' on ' +
              metricsToUpsert[i].Metric_Date__c +
              ': ';
            for (Database.Error err : results[i].getErrors()) {
              errorMsg += err.getMessage() + ' ';
            }
            System.debug(LoggingLevel.ERROR, errorMsg);
          }
        }
      } catch (DmlException e) {
        System.debug(
          LoggingLevel.ERROR,
          'DML Exception in SLAMetricsRollupBatch: ' + e.getMessage()
        );
        throw e;
      }
    }

    System.debug(
      'SLAMetricsRollupBatch completed for date: ' +
        metricsDate +
        ', processed ' +
        metricsToUpsert.size() +
        ' tiers'
    );
  }
}
