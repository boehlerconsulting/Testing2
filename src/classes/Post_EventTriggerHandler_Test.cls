/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Tests für den EreignisTriggerHandler
*
* date              03.03.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   03.03.2016              *1.0*          Created
*/

@IsTest
private class Post_EventTriggerHandler_Test {

    static testMethod void testeEreignisLoeschung() {
        //Test-User anlegen
        User LO_StandardUser1 = Post_TestTools.createUser( 'myPM Vertrieb (VK)' );
        //Einstellunge anlegen
        Post_TestTools.erzeugeRechteEinstellungenAdmin( UserInfo.getProfileId() );
        Post_TestTools.erzeugeRechteEinstellungenVertrieb( Post_TestTools.profileNames2ProfileIds.get( 'myPM Vertrieb (VK)' ) );

        Test.startTest();

        List< Event > LL_Ereignisse;

        //Als Vertiebs-User ausführen
        System.runAs( LO_StandardUser1 ){
            //Ereignisse anlegen
            LL_Ereignisse = Post_TestTools.erzeugeEreignisse( 1, null, null );

            //Ereignisse versuchen zu löschen
            Exception LO_EreignisAusnahme = null;
            try {
                delete( LL_Ereignisse );
            }catch( Exception LO_Ausnahme ){
                LO_EreignisAusnahme = LO_Ausnahme;
            }
            //Löschen sollte nicht funktionieren
            System.assert(  LO_EreignisAusnahme != null && LO_EreignisAusnahme.getMessage() != null && LO_EreignisAusnahme.getMessage().contains( Label.EreignisLoeschenKeineBerechtigung ), 'Das unberechtigte Löschen eines Ereignisses gibt nicht die korrekte Fehlermeldung zurück' );
        }

        //Ereignisse als Administrator versuchen zu löschen
        Exception LO_EreignisAusnahme;
        try {
            delete( LL_Ereignisse );
        }catch( Exception LO_Ausnahme ){
            LO_EreignisAusnahme = LO_Ausnahme;
        }
        //Löschen sollte funktionieren
        System.assertEquals( null, LO_EreignisAusnahme );

        Test.stopTest();
    }

}