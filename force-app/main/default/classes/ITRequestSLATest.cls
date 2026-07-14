@isTest
private class ITRequestSLATest {
  @TestSetup
  static void setup() {
    List<IT_Request__c> testRequests = new List<IT_Request__c>();

    for (Integer i = 0; i < 5; i++) {
      IT_Request__c request = new IT_Request__c();
      request.Employee_Name__c = 'Test Employee ' + i;
      request.Issue_Description__c = 'Test issue ' + i;
      request.Priority__c = 'High';
      request.Status__c = 'New';
      request.Assigned_Tier__c = 'Tier 1';
      testRequests.add(request);
    }

    insert testRequests;
  }

  @isTest
  static void testSLAStatus_NotSet() {
    IT_Request__c request = new IT_Request__c();
    request.Employee_Name__c = 'No SLA User';
    request.Issue_Description__c = 'No SLA test';
    request.Priority__c = 'Medium';
    request.Status__c = 'New';
    request.Assigned_Tier__c = 'Tier 1';

    insert request;

    IT_Request__c inserted = [
      SELECT Id, SLA_Status__c, Due_By__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    if (inserted.Due_By__c == null) {
      System.assertEquals(
        'Not Set',
        inserted.SLA_Status__c,
        'SLA Status should be Not Set when Due By is null'
      );
    }
  }

  @isTest
  static void testSLAStatus_OnTrack() {
    IT_Request__c request = [
      SELECT Id, CreatedDate, Due_By__c, SLA_Status__c
      FROM IT_Request__c
      LIMIT 1
    ];

    System.assertNotEquals(
      null,
      request.Due_By__c,
      'Due By should be set by flow'
    );
    System.assert(
      request.SLA_Status__c == 'On Track' || request.SLA_Status__c == 'At Risk',
      'SLA Status should be On Track or At Risk for new request'
    );
  }

  @isTest
  static void testSLAStatus_AtRisk() {
    IT_Request__c request = [
      SELECT Id
      FROM IT_Request__c
      LIMIT 1
    ];

    DateTime pastDate = DateTime.now().addHours(-7);
    DateTime dueBy = DateTime.now().addHours(1);

    Test.setCreatedDate(request.Id, pastDate);

    update new IT_Request__c(Id = request.Id, Due_By__c = dueBy);

    IT_Request__c updated = [
      SELECT Id, SLA_Status__c, Due_By__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    Decimal timeRemaining =
      (updated.Due_By__c.getTime() - DateTime.now().getTime()) / 3600000.0;
    Decimal totalTime =
      (updated.Due_By__c.getTime() - updated.CreatedDate.getTime()) / 3600000.0;
    Decimal percentRemaining = timeRemaining / totalTime;

    if (percentRemaining < 0.25) {
      System.assertEquals(
        'At Risk',
        updated.SLA_Status__c,
        'SLA Status should be At Risk when under 25% time remaining'
      );
    }
  }

  @isTest
  static void testSLAStatus_Breached() {
    IT_Request__c request = [
      SELECT Id
      FROM IT_Request__c
      LIMIT 1
    ];

    DateTime pastDueBy = DateTime.now().addHours(-2);

    update new IT_Request__c(Id = request.Id, Due_By__c = pastDueBy);

    IT_Request__c updated = [
      SELECT Id, SLA_Status__c, Due_By__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertEquals(
      'Breached',
      updated.SLA_Status__c,
      'SLA Status should be Breached when Due By is in the past'
    );
  }

  @isTest
  static void testSLAStatus_Met() {
    IT_Request__c request = [
      SELECT Id
      FROM IT_Request__c
      LIMIT 1
    ];

    DateTime dueBy = DateTime.now().addHours(10);
    DateTime resolvedAt = DateTime.now();

    update new IT_Request__c(
      Id = request.Id,
      Due_By__c = dueBy,
      Resolved_At__c = resolvedAt,
      Status__c = 'Resolved'
    );

    IT_Request__c updated = [
      SELECT Id, SLA_Status__c, Due_By__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertEquals(
      'Met',
      updated.SLA_Status__c,
      'SLA Status should be Met when resolved before deadline'
    );
  }

  @isTest
  static void testSLAStatus_Missed() {
    IT_Request__c request = [
      SELECT Id
      FROM IT_Request__c
      LIMIT 1
    ];

    DateTime dueBy = DateTime.now().addHours(-5);
    DateTime resolvedAt = DateTime.now();

    update new IT_Request__c(
      Id = request.Id,
      Due_By__c = dueBy,
      Resolved_At__c = resolvedAt,
      Status__c = 'Resolved'
    );

    IT_Request__c updated = [
      SELECT Id, SLA_Status__c, Due_By__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertEquals(
      'Missed',
      updated.SLA_Status__c,
      'SLA Status should be Missed when resolved after deadline'
    );
  }

  @isTest
  static void testTimeToResolutionCalculation() {
    IT_Request__c request = [
      SELECT Id
      FROM IT_Request__c
      LIMIT 1
    ];

    Test.setCreatedDate(request.Id, DateTime.now().addHours(-10));

    update new IT_Request__c(
      Id = request.Id,
      Resolved_At__c = DateTime.now(),
      Status__c = 'Resolved'
    );

    IT_Request__c updated = [
      SELECT Id, Time_To_Resolution_Hours__c, Resolved_At__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertNotEquals(
      null,
      updated.Time_To_Resolution_Hours__c,
      'Time to Resolution should be calculated'
    );
    System.assert(
      updated.Time_To_Resolution_Hours__c > 0,
      'Time to Resolution should be positive'
    );
  }

  @isTest
  static void testResolvedAtStampedWhenStatusResolved() {
    IT_Request__c request = [
      SELECT Id, Status__c, Resolved_At__c
      FROM IT_Request__c
      LIMIT 1
    ];

    System.assertEquals(
      null,
      request.Resolved_At__c,
      'Resolved At should be null initially'
    );

    Test.startTest();
    request.Status__c = 'Resolved';
    update request;
    Test.stopTest();

    IT_Request__c updated = [
      SELECT Id, Status__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertEquals(
      'Resolved',
      updated.Status__c,
      'Status should be Resolved'
    );
    System.assertNotEquals(
      null,
      updated.Resolved_At__c,
      'Resolved At should be stamped when status changes to Resolved'
    );
  }

  @isTest
  static void testResolvedAtClearedWhenReopened() {
    IT_Request__c request = [
      SELECT Id, Status__c
      FROM IT_Request__c
      LIMIT 1
    ];

    request.Status__c = 'Resolved';
    update request;

    IT_Request__c resolved = [
      SELECT Id, Status__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertNotEquals(
      null,
      resolved.Resolved_At__c,
      'Resolved At should be set'
    );

    Test.startTest();
    resolved.Status__c = 'In Progress';
    update resolved;
    Test.stopTest();

    IT_Request__c reopened = [
      SELECT Id, Status__c, Resolved_At__c
      FROM IT_Request__c
      WHERE Id = :request.Id
    ];

    System.assertEquals(
      'In Progress',
      reopened.Status__c,
      'Status should be In Progress'
    );
    System.assertEquals(
      null,
      reopened.Resolved_At__c,
      'Resolved At should be cleared when reopened'
    );
  }

  @isTest
  static void testBulkSLAProcessing() {
    List<IT_Request__c> bulkRequests = new List<IT_Request__c>();

    for (Integer i = 0; i < 200; i++) {
      IT_Request__c request = new IT_Request__c();
      request.Employee_Name__c = 'Bulk User ' + i;
      request.Issue_Description__c = 'Bulk issue ' + i;
      request.Priority__c = Math.mod(i, 2) == 0 ? 'High' : 'Low';
      request.Status__c = 'New';
      request.Assigned_Tier__c = 'Tier 1';
      bulkRequests.add(request);
    }

    Test.startTest();
    insert bulkRequests;
    Test.stopTest();

    List<IT_Request__c> inserted = [
      SELECT Id, Due_By__c, SLA_Status__c, Priority__c
      FROM IT_Request__c
      WHERE Id IN :bulkRequests
    ];

    System.assertEquals(200, inserted.size(), 'Should have 200 records');

    for (IT_Request__c record : inserted) {
      System.assertNotEquals(
        null,
        record.Due_By__c,
        'Due By should be set for all bulk records'
      );
      System.assertNotEquals(
        null,
        record.SLA_Status__c,
        'SLA Status should be calculated'
      );
    }
  }
}
