public with sharing class ITRequestTriageService {
  @TestVisible
  private static List<IT_Triage_Rule__mdt> rulesForTest;

  public static void assignRouting(List<IT_Request__c> newRecords) {
    if (newRecords == null || newRecords.isEmpty()) {
      return;
    }

    List<IT_Triage_Rule__mdt> rules = getRules();
    if (rules.isEmpty()) {
      return;
    }

    Map<String, Id> queueIdByDevName = loadQueueIds(rules);

    for (IT_Request__c req : newRecords) {
      // Callers that pre-set Assigned_Tier__c (e.g. legacy tests, admins on
      // manual entry) opt out of auto-triage entirely; that becomes the manual
      // override channel.
      if (String.isNotBlank(req.Assigned_Tier__c)) {
        continue;
      }
      IT_Triage_Rule__mdt match = findMatch(req, rules);
      if (match == null) {
        continue;
      }
      req.Assigned_Tier__c = match.Target_Tier__c;

      if (String.isNotBlank(match.Target_Queue_DevName__c)) {
        Id queueId = queueIdByDevName.get(match.Target_Queue_DevName__c);
        if (queueId != null) {
          req.OwnerId = queueId;
        }
      }
    }
  }

  private static IT_Triage_Rule__mdt findMatch(
    IT_Request__c req,
    List<IT_Triage_Rule__mdt> rules
  ) {
    String description = req.Issue_Description__c == null
      ? ''
      : req.Issue_Description__c.toLowerCase();
    String priority = req.Priority__c;

    for (IT_Triage_Rule__mdt rule : rules) {
      if (!rule.Active__c) {
        continue;
      }
      if (
        String.isNotBlank(rule.Priority_Filter__c) &&
        rule.Priority_Filter__c != priority
      ) {
        continue;
      }
      if (String.isNotBlank(rule.Keyword__c)) {
        if (!description.contains(rule.Keyword__c.toLowerCase())) {
          continue;
        }
      }
      return rule;
    }
    return null;
  }

  private static Map<String, Id> loadQueueIds(List<IT_Triage_Rule__mdt> rules) {
    Set<String> queueNames = new Set<String>();
    for (IT_Triage_Rule__mdt rule : rules) {
      if (String.isNotBlank(rule.Target_Queue_DevName__c)) {
        queueNames.add(rule.Target_Queue_DevName__c);
      }
    }
    Map<String, Id> queueIdByDevName = new Map<String, Id>();
    if (queueNames.isEmpty()) {
      return queueIdByDevName;
    }
    for (Group q : [
      SELECT Id, DeveloperName
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName IN :queueNames
      WITH SYSTEM_MODE
    ]) {
      queueIdByDevName.put(q.DeveloperName, q.Id);
    }
    return queueIdByDevName;
  }

  private static List<IT_Triage_Rule__mdt> getRules() {
    if (rulesForTest != null) {
      return rulesForTest;
    }
    return [
      SELECT
        DeveloperName,
        Active__c,
        Keyword__c,
        Priority_Filter__c,
        Target_Tier__c,
        Target_Queue_DevName__c,
        Evaluation_Order__c
      FROM IT_Triage_Rule__mdt
      WHERE Active__c = TRUE
      ORDER BY Evaluation_Order__c ASC NULLS LAST, DeveloperName ASC
    ];
  }
}
