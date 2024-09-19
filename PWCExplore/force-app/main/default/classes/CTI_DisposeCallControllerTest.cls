@IsTest
public with sharing class CTI_DisposeCallControllerTest {

    @IsTest
    static void testDisposeTheCall() {        
		Test.setMock(HttpCalloutMock.class, new MockCTI_DisposeCallController());
        List<CTI_DisposeCallController.DisposeInputs> disInputList = new List<CTI_DisposeCallController.DisposeInputs>();
        List<CTI_DisposeCallController.DisposeOutput> disOutput = new List<CTI_DisposeCallController.DisposeOutput>();
        CTI_DisposeCallController.DisposeInputs disInput = new CTI_DisposeCallController.DisposeInputs();
        disInput.currentUser = 'Test User';
        disInput.currentCaseId = '50023000003Nx2xAAC';
        disInput.uniqueConId = '50023000003Nx2x';
        disInputList.add(disInput);
        disOutput = CTI_DisposeCallController.disposeTheCall(disInputList);
        system.assertEquals(disOutput[0].resultMsg, '{"Test": "Mockdata"}');
    }
}