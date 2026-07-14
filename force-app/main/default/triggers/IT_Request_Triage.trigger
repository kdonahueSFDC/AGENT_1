trigger IT_Request_Triage on IT_Request__c(before insert) {
  ITRequestTriageService.assignRouting(Trigger.new);
}
