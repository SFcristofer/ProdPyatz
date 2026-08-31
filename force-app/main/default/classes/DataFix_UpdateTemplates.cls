public without sharing class DataFix_UpdateTemplates {
    public static void updateTemplates(Map<String, String> tipoToPreguntas) {
        List<Form_Template__c> toUpdate = new List<Form_Template__c>();
        for(Form_Template__c t : [SELECT Id, Tipo_Reporte__c FROM Form_Template__c]) {
            if(tipoToPreguntas.containsKey(t.Tipo_Reporte__c)) {
                t.put('Preguntas__c', tipoToPreguntas.get(t.Tipo_Reporte__c));
                toUpdate.add(t);
            }
        }
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}