@isTest
private class MyITRequestsControllerTest {
  @TestSetup
  static void setup() {
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 3; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Alice Owner',
          Employee_Email__c = 'alice@example.com',
          Issue_Description__c = 'General question ' + i,
          Priority__c = 'Medium',
          Status__c = 'New',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    reqs.add(
      new IT_Request__c(
        Employee_Name__c = 'Alice Owner',
        Employee_Email__c = 'alice@example.com',
        Issue_Description__c = 'Old resolved issue',
        Priority__c = 'Low',
        Status__c = 'Resolved',
        Assigned_Tier__c = 'Tier 1'
      )
    );
    reqs.add(
      new IT_Request__c(
        Employee_Name__c = 'Bob Other',
        Employee_Email__c = 'bob@example.com',
        Issue_Description__c = 'Not Alice',
        Priority__c = 'Medium',
        Status__c = 'New',
        Assigned_Tier__c = 'Tier 1'
      )
    );
    insert reqs;
  }

  @isTest
  static void testReturnsOnlyMatchingEmail() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      'alice@example.com',
      null
    );
    Test.stopTest();

    System.assertEquals(
      4,
      results.size(),
      'Alice has 4 records; Bob should not appear'
    );
    for (MyITRequestsController.RequestSummary r : results) {
      System.assertNotEquals(null, r.id, 'Id should be populated');
      System.assert(
        String.isNotBlank(r.name),
        'Auto number should be populated'
      );
      System.assertEquals(
        '/' + r.id,
        r.recordLink,
        'Record link should point to detail page'
      );
    }
  }

  @isTest
  static void testFilterOpenOnly() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      'alice@example.com',
      'Open'
    );
    Test.stopTest();

    System.assertEquals(
      3,
      results.size(),
      'Only New/In Progress/Escalated should be returned'
    );
    for (MyITRequestsController.RequestSummary r : results) {
      System.assertEquals(
        'New',
        r.status,
        'Resolved record should be filtered out'
      );
    }
  }

  @isTest
  static void testFilterResolvedOnly() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      'alice@example.com',
      'Resolved'
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Only the Resolved record');
    System.assertEquals('Resolved', results[0].status);
  }

  @isTest
  static void testBlankEmailReturnsEmpty() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      '',
      null
    );
    List<MyITRequestsController.RequestSummary> nullResults = MyITRequestsController.getMyRequests(
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(0, results.size(), 'Blank email → no records');
    System.assertEquals(0, nullResults.size(), 'Null email → no records');
  }

  @isTest
  static void testEmailIsNormalized() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      '  ALICE@Example.com  ',
      null
    );
    Test.stopTest();

    System.assertEquals(
      4,
      results.size(),
      'Whitespace and case should be normalized before matching'
    );
  }

  @isTest
  static void testUnknownEmailReturnsEmpty() {
    Test.startTest();
    List<MyITRequestsController.RequestSummary> results = MyITRequestsController.getMyRequests(
      'nobody@example.com',
      null
    );
    Test.stopTest();

    System.assertEquals(0, results.size(), 'Unknown email should return zero');
  }

  @isTest
  static void testSlaStatusClassification() {
    System.assertEquals(
      'slds-text-color_error',
      MyITRequestsController.classifySlaStatus('Breached')
    );
    System.assertEquals(
      'slds-text-color_error',
      MyITRequestsController.classifySlaStatus('Missed')
    );
    System.assertEquals(
      'slds-text-color_warning',
      MyITRequestsController.classifySlaStatus('At Risk')
    );
    System.assertEquals(
      'slds-text-color_success',
      MyITRequestsController.classifySlaStatus('Met')
    );
    System.assertEquals(
      'slds-text-color_success',
      MyITRequestsController.classifySlaStatus('On Track')
    );
    System.assertEquals(
      'slds-text-color_default',
      MyITRequestsController.classifySlaStatus('Not Set')
    );
    System.assertEquals(
      'slds-text-color_default',
      MyITRequestsController.classifySlaStatus(null)
    );
  }

  @isTest
  static void testPaginationFirstPage() {
    // Create 250 records for pagination testing
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 250; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Pagination User',
          Employee_Email__c = 'paginate@example.com',
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = 'New',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    insert reqs;

    Test.startTest();
    MyITRequestsController.PaginatedResult result = MyITRequestsController.getMyRequestsPaginated(
      'paginate@example.com',
      null,
      0,
      50
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      50,
      result.records.size(),
      'First page should return 50 records'
    );
    System.assertEquals(
      true,
      result.hasMore,
      'Should have more records available'
    );
  }

  @isTest
  static void testPaginationSecondPage() {
    // Create 250 records for pagination testing
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 250; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Pagination User',
          Employee_Email__c = 'paginate@example.com',
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = 'New',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    insert reqs;

    Test.startTest();
    MyITRequestsController.PaginatedResult result = MyITRequestsController.getMyRequestsPaginated(
      'paginate@example.com',
      null,
      50,
      50
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      50,
      result.records.size(),
      'Second page should return 50 records'
    );
    System.assertEquals(
      true,
      result.hasMore,
      'Should still have more records available'
    );
  }

  @isTest
  static void testPaginationLastPage() {
    // Create 120 records (less than 3 full pages of 50)
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 120; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Pagination User',
          Employee_Email__c = 'paginate@example.com',
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = 'New',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    insert reqs;

    Test.startTest();
    MyITRequestsController.PaginatedResult result = MyITRequestsController.getMyRequestsPaginated(
      'paginate@example.com',
      null,
      100,
      50
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      20,
      result.records.size(),
      'Last page should return remaining 20 records'
    );
    System.assertEquals(
      false,
      result.hasMore,
      'Should not have more records available'
    );
  }

  @isTest
  static void testPaginationWithFilters() {
    // Create mix of open and resolved records
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 200; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Filter User',
          Employee_Email__c = 'filter@example.com',
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = Math.mod(i, 2) == 0 ? 'New' : 'Resolved',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    insert reqs;

    Test.startTest();
    MyITRequestsController.PaginatedResult result = MyITRequestsController.getMyRequestsPaginated(
      'filter@example.com',
      'Open',
      0,
      50
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      50,
      result.records.size(),
      'Should return 50 open records'
    );
    System.assertEquals(
      true,
      result.hasMore,
      'Should have more open records available'
    );

    for (MyITRequestsController.RequestSummary r : result.records) {
      System.assertEquals(
        'New',
        r.status,
        'All returned records should be open'
      );
    }
  }

  @isTest
  static void testPaginationBulkNoGovernorLimits() {
    // Create 300 records to test bulkification
    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 300; i++) {
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Bulk User',
          Employee_Email__c = 'bulk@example.com',
          Issue_Description__c = 'Issue ' + i,
          Priority__c = 'Medium',
          Status__c = 'New',
          Assigned_Tier__c = 'Tier 1'
        )
      );
    }
    insert reqs;

    Test.startTest();
    MyITRequestsController.PaginatedResult result = MyITRequestsController.getMyRequestsPaginated(
      'bulk@example.com',
      null,
      0,
      100
    );
    Test.stopTest();

    System.assertEquals(
      100,
      result.records.size(),
      'Should handle large page size'
    );
    System.assertEquals(
      true,
      result.hasMore,
      'Should indicate more records exist'
    );
  }
}
