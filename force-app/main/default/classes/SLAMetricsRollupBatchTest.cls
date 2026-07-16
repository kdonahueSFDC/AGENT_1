@isTest
private class SLAMetricsRollupBatchTest {
  @TestSetup
  static void setup() {
    // Create test data - will be resolved "today" for testing
    DateTime now = DateTime.now();

    List<IT_Request__c> requests = new List<IT_Request__c>();

    // Tier 1: 5 Met, 2 Missed (7 total)
    for (Integer i = 0; i < 7; i++) {
      IT_Request__c req = new IT_Request__c(
        Employee_Name__c = 'Test User',
        Issue_Description__c = 'Test Issue Tier1 ' + i,
        Priority__c = 'Low',
        Status__c = 'Resolved',
        Assigned_Tier__c = 'Tier 1',
        Due_By__c = (i < 5 ? now.addHours(70) : now.addHours(-10)),
        Resolved_At__c = now
      );
      requests.add(req);
    }

    // Tier 2: 10 Met, 3 Missed (13 total)
    for (Integer i = 0; i < 13; i++) {
      IT_Request__c req = new IT_Request__c(
        Employee_Name__c = 'Test User',
        Issue_Description__c = 'Test Issue Tier2 ' + i,
        Priority__c = 'High',
        Status__c = 'Resolved',
        Assigned_Tier__c = 'Tier 2',
        Due_By__c = (i < 10 ? now.addHours(8) : now.addHours(-4)),
        Resolved_At__c = now
      );
      requests.add(req);
    }

    // Tier 3: 2 Met, 8 Missed (10 total)
    for (Integer i = 0; i < 10; i++) {
      IT_Request__c req = new IT_Request__c(
        Employee_Name__c = 'Test User',
        Issue_Description__c = 'Test Issue Tier3 ' + i,
        Priority__c = 'Critical',
        Status__c = 'Resolved',
        Assigned_Tier__c = 'Tier 3',
        Due_By__c = (i < 2 ? now.addHours(4) : now.addHours(-2)),
        Resolved_At__c = now
      );
      requests.add(req);
    }

    // Add unresolved request (should be excluded)
    IT_Request__c unresolvedRequest = new IT_Request__c(
      Employee_Name__c = 'Test User',
      Issue_Description__c = 'Unresolved',
      Priority__c = 'Low',
      Status__c = 'New',
      Assigned_Tier__c = 'Tier 1',
      Due_By__c = now.addHours(72)
    );
    requests.add(unresolvedRequest);

    insert requests;
  }

  @isTest
  static void testBatchExecution() {
    // Execute the batch for today (since test data was created today)
    Date today = Date.today();

    Test.startTest();
    SLAMetricsRollupBatch batch = new SLAMetricsRollupBatch(today);
    Database.executeBatch(batch, 200);
    Test.stopTest();

    // Query results
    List<SLA_Metrics__c> metrics = [
      SELECT
        Metric_Date__c,
        Tier__c,
        Total_Requests__c,
        Breached_Count__c,
        Met_Count__c,
        Missed_Count__c,
        Avg_Resolution_Hours__c,
        Breach_Percentage__c
      FROM SLA_Metrics__c
      ORDER BY Tier__c
    ];

    // Should have 3 records (one per tier)
    System.assertEquals(3, metrics.size(), 'Should have 3 metric records');

    // Tier 1 assertions
    SLA_Metrics__c tier1 = metrics[0];
    System.assertEquals(today, tier1.Metric_Date__c, 'Tier 1 date');
    System.assertEquals('Tier 1', tier1.Tier__c, 'Tier 1 tier');
    System.assertEquals(7, tier1.Total_Requests__c, 'Tier 1 total');
    System.assertEquals(2, tier1.Breached_Count__c, 'Tier 1 breached');
    System.assertEquals(5, tier1.Met_Count__c, 'Tier 1 met');
    System.assertEquals(2, tier1.Missed_Count__c, 'Tier 1 missed');
    System.assertNotEquals(
      null,
      tier1.Avg_Resolution_Hours__c,
      'Tier 1 avg should be calculated'
    );
    System.assertNotEquals(
      null,
      tier1.Breach_Percentage__c,
      'Tier 1 breach % should be calculated'
    );

    // Tier 2 assertions
    SLA_Metrics__c tier2 = metrics[1];
    System.assertEquals(today, tier2.Metric_Date__c, 'Tier 2 date');
    System.assertEquals('Tier 2', tier2.Tier__c, 'Tier 2 tier');
    System.assertEquals(13, tier2.Total_Requests__c, 'Tier 2 total');
    System.assertEquals(3, tier2.Breached_Count__c, 'Tier 2 breached');
    System.assertEquals(10, tier2.Met_Count__c, 'Tier 2 met');
    System.assertEquals(3, tier2.Missed_Count__c, 'Tier 2 missed');

    // Tier 3 assertions
    SLA_Metrics__c tier3 = metrics[2];
    System.assertEquals(today, tier3.Metric_Date__c, 'Tier 3 date');
    System.assertEquals('Tier 3', tier3.Tier__c, 'Tier 3 tier');
    System.assertEquals(10, tier3.Total_Requests__c, 'Tier 3 total');
    System.assertEquals(8, tier3.Breached_Count__c, 'Tier 3 breached');
    System.assertEquals(2, tier3.Met_Count__c, 'Tier 3 met');
    System.assertEquals(8, tier3.Missed_Count__c, 'Tier 3 missed');
  }

  @isTest
  static void testUpsertBehavior() {
    // Test that running batch twice for same date updates existing records
    Date today = Date.today();

    Test.startTest();
    // First run
    SLAMetricsRollupBatch batch1 = new SLAMetricsRollupBatch(today);
    Database.executeBatch(batch1, 200);
    Test.stopTest();

    // Verify 3 records created
    Integer recordCount = [SELECT COUNT() FROM SLA_Metrics__c];
    System.assertEquals(3, recordCount, 'First run should create 3 records');

    // Second run (outside test context for synchronous execution)
    SLAMetricsRollupBatch batch2 = new SLAMetricsRollupBatch(today);
    Database.executeBatch(batch2, 200);

    // Should still have 3 records (upserted, not duplicated)
    recordCount = [SELECT COUNT() FROM SLA_Metrics__c];
    System.assertEquals(
      3,
      recordCount,
      'Second run should upsert, not duplicate'
    );
  }

  @isTest
  static void testEmptyResult() {
    // Test with a date that has no resolved requests
    Date futureDate = Date.today().addDays(10);

    Test.startTest();
    SLAMetricsRollupBatch batch = new SLAMetricsRollupBatch(futureDate);
    Database.executeBatch(batch, 200);
    Test.stopTest();

    // Should have no records created
    Integer recordCount = [SELECT COUNT() FROM SLA_Metrics__c];
    System.assertEquals(0, recordCount, 'No records for future date');
  }

  @isTest
  static void testDefaultConstructor() {
    // Default constructor processes yesterday, but our test data is today
    // So this should return 0 records
    Test.startTest();
    SLAMetricsRollupBatch batch = new SLAMetricsRollupBatch();
    Database.executeBatch(batch, 200);
    Test.stopTest();

    // Should have 0 records (test data is for today, batch processes yesterday)
    Integer recordCount = [SELECT COUNT() FROM SLA_Metrics__c];
    System.assertEquals(0, recordCount, 'Default should process yesterday');
  }

  @isTest
  static void testSchedulableWrapper() {
    // Test the schedulable class that wraps the batch
    Test.startTest();
    SLAMetricsRollupSchedulable schedulable = new SLAMetricsRollupSchedulable();
    String cronExp = '0 0 0 * * ?'; // Daily at midnight
    System.schedule('Test SLA Metrics Rollup', cronExp, schedulable);
    Test.stopTest();

    // Verify job was scheduled
    List<CronTrigger> jobs = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'Test SLA Metrics Rollup'
    ];
    System.assertEquals(1, jobs.size(), 'Job should be scheduled');
  }

  @isTest
  static void testBulkProcessing() {
    // Test that batch handles bulk data correctly
    Date today = Date.today();

    Test.startTest();
    SLAMetricsRollupBatch batch = new SLAMetricsRollupBatch(today);
    Database.executeBatch(batch, 200);
    Test.stopTest();

    // Verify aggregation worked correctly across all records
    SLA_Metrics__c tier1 = [
      SELECT Total_Requests__c, Breached_Count__c, Met_Count__c
      FROM SLA_Metrics__c
      WHERE Tier__c = 'Tier 1'
    ];
    System.assertEquals(
      7,
      tier1.Total_Requests__c,
      'Bulk: Tier 1 should aggregate 7 requests'
    );
    System.assertEquals(
      5,
      tier1.Met_Count__c,
      'Bulk: Tier 1 should have 5 met'
    );
    System.assertEquals(
      2,
      tier1.Breached_Count__c,
      'Bulk: Tier 1 should have 2 breached'
    );
  }
}
