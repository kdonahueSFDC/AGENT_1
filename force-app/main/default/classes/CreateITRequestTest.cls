@isTest
private class CreateITRequestTest {
  @TestSetup
  static void setup() {
    // No setup needed - we'll create records in each test
  }

  @isTest
  static void testCreateSingleRequest() {
    // Test creating a single IT request with all fields specified
    CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
    request.employeeName = 'John Doe';
    request.issueDescription = 'Laptop not turning on';
    request.priority = 'High';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request }
    );
    Test.stopTest();

    // Assertions
    System.assertEquals(1, responses.size(), 'Should return 1 response');
    CreateITRequest.ResponseWrapper response = responses[0];

    System.assertNotEquals(
      null,
      response.recordId,
      'Record ID should be populated'
    );
    System.assertNotEquals(
      null,
      response.recordName,
      'Record name should be populated'
    );
    System.assert(
      response.recordName.startsWith('IT-'),
      'Record name should start with IT-'
    );
    System.assert(
      response.message.contains('Created IT request'),
      'Message should confirm creation'
    );
    System.assert(
      response.message.contains('John Doe'),
      'Message should include employee name'
    );

    // Verify record in database
    IT_Request__c createdRecord = [
      SELECT
        Id,
        Name,
        Employee_Name__c,
        Issue_Description__c,
        Priority__c,
        Status__c,
        Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id = :response.recordId
    ];

    System.assertEquals(
      'John Doe',
      createdRecord.Employee_Name__c,
      'Employee name should match'
    );
    System.assertEquals(
      'Laptop not turning on',
      createdRecord.Issue_Description__c,
      'Issue description should match'
    );
    System.assertEquals(
      'High',
      createdRecord.Priority__c,
      'Priority should match'
    );
    System.assertEquals('New', createdRecord.Status__c, 'Status should be New');
    System.assertNotEquals(
      null,
      createdRecord.Assigned_Tier__c,
      'Assigned tier should be routed by the triage trigger'
    );
  }

  @isTest
  static void testCreateRequestWithDefaultPriority() {
    // Test creating a request with null priority (should default to Medium)
    CreateITRequest.RequestWrapper request1 = new CreateITRequest.RequestWrapper();
    request1.employeeName = 'Jane Smith';
    request1.issueDescription = 'Password reset needed';
    request1.priority = null;

    // Test creating a request with empty string priority (should also default to Medium)
    CreateITRequest.RequestWrapper request2 = new CreateITRequest.RequestWrapper();
    request2.employeeName = 'Bob Johnson';
    request2.issueDescription = 'Printer not working';
    request2.priority = '';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request1, request2 }
    );
    Test.stopTest();

    // Assertions
    System.assertEquals(2, responses.size(), 'Should return 2 responses');

    for (CreateITRequest.ResponseWrapper response : responses) {
      System.assertNotEquals(
        null,
        response.recordId,
        'Record ID should be populated'
      );
      System.assertNotEquals(
        null,
        response.recordName,
        'Record name should be populated'
      );
    }

    // Verify both records have Medium priority
    List<IT_Request__c> createdRecords = [
      SELECT Id, Priority__c
      FROM IT_Request__c
      WHERE Id IN (:responses[0].recordId, :responses[1].recordId)
    ];

    System.assertEquals(
      2,
      createdRecords.size(),
      'Should have created 2 records'
    );
    for (IT_Request__c record : createdRecords) {
      System.assertEquals(
        'Medium',
        record.Priority__c,
        'Priority should default to Medium'
      );
    }
  }

  @isTest
  static void testCreateBulkRequests() {
    // Test bulk creation with 200 records (governor limit testing)
    List<CreateITRequest.RequestWrapper> requests = new List<CreateITRequest.RequestWrapper>();

    for (Integer i = 0; i < 200; i++) {
      CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
      request.employeeName = 'Employee ' + i;
      request.issueDescription = 'Issue description for request ' + i;

      // Vary priorities
      if (Math.mod(i, 4) == 0) {
        request.priority = 'Low';
      } else if (Math.mod(i, 4) == 1) {
        request.priority = 'Medium';
      } else if (Math.mod(i, 4) == 2) {
        request.priority = 'High';
      } else {
        request.priority = 'Critical';
      }

      requests.add(request);
    }

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      requests
    );
    Test.stopTest();

    // Assertions
    System.assertEquals(200, responses.size(), 'Should return 200 responses');

    Set<Id> recordIds = new Set<Id>();
    for (CreateITRequest.ResponseWrapper response : responses) {
      System.assertNotEquals(
        null,
        response.recordId,
        'Record ID should be populated'
      );
      System.assertNotEquals(
        null,
        response.recordName,
        'Record name should be populated'
      );
      System.assert(
        response.message.contains('Created IT request'),
        'Message should confirm creation'
      );
      recordIds.add(response.recordId);
    }

    System.assertEquals(
      200,
      recordIds.size(),
      'Should have 200 unique record IDs'
    );

    // Verify all records were created in database
    List<IT_Request__c> createdRecords = [
      SELECT Id, Status__c, Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id IN :recordIds
    ];

    System.assertEquals(
      200,
      createdRecords.size(),
      'Should have created 200 records in database'
    );

    // Verify all have correct default values. Assigned_Tier__c is routed by
    // ITRequestTriageService, not the invocable, so we only require it to be set.
    for (IT_Request__c record : createdRecords) {
      System.assertEquals('New', record.Status__c, 'Status should be New');
      System.assertNotEquals(
        null,
        record.Assigned_Tier__c,
        'Assigned tier should be routed by the triage trigger'
      );
    }
  }

  @isTest
  static void testCreateEmptyListOfRequests() {
    // Test with empty list
    List<CreateITRequest.RequestWrapper> requests = new List<CreateITRequest.RequestWrapper>();

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      requests
    );
    Test.stopTest();

    // Should handle empty list gracefully
    System.assertEquals(
      0,
      responses.size(),
      'Should return 0 responses for empty input'
    );
  }

  @isTest
  static void testCreateMultipleRequestsWithVariedPriorities() {
    // Test creating requests with all priority levels
    List<CreateITRequest.RequestWrapper> requests = new List<CreateITRequest.RequestWrapper>();

    String[] priorities = new List<String>{
      'Low',
      'Medium',
      'High',
      'Critical'
    };
    for (Integer i = 0; i < priorities.size(); i++) {
      CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
      request.employeeName = 'Test User ' + i;
      request.issueDescription = 'Test issue ' + i;
      request.priority = priorities[i];
      requests.add(request);
    }

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      requests
    );
    Test.stopTest();

    // Assertions
    System.assertEquals(4, responses.size(), 'Should return 4 responses');

    List<IT_Request__c> createdRecords = [
      SELECT Id, Priority__c
      FROM IT_Request__c
      WHERE
        Id IN :new List<Id>{
          responses[0].recordId,
          responses[1].recordId,
          responses[2].recordId,
          responses[3].recordId
        }
      ORDER BY Priority__c
    ];

    System.assertEquals(
      4,
      createdRecords.size(),
      'Should have created 4 records'
    );

    // Verify priorities match
    Set<String> actualPriorities = new Set<String>();
    for (IT_Request__c record : createdRecords) {
      actualPriorities.add(record.Priority__c);
    }

    System.assert(
      actualPriorities.contains('Low'),
      'Should have Low priority record'
    );
    System.assert(
      actualPriorities.contains('Medium'),
      'Should have Medium priority record'
    );
    System.assert(
      actualPriorities.contains('High'),
      'Should have High priority record'
    );
    System.assert(
      actualPriorities.contains('Critical'),
      'Should have Critical priority record'
    );
  }

  @isTest
  static void testSLACalculation_Critical() {
    CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
    request.employeeName = 'Critical User';
    request.issueDescription = 'System down';
    request.priority = 'Critical';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request }
    );
    Test.stopTest();

    IT_Request__c record = [
      SELECT Id, Priority__c, Due_By__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :responses[0].recordId
    ];

    System.assertNotEquals(
      null,
      record.Due_By__c,
      'Due By should be set by flow'
    );
    Decimal hoursDiff =
      (record.Due_By__c.getTime() - record.CreatedDate.getTime()) / 3600000.0;
    System.assert(
      Math.abs(hoursDiff - 4) < 0.1,
      'Critical SLA should be 4 hours'
    );
  }

  @isTest
  static void testSLACalculation_High() {
    CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
    request.employeeName = 'High User';
    request.issueDescription = 'Major issue';
    request.priority = 'High';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request }
    );
    Test.stopTest();

    IT_Request__c record = [
      SELECT Id, Priority__c, Due_By__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :responses[0].recordId
    ];

    System.assertNotEquals(
      null,
      record.Due_By__c,
      'Due By should be set by flow'
    );
    Decimal hoursDiff =
      (record.Due_By__c.getTime() - record.CreatedDate.getTime()) / 3600000.0;
    System.assert(Math.abs(hoursDiff - 8) < 0.1, 'High SLA should be 8 hours');
  }

  @isTest
  static void testSLACalculation_Medium() {
    CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
    request.employeeName = 'Medium User';
    request.issueDescription = 'Medium issue';
    request.priority = 'Medium';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request }
    );
    Test.stopTest();

    IT_Request__c record = [
      SELECT Id, Priority__c, Due_By__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :responses[0].recordId
    ];

    System.assertNotEquals(
      null,
      record.Due_By__c,
      'Due By should be set by flow'
    );
    Decimal hoursDiff =
      (record.Due_By__c.getTime() - record.CreatedDate.getTime()) / 3600000.0;
    System.assert(
      Math.abs(hoursDiff - 24) < 0.1,
      'Medium SLA should be 24 hours'
    );
  }

  @isTest
  static void testSLACalculation_Low() {
    CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
    request.employeeName = 'Low User';
    request.issueDescription = 'Low priority issue';
    request.priority = 'Low';

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      new List<CreateITRequest.RequestWrapper>{ request }
    );
    Test.stopTest();

    IT_Request__c record = [
      SELECT Id, Priority__c, Due_By__c, CreatedDate
      FROM IT_Request__c
      WHERE Id = :responses[0].recordId
    ];

    System.assertNotEquals(
      null,
      record.Due_By__c,
      'Due By should be set by flow'
    );
    Decimal hoursDiff =
      (record.Due_By__c.getTime() - record.CreatedDate.getTime()) / 3600000.0;
    System.assert(Math.abs(hoursDiff - 72) < 0.1, 'Low SLA should be 72 hours');
  }

  @isTest
  static void testCreateBulkRequests_SLASet() {
    List<CreateITRequest.RequestWrapper> requests = new List<CreateITRequest.RequestWrapper>();

    for (Integer i = 0; i < 200; i++) {
      CreateITRequest.RequestWrapper request = new CreateITRequest.RequestWrapper();
      request.employeeName = 'Bulk User ' + i;
      request.issueDescription = 'Bulk issue ' + i;
      request.priority = 'High';
      requests.add(request);
    }

    Test.startTest();
    List<CreateITRequest.ResponseWrapper> responses = CreateITRequest.createRequests(
      requests
    );
    Test.stopTest();

    Set<Id> recordIds = new Set<Id>();
    for (CreateITRequest.ResponseWrapper response : responses) {
      recordIds.add(response.recordId);
    }

    List<IT_Request__c> records = [
      SELECT Id, Due_By__c
      FROM IT_Request__c
      WHERE Id IN :recordIds
    ];

    System.assertEquals(200, records.size(), 'Should have 200 records');
    for (IT_Request__c record : records) {
      System.assertNotEquals(
        null,
        record.Due_By__c,
        'Due By should be set for bulk records'
      );
    }
  }
}
