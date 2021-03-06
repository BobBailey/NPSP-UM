/*
    Copyright (c) 2011, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2011 (2.0)
* @description The controller for the VF page invoked by using the bulk opp rollups tab 
*/
public class CTRL_OpportunityRollup {
 
    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public CTRL_OpportunityRollup() {
        batchRunning = false;

        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {     
        }  
        
        if (oid != null) {
            batching = false;           
        } else {
            batching = true;
        }
    }
    
    public PageReference startAction() {
        PageReference ref;
        if (oid != null){            
            // run the rollup for the specified object
            OpportunityRollups rg = new OpportunityRollups();
            if (objectId.startsWith('001')){
                Account a = [select id from Account where id = :oid];
                rg.RollupAccounts(new map<id, Account>(new list<Account>{a}));
            }                
            else if (objectId.startsWith('003')){
                Contact c = [select TotalOppAmount__c, OppAmountLastYear__c, 
                    OppAmount2YearsAgo__c, OppAmountLastNDays__c,
                    OppAmountThisYear__c, TotalMembershipOppAmount__c,
                    LastCloseDate__c, MembershipEndDate__c,
                    MembershipJoinDate__c, LastMembershipLevel__c from Contact where id = :oid];
                rg.RollupContacts(new map<id, Contact>(new list<Contact>{c}));                
            }                
            else{ 
                Household__c h = [select id from Household__c where id = :oid];
                rg.RollupHouseholds(new map<id, Household__c>(new list<Household__c>{h}));                
            }    
            ref = new PageReference('/' + oid);
            ref.setRedirect(true);
        }
        return ref;
    }

    public PageReference rollup() {
        
        // run batch rollup
        OpportunityRollups rg = new OpportunityRollups();
        rg.rollupAll();
        
        batchRunning = true;
        return null;                
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

    public static testMethod void testRollup() {
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
            new Households_Settings__c (
                Household_Rules__c = Households.ALL_PROCESSOR,
                Always_Rollup_to_Primary_Contact__c = true,
                Enable_Opp_Rollup_Triggers__c = true,
                Excluded_Account_Opp_Rectypes__c = null,
                Excluded_Account_Opp_Types__c = null,
                Excluded_Contact_Opp_Rectypes__c = null,
                Excluded_Contact_Opp_Types__c = null,
                Membership_Record_Types__c = null
            ));
        
        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
            Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
            Enable_Opportunity_Contact_Role_Trigger__c = true,
            Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
        Date datClose = System.Today();
            
        // create & insert contact(s)
        Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 50 ) ;
        insert TestCons;

        // create new opps
        Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);

        account testacct = new account(name='testacct');
        insert testacct;

        Test.startTest();

        // create the page 
        PageReference pageRef=Page.OpportunityRollup; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', testcons[3].id);
        
        // instantiate the controller
        CTRL_OpportunityRollup controller=new CTRL_OpportunityRollup();

        // rollup the contact
        pageReference nextref = controller.startAction();       

        system.assert(nextref.getUrl().contains(testcons[3].id));
        
        // roll up everyone
        controller.rollup();
        controller.cancel();
    }

}