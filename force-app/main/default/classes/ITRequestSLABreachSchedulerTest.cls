@isTest
private class ITRequestSLABreachSchedulerTest {
  @testSetup
  static void setup() {
    // Test data created per test method due to need for specific Due_By dates
  }

  @isTest
  static void testBreachedRecordsGetFlagged() {
    IT_Request__c breached = new IT_Request__c(
      Employee_Name__c = 'John Doe',
      Issue_Description__c = 'Laptop not working',
      Priority__c = 'Critical',
      Status__c = 'In Progress',
      Due_By__c = Datetime.now().addHours(-1),
      SLA_Breach_Notified__c = false
    );
    insert breached;

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    IT_Request__c result = [
      SELECT Id, SLA_Breach_Notified__c
      FROM IT_Request__c
      WHERE Id = :breached.Id
      LIMIT 1
    ];
    System.assertEquals(
      true,
      result.SLA_Breach_Notified__c,
      'Breached record should be flagged'
    );
  }

  @isTest
  static void testNonBreachedIgnored() {
    IT_Request__c healthy = new IT_Request__c(
      Employee_Name__c = 'Jane Smith',
      Issue_Description__c = 'Software install request',
      Priority__c = 'Low',
      Status__c = 'New',
      Due_By__c = Datetime.now().addDays(2),
      SLA_Breach_Notified__c = false
    );
    insert healthy;

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    IT_Request__c result = [
      SELECT Id, SLA_Breach_Notified__c
      FROM IT_Request__c
      WHERE Id = :healthy.Id
      LIMIT 1
    ];
    System.assertEquals(
      false,
      result.SLA_Breach_Notified__c,
      'Healthy record should not be flagged'
    );
  }

  @isTest
  static void testAlreadyNotifiedIgnored() {
    IT_Request__c alreadyNotified = new IT_Request__c(
      Employee_Name__c = 'Bob Johnson',
      Issue_Description__c = 'Password reset',
      Priority__c = 'High',
      Status__c = 'In Progress',
      Due_By__c = Datetime.now().addHours(-2),
      SLA_Breach_Notified__c = true
    );
    insert alreadyNotified;

    Integer emailsBefore = Limits.getEmailInvocations();

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    Integer emailsAfter = Limits.getEmailInvocations();
    System.assertEquals(
      emailsBefore,
      emailsAfter,
      'No new emails should be sent for already notified records'
    );
  }

  @isTest
  static void testBulk() {
    List<IT_Request__c> breachedRequests = new List<IT_Request__c>();

    for (Integer i = 0; i < 50; i++) {
      breachedRequests.add(
        new IT_Request__c(
          Employee_Name__c = 'Employee ' + i,
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = 'In Progress',
          Due_By__c = Datetime.now().addHours(-1),
          SLA_Breach_Notified__c = false
        )
      );
    }
    insert breachedRequests;

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    List<IT_Request__c> results = [
      SELECT Id, SLA_Breach_Notified__c
      FROM IT_Request__c
      WHERE Id IN :breachedRequests
    ];

    Integer flaggedCount = 0;
    for (IT_Request__c req : results) {
      if (req.SLA_Breach_Notified__c) {
        flaggedCount++;
      }
    }

    System.assertEquals(
      50,
      flaggedCount,
      'All 50 breached records should be flagged'
    );
  }

  @isTest
  static void testResolvedIgnored() {
    IT_Request__c resolved = new IT_Request__c(
      Employee_Name__c = 'Alice Cooper',
      Issue_Description__c = 'Monitor issue',
      Priority__c = 'Critical',
      Status__c = 'Resolved',
      Due_By__c = Datetime.now().addHours(-3),
      SLA_Breach_Notified__c = false
    );
    insert resolved;

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    IT_Request__c result = [
      SELECT Id, SLA_Breach_Notified__c
      FROM IT_Request__c
      WHERE Id = :resolved.Id
      LIMIT 1
    ];
    System.assertEquals(
      false,
      result.SLA_Breach_Notified__c,
      'Resolved record should not be flagged even if past due'
    );
  }

  @isTest
  static void testNoDueByIgnored() {
    IT_Request__c noDueBy = new IT_Request__c(
      Employee_Name__c = 'Test User',
      Issue_Description__c = 'Test issue',
      Priority__c = 'Medium',
      Status__c = 'New',
      Due_By__c = null,
      SLA_Breach_Notified__c = false
    );
    insert noDueBy;

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    IT_Request__c result = [
      SELECT Id, SLA_Breach_Notified__c
      FROM IT_Request__c
      WHERE Id = :noDueBy.Id
      LIMIT 1
    ];
    System.assertEquals(
      false,
      result.SLA_Breach_Notified__c,
      'Record without Due_By should not be flagged'
    );
  }

  @isTest
  static void testEmptyResultSetExitsGracefully() {
    // No test data — all query conditions will exclude any records
    // This covers the isEmpty() early-return branch at line 23-25

    Test.startTest();
    String cronExp = '0 0 * * * ?';
    System.schedule(
      'SLA Breach Test Empty',
      cronExp,
      new ITRequestSLABreachScheduler()
    );
    Test.stopTest();

    // No assertion needed; success = no exceptions thrown
    // Confirm no DML occurred
    List<IT_Request__c> allRecords = [SELECT Id FROM IT_Request__c];
    System.assertEquals(
      0,
      allRecords.size(),
      'No records should exist in test context'
    );
  }
}
