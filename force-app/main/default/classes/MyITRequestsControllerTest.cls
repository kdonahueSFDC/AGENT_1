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
}
