public class PullerController
{
    private static Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public FieldsWrapper fw { get; set; }

    public PullerController() {
        fw = new FieldsWrapper();
        initObjNames();
        resetFileds();
    }

    private void initObjNames() {
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        for(String name : entities) {
            fw.objectNames.add(new SelectOption(name, name));
        }
    }
    
    public void showFields()  {
        resetFileds();
        if (fw.selectedObject == '-') {
            return;
        }
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(fw.selectedObject).getDescribe().fields.getMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();
        fw.fieldNames =  new List<SelectOption>();
        
        for (String name : fields) {
            Pair field = new Pair();
            field.name = name;
            field.selected = false;
            fw.lstfieldname.add(field);
            fw.fieldNames.add(new SelectOption(name, name));
        }
    }
    
    public void constructQuery() {
        fw.query = 'SELECT';
        fw.fieldCount = 0;
        for (Pair p : fw.lstfieldname) {
            if (p.selected) {
                fw.query += (fw.fieldCount++ > 0) ? ',' : '' ;
                fw.query += ' ' + p.name;
            }
        }
        
        fw.query += ' FROM ' + fw.selectedObject;
        if (fw.fieldCount == 0) {
            fw.query = 'Choose fields to select from database';
            return;
        }            
        
        Boolean firstCondition = true;
        if (!fw.conditions.isEmpty()) {
            
            String andCondition = '';
            String orCondition = '';

            for (Condition c : fw.conditions) {
                if (c.andOrSelected == fw.AND_STR && !String.isEmpty(c.value)) {
                    andCondition += fw.AND_STR + ' ' + c.fieldSelected + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        andCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        andCondition += ' \'' + c.value + '\' ';
                    }                    
                } else if (c.andOrSelected == fw.OR_STR && !String.isEmpty(c.value)) {
                    orCondition += fw.OR_STR + ' ' + c.fieldSelected + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        orCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        orCondition += ' \'' + c.value + '\' ';
                    }
                }
        	}

            if (!String.isEmpty(andCondition)) {
                fw.query += ' WHERE ';
                andCondition = andCondition.substring(4);
                fw.query += '( ' + andCondition + ' ) ';
                fw.query += orCondition;
            } 
            else if (String.isEmpty(andCondition) && !String.isEmpty(orCondition)) {
                fw.query += ' WHERE ';
                orCondition = orCondition.substring(3);
                fw.query += orCondition;
            }
        }
    }

    public void queryDB() {
        constructQuery();
        if (fw.fieldCount != 0) {
            List<sObject> resultList = new List<sObject>();
            system.debug('QUERY ' + fw.query);

            try {
                resultList = Database.query(fw.query);
            }
            catch (Exception e) {             
            	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            	ApexPages.addMessage(myMsg);
                return;
            }

            if (resultList.size() != 0) {
                fw.selectResult = '';
                for (Integer i=0; i < resultList.size(); i++) {
                    fw.selectResult += resultList.get(i) + '<br/>';
                }
            } else {
                fw.selectResult = 'No records were found';
            }
        }
        else {
            fw.query = 'No fields are selected';
            fw.selectResult = null;
        }
    }

    public void resetFileds() {
        fw.resetFileds();
    }

    public void addCondition() {
        fw.conditions.add(new Condition());
    }
    
    public void removeCondition() {
        if (!fw.conditions.isEmpty()) {
            fw.conditions.remove(fw.conditions.size() - 1);
        }
    }

    private class FieldsWrapper {
        public List <Pair> lstfieldname{ get; set; }
        public List <Pair> fields {
            get {
                return lstfieldname;
            }
            set {
                lstfieldname = value;
            }
        }
        public List <SelectOption> objectNames{ public get; private set; }
        public String selectedObject { get; set; }
        public String query { get; set; }
        public String selectResult { get; set; }
        public Integer fieldCount { get; set; }
        public List <SelectOption> andOrList { public get; private set; }
        public List <SelectOption> operatorsList { public get; private set; }
        public List <Condition> conditions { public get; private set; }
        public List <SelectOption> fieldNames { public get; private set; }
        private final String AND_STR = 'AND';
        private final String OR_STR = 'OR';

        public FieldsWrapper() {
            andOrList = new List<SelectOption>();
            andOrList.add(new SelectOption(AND_STR, AND_STR));
            andOrList.add(new SelectOption(OR_STR, OR_STR));

            operatorsList = new List<SelectOption>();
            operatorsList.add(new SelectOption('=', '='));
            operatorsList.add(new SelectOption('!=', '!='));
            operatorsList.add(new SelectOption('LIKE', 'LIKE'));

            objectNames = new List<SelectOption>();
            objectNames.add(new SelectOption('-', '-'));

            conditions = new List<Condition>();
            fields = new List<Pair>();
        }

        public void resetFileds() {
            fields.clear();
            conditions.clear();
            query = 'Choose fields to select from database';
            selectResult = '';
            fieldCount = 0;
        }
    }

    private class Pair  {
        public String name { get; set; }
        public Boolean selected { get; set; }
    }
    
    private class Condition {
        public String value { get; set; }
        public String andOrSelected { get; set; }
        public String operatorSelected { get; set; }
        public String fieldSelected { get; set; }
    }
}