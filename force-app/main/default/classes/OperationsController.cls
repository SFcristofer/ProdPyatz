/**
 * Controlador de dominio para Operaciones de Campo, Calendario y Seguimiento Táctico.
 */
public with sharing class OperationsController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getActiveUsers() {
        List<Map<String, String>> result = new List<Map<String, String>>();
        for (User u : [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name ASC]) {
            result.add(new Map<String, String>{
                'label' => u.Name,
                'value' => u.Id
            });
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOpportunitiesList(String searchTerm) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        String query = 'SELECT Id, Name, Account.Name, StageName, Amount, CloseDate, Owner.Name, Estado_Oportunidad__c FROM Opportunity ';
        if (String.isNotBlank(searchTerm)) {
            String key = '%' + searchTerm + '%';
            query += 'WHERE (Name LIKE :key OR Account.Name LIKE :key) ';
        }
        query += 'ORDER BY CreatedDate DESC LIMIT 200';
        for(Opportunity o : Database.query(query)) {
            result.add(new Map<String, Object>{ 
                'id' => o.Id, 
                'name' => o.Name, 
                'account' => o.Account.Name, 
                'owner' => o.Owner.Name, 
                'closeDate' => o.CloseDate, 
                'amount' => o.Amount, 
                'stageName' => o.StageName,
                'statusOpp' => o.Estado_Oportunidad__c
            });
        }
        return result;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getOpportunitiesByAccount(Id accountId) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Opportunity o : [SELECT Id, Name, StageName, Amount, CloseDate, Owner.Name, Account.Name, Subetapa__c, Estado_Subetapa__c, Estado_Oportunidad__c FROM Opportunity WHERE AccountId = :accountId ORDER BY CreatedDate DESC]) {
            results.add(new Map<String, Object>{ 
                'id' => o.Id, 
                'name' => o.Name, 
                'account' => o.Account.Name, 
                'stageName' => o.StageName, 
                'amount' => o.Amount != null ? o.Amount : 0, 
                'closeDate' => o.CloseDate, 
                'owner' => o.Owner.Name, 
                'subetapa' => o.Subetapa__c, 
                'estado' => o.Estado_Subetapa__c,
                'statusOpp' => o.Estado_Oportunidad__c
            });
        }
        return results;
    }

    @AuraEnabled
    public static Id saveTechnicalData(Map<String, Object> data) {
        return QuoteEngineService.saveTechnicalData(data);
    }

    @AuraEnabled
    public static List<Map<String, Object>> getChecklist(Id opportunityId, String category) {
        return FileService.getChecklist(opportunityId, category);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getEvidenceGallery(Id opportunityId) {
        return FileService.getEvidenceGallery(opportunityId);
    }

    @AuraEnabled
    public static void renameUploadedFile(Id documentId, String docType) {
        FileService.renameAndLinkFile(documentId, docType);
    }

    @AuraEnabled
    public static Map<String, Object> getCalendarData(Id recordId, String startDate, String endDate) {
        return CalendarService.getCalendarData(startDate, endDate);
    }

    @AuraEnabled
    public static List<Map<String, Object>> getTacticalHistory(Id oppId) {
        return OperationsService.getTacticalHistory(oppId);
    }

    @AuraEnabled
    public static void updateTaskActivity(Id taskId, String newStatus, String observation) {
        OperationsService.updateTaskActivity(taskId, newStatus, observation);
    }

    @AuraEnabled
    public static void saveStageTracking(Id opportunityId, String stage, String subStage, String status) {
        OperationsService.saveStageTracking(opportunityId, stage, subStage, status);
    }

    @AuraEnabled
    public static List<Map<String, Object>> getActionTimeline(Id opportunityId) {
        return CalendarService.getActionTimeline(opportunityId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Seguimiento_Etapas_Pyatz__c> getProcessHistory(Id opportunityId) {
        return [SELECT Etapa__c, Subetapa__c, Estado__c, LastModifiedDate FROM Seguimiento_Etapas_Pyatz__c WHERE Oportunidad__c = :opportunityId ORDER BY CreatedDate ASC];
    }

    @AuraEnabled
    public static Id saveNote(Id parentId, String title, String content) {
        return OperationsService.saveNote(parentId, title, content);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOpenOpportunities() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for(Opportunity o : [SELECT Id, Name FROM Opportunity WHERE IsClosed = false ORDER BY Name ASC LIMIT 100]) {
            options.add(new Map<String, String>{'label' => o.Name, 'value' => o.Id});
        }
        return options;
    }

    @AuraEnabled
    public static Map<String, Object> getEmailDetails(Id emailId) {
        return OperationsService.getEmailDetails(emailId);
    }

    @AuraEnabled
    public static void completeTask(Id taskId) {
        Task t = new Task(Id = taskId, Status = 'Completed');
        update t;
    }

    @AuraEnabled
    public static void rescheduleTaskTomorrow(Id taskId) {
        Task t = [SELECT Id, ActivityDate FROM Task WHERE Id = :taskId LIMIT 1];
        if (t.ActivityDate == null || t.ActivityDate < Date.today()) {
            t.ActivityDate = Date.today().addDays(1);
        } else {
            t.ActivityDate = t.ActivityDate.addDays(1);
        }
        update t;
    }

    @AuraEnabled
    public static void reassignAppointment(Id appointmentId, String newResourceId) {
        try {
            delete [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :appointmentId];
            
            if (String.isNotBlank(newResourceId) && newResourceId != 'UNASSIGNED') {
                AssignedResource ar = new AssignedResource();
                ar.ServiceAppointmentId = appointmentId;
                ar.ServiceResourceId = (Id)newResourceId;
                insert ar;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error reasignando la cita: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id cloneOpportunity(Id oppId) {
        try {
            // 1. Clonado dinámico de Oportunidad
            Map<String, Schema.SObjectField> oppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
            List<String> oppFields = new List<String>();
            for (String fieldName : oppFieldMap.keySet()) {
                if (oppFieldMap.get(fieldName).getDescribe().isCreateable()) {
                    oppFields.add(fieldName);
                }
            }
            String oppQuery = 'SELECT ' + String.join(oppFields, ',') + ' FROM Opportunity WHERE Id = :oppId LIMIT 1';
            Opportunity original = Database.query(oppQuery);
            
            Opportunity cloned = original.clone(false, true, false, false);
            cloned.Name = original.Name + ' (Copia)';
            cloned.StageName = 'Definición';
            cloned.Subetapa__c = '1';
            cloned.Estado_Subetapa__c = null;
            
            insert cloned;
            
            // 2. Clonar OpportunityLineItem
            Map<String, Schema.SObjectField> oliFieldMap = Schema.SObjectType.OpportunityLineItem.fields.getMap();
            List<String> oliFields = new List<String>();
            for (String fieldName : oliFieldMap.keySet()) {
                if (oliFieldMap.get(fieldName).getDescribe().isCreateable() && fieldName.toLowerCase() != 'totalprice') {
                    oliFields.add(fieldName);
                }
            }
            if (!oliFields.isEmpty()) {
                String oliQuery = 'SELECT ' + String.join(oliFields, ',') + ' FROM OpportunityLineItem WHERE OpportunityId = :oppId';
                List<OpportunityLineItem> originalOlis = Database.query(oliQuery);
                if (!originalOlis.isEmpty()) {
                    List<OpportunityLineItem> clonedOlis = new List<OpportunityLineItem>();
                    for (OpportunityLineItem oli : originalOlis) {
                        OpportunityLineItem clonedOli = oli.clone(false, true, false, false);
                        clonedOli.OpportunityId = cloned.Id;
                        clonedOlis.add(clonedOli);
                    }
                    insert clonedOlis;
                }
            }
            
            // 3. Clonar Levantamiento_Tecnico__c
            Map<String, Schema.SObjectField> levFieldMap = Schema.SObjectType.Levantamiento_Tecnico__c.fields.getMap();
            List<String> levFields = new List<String>();
            for (String fieldName : levFieldMap.keySet()) {
                if (levFieldMap.get(fieldName).getDescribe().isCreateable()) {
                    levFields.add(fieldName);
                }
            }
            if (!levFields.isEmpty()) {
                String levQuery = 'SELECT ' + String.join(levFields, ',') + ' FROM Levantamiento_Tecnico__c WHERE Oportunidad__c = :oppId';
                List<Levantamiento_Tecnico__c> originalLevs = Database.query(levQuery);
                if (!originalLevs.isEmpty()) {
                    List<Levantamiento_Tecnico__c> clonedLevs = new List<Levantamiento_Tecnico__c>();
                    for (Levantamiento_Tecnico__c lev : originalLevs) {
                        Levantamiento_Tecnico__c clonedLev = lev.clone(false, true, false, false);
                        clonedLev.Oportunidad__c = cloned.Id;
                        clonedLevs.add(clonedLev);
                    }
                    insert clonedLevs;
                }
            }
            
            // 4. Clonar Cotizaciones (Quotes) y sus partidas (QuoteLineItem)
            Map<String, Schema.SObjectField> quoteFieldMap = Schema.SObjectType.Quote.fields.getMap();
            List<String> quoteFields = new List<String>();
            for (String fieldName : quoteFieldMap.keySet()) {
                if (quoteFieldMap.get(fieldName).getDescribe().isCreateable()) {
                    quoteFields.add(fieldName);
                }
            }
            if (!quoteFields.isEmpty()) {
                String quoteQuery = 'SELECT ' + String.join(quoteFields, ',') + ' FROM Quote WHERE OpportunityId = :oppId';
                List<Quote> originalQuotes = Database.query(quoteQuery);
                
                if (!originalQuotes.isEmpty()) {
                    Map<Id, Quote> oldQuoteIdToNewQuote = new Map<Id, Quote>();
                    List<Quote> clonedQuotes = new List<Quote>();
                    for (Quote q : originalQuotes) {
                        Quote clonedQuote = q.clone(false, true, false, false);
                        clonedQuote.OpportunityId = cloned.Id;
                        clonedQuote.Status = 'Borrador'; // Reiniciar estatus
                        
                        // Asegurar sufijo de clonado y límite de 255 caracteres
                        String newName = q.Name + ' (Copia)';
                        if (newName.length() > 255) {
                            newName = newName.substring(0, 255);
                        }
                        clonedQuote.Name = newName;
                        
                        clonedQuotes.add(clonedQuote);
                    }
                    insert clonedQuotes;
                    
                    for(Integer i=0; i<originalQuotes.size(); i++) {
                        oldQuoteIdToNewQuote.put(originalQuotes[i].Id, clonedQuotes[i]);
                    }
                    
                    // Clonar Partidas de la Cotización
                    Map<String, Schema.SObjectField> qliFieldMap = Schema.SObjectType.QuoteLineItem.fields.getMap();
                    List<String> qliFields = new List<String>();
                    for (String fieldName : qliFieldMap.keySet()) {
                        String fnLower = fieldName.toLowerCase();
                        if (qliFieldMap.get(fieldName).getDescribe().isCreateable() && fnLower != 'totalprice' && fnLower != 'subtotal' && fnLower != 'listprice') {
                            qliFields.add(fieldName);
                        }
                    }
                    
                    if (!qliFields.isEmpty()) {
                        Set<Id> oldQuoteIds = oldQuoteIdToNewQuote.keySet();
                        String qliQuery = 'SELECT ' + String.join(qliFields, ',') + ' FROM QuoteLineItem WHERE QuoteId IN :oldQuoteIds';
                        List<QuoteLineItem> originalQlis = Database.query(qliQuery);
                        
                        if (!originalQlis.isEmpty()) {
                            List<QuoteLineItem> clonedQlis = new List<QuoteLineItem>();
                            for (QuoteLineItem qli : originalQlis) {
                                QuoteLineItem clonedQli = qli.clone(false, true, false, false);
                                clonedQli.QuoteId = oldQuoteIdToNewQuote.get(qli.QuoteId).Id;
                                clonedQlis.add(clonedQli);
                            }
                            insert clonedQlis;
                        }
                    }
                }
            }
            
            return cloned.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al clonar oportunidad: ' + e.getMessage());
        }
    }
}