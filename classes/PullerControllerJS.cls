public class PullerControllerJS
{
    private static Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public FieldsWrapper fw { get; set; }
    public static List<String> objectNames = new List<String>();
    public static List<Pair> fieldList = new List<Pair>();
    public static List<Condition> conditions = new List<Condition>();

    @RemoteAction
    public static List<String> getObjectNames() {
        initObjNames();
        return objectNames;
    }

    @RemoteAction
    public static List<Pair> getFieldList(String selectedName) {
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(selectedName).getDescribe().fields.getMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();

        for (String name : fields) {
            Pair field = new Pair();
            field.name = name;
            field.selected = false;
            fieldList.add(field);
        }
        return fieldList;
    }

    @RemoteAction
    public static List<String> getSelectedFields(List<Pair> fieldList2) {
        List<String> fieldNames = new List<String>();
        for (Pair p : fieldList2) {
            if (p.selected) {
                fieldNames.add(p.name);
            }
        }
        return fieldNames;
    }

    public PullerControllerJS() {
        fw = new FieldsWrapper();
        initObjNames();
        resetFileds();
    }

    private static void initObjNames() {
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        for(String name : entities) {
            objectNames.add(name);
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

    @RemoteAction
    public static String constructQuery(List<Pair> fieldList, String selectedObject, List<Condition> conditions) {
        String query = 'SELECT';
        Integer fieldCount = 0;
        for (Pair p : fieldList) {
            if (p.selected) {
                query += (fieldCount++ > 0) ? ',' : '' ;
                query += ' ' + p.name;
            }
        }

        query += ' FROM ' + selectedObject;
        if (fieldCount == 0) {
            query = 'Choose fields to select from database';
        }

        Boolean firstCondition = true;
        if (!conditions.isEmpty()) {

            String andCondition = '';
            String orCondition = '';

            for (Condition c : conditions) {
                if (c.andOrSelected == 'AND' && !String.isEmpty(c.value)) {
                    andCondition += 'AND ' + c.field + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        andCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        andCondition += ' \'' + c.value + '\' ';
                    }
                } else if (c.andOrSelected == 'OR' && !String.isEmpty(c.value)) {
                    orCondition += 'OR ' + c.field + ' ' + c.operatorSelected;
                    if (c.operatorSelected == 'LIKE') {
                        orCondition += ' \'%' + c.value + '%\' ';
                    } else {
                        orCondition += ' \'' + c.value + '\' ';
                    }
                }
            }

            if (!String.isEmpty(andCondition)) {
                query += ' WHERE ';
                andCondition = andCondition.substring(4);
                query += '( ' + andCondition + ' ) ';
                query += orCondition;
            }
            else if (String.isEmpty(andCondition) && !String.isEmpty(orCondition)) {
                query += ' WHERE ';
                orCondition = orCondition.substring(3);
                query += orCondition;
            }
        }
        return query;
    }

    @RemoteAction
    public static String queryDB(List<Pair> fieldList, String selectedObject, List<Condition> conditions) {
        String query = constructQuery(fieldList, selectedObject, conditions);
        String queryResultStr;
        if (query != 'Choose fields to select from database' && !fieldList.isEmpty()) {
            List<sObject> selectResult = new List<sObject>();
            system.debug('fieldList ' + fieldList);
            system.debug('query' + query);
            try {
                selectResult = Database.query(query);
            }
            catch (Exception e) {
                return e.getMessage();
            }


            if (selectResult.size() != 0) {
                queryResultStr = '';
                for (Integer i=0; i < selectResult.size(); i++) {
                    queryResultStr += selectResult.get(i) + '\n';
                }
            } else {
                queryResultStr = 'No records were found';
            }
        }
        else {
        //    query = 'No fields are selected';
            queryResultStr = 'No fields are selected';
        }
        return queryResultStr;
    }

    public void resetFileds() {
        fw.resetFileds();
    }

    @RemoteAction
    public static List<Condition> addCondition(List<Condition> conditions) {
        conditions.add(new Condition());
        return conditions;
    }

    @RemoteAction
    public static List<Condition> removeCondition(List<Condition> conditions, Integer index) {
        if (!conditions.isEmpty()) {
            conditions.remove(index);
        }
        return conditions;
    }

    @RemoteAction
    public static List<Condition> getConditions() {
        return conditions;
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
        public String selectedObject { get; set; }
        public String query { get; set; }
        public String selectResult { get; set; }
        public Integer fieldCount { get; set; }
        public List <SelectOption> andOrList { public get; private set; }
        public List <SelectOption> operatorsList { public get; private set; }
   //     public List <Condition> conditions { public get; private set; }
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

      //      objectOptions = new List<SelectOption>();
      //      objectOptions.add(new SelectOption('-', '-'));

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
        public String field { get; set; }
    }
}