/**
 * Created by User on 15.08.2017.
 */

@IsTest
private class PullerTest {

    @isTest(SeeAllData=true)
    static void testPositiveBehavior() {
        PullerController pc = new PullerController();
        pc.fw.selectedObject = 'Account';
        pc.showFields();

        pc.constructQuery();
        System.assertEquals('Choose fields to select from database', pc.fw.query);

        PullerController.Pair p = new PullerController.Pair();
        p.name = 'name';
        p.selected = true;
        pc.fw.lstfieldname.add(p);

        List<Account> resultList = Database.query('SELECT name FROM Account');
        String selectResult = '';
        for (Integer i=0; i < resultList.size(); i++) {
            selectResult += resultList.get(i) + '<br/>';
        }

        pc.queryDB();
        system.assertEquals(selectResult, pc.fw.selectResult);

        PullerController.Condition c = new PullerController.Condition();
        c.andOrSelected = 'AND';
        c.fieldSelected = 'accountnumber';
        c.operatorSelected = '=';
        c.value = '123';
        pc.fw.conditions.add(c);

        resultList = Database.query('SELECT name FROM Account WHERE accountnumber = \'123\'');
        selectResult = '';
        for (Integer i=0; i < resultList.size(); i++) {
            selectResult += resultList.get(i) + '<br/>';
        }

        pc.queryDB();
        system.assertEquals(selectResult, pc.fw.selectResult);

        c = new PullerController.Condition();
        c.andOrSelected = 'OR';
        c.fieldSelected = 'accountnumber';
        c.operatorSelected = 'like';
        c.value = 'CC';
        pc.fw.conditions.add(c);

        resultList = Database.query('SELECT name FROM Account WHERE accountnumber = \'123\' or accountnumber LIKE \'%CC%\'');
        selectResult = '';
        for (Integer i=0; i < resultList.size(); i++) {
            selectResult += resultList.get(i) + '<br/>';
        }

        pc.queryDB();
        system.assertEquals(selectResult, pc.fw.selectResult);
    }

    @isTest(SeeAllData=true)
    static void testNegativeBehavior() {
        PullerController pc = new PullerController();
        pc.fw.selectedObject = 'Account';

        PullerController.Pair p = new PullerController.Pair();
        p.name = 'name';
        p.selected = true;
        pc.fw.lstfieldname.add(p);

        PullerController.Condition c = new PullerController.Condition();
        c.andOrSelected = 'AND';
        c.fieldSelected = 'createdbyid';
        c.operatorSelected = '=';
        c.value = '1';
        pc.fw.conditions.add(c);

        system.assertEquals(0, ApexPages.getMessages().size());
        pc.queryDB();
        system.assertEquals(1, ApexPages.getMessages().size());

        pc.fw.conditions.clear();
        c = new PullerController.Condition();
        c.andOrSelected = 'AND';
        c.fieldSelected = 'accountnumber';
        c.operatorSelected = '=';
        c.value = 'DOESNT EXIST';
        pc.fw.conditions.add(c);

        List<Account> resultList = Database.query('SELECT name FROM Account WHERE accountnumber = \'DOESNT EXIST\' ');
        String selectResult = '';
        for (Integer i=0; i < resultList.size(); i++) {
            selectResult += resultList.get(i) + '<br/>';
        }

        pc.queryDB();
        system.assertEquals('No records were found', pc.fw.selectResult);
    }
}