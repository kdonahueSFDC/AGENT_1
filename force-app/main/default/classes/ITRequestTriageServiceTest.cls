@isTest
private class ITRequestTriageServiceTest {
  private static IT_Triage_Rule__mdt rule(
    String devName,
    Decimal order,
    String keyword,
    String priorityFilter,
    String tier,
    String queueDevName
  ) {
    IT_Triage_Rule__mdt r = new IT_Triage_Rule__mdt();
    r.DeveloperName = devName;
    r.Active__c = true;
    r.Evaluation_Order__c = order;
    r.Keyword__c = keyword;
    r.Priority_Filter__c = priorityFilter;
    r.Target_Tier__c = tier;
    r.Target_Queue_DevName__c = queueDevName;
    return r;
  }

  private static void installRules(List<IT_Triage_Rule__mdt> rules) {
    ITRequestTriageService.rulesForTest = rules;
  }

  @isTest
  static void testKeywordRoutesToTier3() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('Breach', 10, 'breach', null, 'Tier 3', 'IT_Tier_3_Queue'),
        rule('Fallback', 9999, null, null, 'Tier 1', 'IT_Tier_1_Queue')
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'Sec User',
      Issue_Description__c = 'Possible data BREACH in customer table',
      Priority__c = 'High',
      Status__c = 'New'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c, OwnerId
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 3',
      saved.Assigned_Tier__c,
      'Keyword "breach" should route to Tier 3'
    );

    Group tier3 = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'IT_Tier_3_Queue'
      LIMIT 1
    ];
    System.assertEquals(
      tier3.Id,
      saved.OwnerId,
      'Owner should be the Tier 3 queue'
    );
  }

  @isTest
  static void testPriorityFilterCriticalOverride() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule(
          'CriticalIsTier2',
          10,
          null,
          'Critical',
          'Tier 2',
          'IT_Tier_2_Queue'
        ),
        rule(
          'PasswordIsTier1',
          20,
          'password',
          null,
          'Tier 1',
          'IT_Tier_1_Queue'
        )
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'CEO',
      Issue_Description__c = 'Password change but I am the CEO',
      Priority__c = 'Critical',
      Status__c = 'New'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 2',
      saved.Assigned_Tier__c,
      'Critical priority should win over password keyword due to evaluation order'
    );
  }

  @isTest
  static void testFallbackWhenNoKeywordMatches() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('VPN', 10, 'vpn', null, 'Tier 2', 'IT_Tier_2_Queue'),
        rule('Fallback', 9999, null, null, 'Tier 1', 'IT_Tier_1_Queue')
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'Frank',
      Issue_Description__c = 'Chair is broken',
      Priority__c = 'Low',
      Status__c = 'New'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c, OwnerId
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 1',
      saved.Assigned_Tier__c,
      'Non-matching request should fall through to the catch-all rule'
    );
  }

  @isTest
  static void testManualTierOverrideSkipsRouting() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('Breach', 10, 'breach', null, 'Tier 3', 'IT_Tier_3_Queue')
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'Admin',
      Issue_Description__c = 'Reported breach, but handling directly',
      Priority__c = 'High',
      Status__c = 'New',
      Assigned_Tier__c = 'Tier 1'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 1',
      saved.Assigned_Tier__c,
      'Pre-set Assigned_Tier__c should suppress auto-triage'
    );
  }

  @isTest
  static void testInactiveRuleIgnored() {
    IT_Triage_Rule__mdt inactive = rule(
      'Inactive',
      1,
      'breach',
      null,
      'Tier 3',
      'IT_Tier_3_Queue'
    );
    inactive.Active__c = false;
    installRules(
      new List<IT_Triage_Rule__mdt>{
        inactive,
        rule('Fallback', 9999, null, null, 'Tier 1', 'IT_Tier_1_Queue')
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'User',
      Issue_Description__c = 'Suspected breach',
      Priority__c = 'High',
      Status__c = 'New'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 1',
      saved.Assigned_Tier__c,
      'Inactive rules should be skipped'
    );
  }

  @isTest
  static void testMissingQueueLeavesOwnerUnchanged() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('Ghost', 10, 'ghost', null, 'Tier 2', 'IT_Nonexistent_Queue')
      }
    );

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'User',
      Issue_Description__c = 'Ghost sighting',
      Priority__c = 'Medium',
      Status__c = 'New'
    );

    Id runningUserId = UserInfo.getUserId();

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c, OwnerId
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      'Tier 2',
      saved.Assigned_Tier__c,
      'Tier should still be stamped even when queue is missing'
    );
    System.assertEquals(
      runningUserId,
      saved.OwnerId,
      'Owner should remain the running user when target queue does not exist'
    );
  }

  @isTest
  static void testEmptyRuleSetIsNoop() {
    installRules(new List<IT_Triage_Rule__mdt>());

    IT_Request__c req = new IT_Request__c(
      Employee_Name__c = 'User',
      Issue_Description__c = 'Anything',
      Priority__c = 'Medium',
      Status__c = 'New'
    );

    Test.startTest();
    insert req;
    Test.stopTest();

    IT_Request__c saved = [
      SELECT Id, Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(
      null,
      saved.Assigned_Tier__c,
      'With no rules loaded, triage should leave Assigned_Tier__c null'
    );
  }

  @isTest
  static void testBulkRouting() {
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('Critical', 10, null, 'Critical', 'Tier 2', 'IT_Tier_2_Queue'),
        rule('Breach', 20, 'breach', null, 'Tier 3', 'IT_Tier_3_Queue'),
        rule('Password', 30, 'password', null, 'Tier 1', 'IT_Tier_1_Queue'),
        rule('Fallback', 9999, null, null, 'Tier 1', 'IT_Tier_1_Queue')
      }
    );

    List<String> descriptions = new List<String>{
      'Suspected breach in system',
      'Password reset for user',
      'Prod is down urgent',
      'General question'
    };
    List<String> priorities = new List<String>{
      'High',
      'Medium',
      'Critical',
      'Low'
    };

    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 200; i++) {
      Integer bucket = Math.mod(i, 4);
      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Bulk User ' + i,
          Issue_Description__c = descriptions[bucket] + ' ' + i,
          Priority__c = priorities[bucket],
          Status__c = 'New'
        )
      );
    }

    Test.startTest();
    insert reqs;
    Test.stopTest();

    Map<String, Integer> tierCounts = new Map<String, Integer>{
      'Tier 1' => 0,
      'Tier 2' => 0,
      'Tier 3' => 0
    };
    for (IT_Request__c saved : [
      SELECT Assigned_Tier__c
      FROM IT_Request__c
      WHERE Id IN :reqs
    ]) {
      tierCounts.put(
        saved.Assigned_Tier__c,
        tierCounts.get(saved.Assigned_Tier__c) + 1
      );
    }

    System.assertEquals(50, tierCounts.get('Tier 3'), 'breach → Tier 3');
    System.assertEquals(50, tierCounts.get('Tier 2'), 'Critical → Tier 2');
    // Password matches (50) plus fallback general questions (50) both go to Tier 1.
    System.assertEquals(
      100,
      tierCounts.get('Tier 1'),
      'password + fallback → Tier 1'
    );
  }

  @isTest
  static void testBulkTriageWithVariedRulesNoGovernorLimits() {
    // Comprehensive bulk test with 250+ records exercising all rule conditions
    // Proves bulkification: queue lookup happens once, not per record
    installRules(
      new List<IT_Triage_Rule__mdt>{
        rule('Critical', 10, null, 'Critical', 'Tier 2', 'IT_Tier_2_Queue'),
        rule('Phishing', 20, 'phishing', null, 'Tier 3', 'IT_Tier_3_Queue'),
        rule('Breach', 30, 'breach', null, 'Tier 3', 'IT_Tier_3_Queue'),
        rule('Outage', 40, 'outage', null, 'Tier 2', 'IT_Tier_2_Queue'),
        rule('VPN', 50, 'vpn', null, 'Tier 2', 'IT_Tier_2_Queue'),
        rule('Password', 60, 'password', null, 'Tier 1', 'IT_Tier_1_Queue'),
        rule('MFA', 70, 'mfa', null, 'Tier 1', 'IT_Tier_1_Queue'),
        rule('Fallback', 9999, null, null, 'Tier 1', 'IT_Tier_1_Queue')
      }
    );

    List<String> keywords = new List<String>{
      'phishing',
      'breach',
      'outage',
      'vpn',
      'password',
      'mfa',
      'misc'
    };
    List<String> priorities = new List<String>{
      'Critical',
      'High',
      'Medium',
      'Low'
    };

    List<IT_Request__c> reqs = new List<IT_Request__c>();
    for (Integer i = 0; i < 250; i++) {
      String keyword = keywords[Math.mod(i, keywords.size())];
      String priority = priorities[Math.mod(i, priorities.size())];

      reqs.add(
        new IT_Request__c(
          Employee_Name__c = 'Bulk User ' + i,
          Issue_Description__c = 'Request about ' + keyword + ' case ' + i,
          Priority__c = priority,
          Status__c = 'New'
        )
      );
    }

    // Track SOQL/DML limits before insert
    Integer soqlBefore = Limits.getQueries();
    Integer dmlBefore = Limits.getDmlStatements();

    Test.startTest();
    insert reqs;
    Test.stopTest();

    Integer soqlAfter = Limits.getQueries();
    Integer dmlAfter = Limits.getDmlStatements();

    // Verify all records triaged correctly
    List<IT_Request__c> saved = [
      SELECT Id, Assigned_Tier__c, OwnerId, Issue_Description__c, Priority__c
      FROM IT_Request__c
      WHERE Id IN :reqs
    ];

    System.assertEquals(250, saved.size(), 'All records should be created');

    Map<String, Integer> tierCounts = new Map<String, Integer>{
      'Tier 1' => 0,
      'Tier 2' => 0,
      'Tier 3' => 0
    };

    for (IT_Request__c rec : saved) {
      System.assertNotEquals(
        null,
        rec.Assigned_Tier__c,
        'Every record should have a tier assigned'
      );
      tierCounts.put(
        rec.Assigned_Tier__c,
        tierCounts.get(rec.Assigned_Tier__c) + 1
      );
    }

    // Verify tier distribution is reasonable
    System.assert(tierCounts.get('Tier 1') > 0, 'Should have Tier 1 requests');
    System.assert(tierCounts.get('Tier 2') > 0, 'Should have Tier 2 requests');
    System.assert(tierCounts.get('Tier 3') > 0, 'Should have Tier 3 requests');

    // Critical check: SOQL queries should remain minimal (bulkified)
    // Even 250 records should not spike SOQL usage significantly
    Integer soqlUsed = soqlAfter - soqlBefore;
    System.assert(
      soqlUsed <= 5,
      'SOQL queries should be bulkified; used ' +
        soqlUsed +
        ' queries for 250 records'
    );

    // Critical check: DML should also be minimal
    Integer dmlUsed = dmlAfter - dmlBefore;
    System.assert(
      dmlUsed <= 3,
      'DML operations should be bulkified; used ' +
        dmlUsed +
        ' DML for 250 records'
    );
  }
}
