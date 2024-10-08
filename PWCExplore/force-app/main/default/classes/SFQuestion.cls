/**
 * Renaming old "Question" to "SFQuestion" class
 * This is to avoid problem with "Question" object which is added by Chatter Answers
 *
 * Class: question
 *  Retrieves the question information and puts it in the question object
 *
 */

public inherited sharing class SFQuestion {
	public String name { get; set; }
	public String id { get; set; }
	public String question { get; set; }
	public String orderNumber { get; set; }
	public String choices { get; set; }
	public String selectedOption { get; set; }
	public String inputText { get; set; }
	public List<String> selectedOptions { get; set; }
	public List<SelectOption> responseOptions { get; set; }
	public Boolean required { get; set; }
	public String questionType { get; set; }
	public Boolean renderFreeText { get; set; }
	public Boolean renderRadioVertical { get; set; }
	public Boolean renderMultiCheckboxes { get; set; }
	public Boolean renderRadioHorizontal { get; set; }
	//public Boolean renderInput                {get; set;}

	public Boolean noData { get; set; }
	public String noOfRowsForTextArea { get; set; }
	public Survey_Question__c q { get; set; }

    public Boolean isVisible { get; set; }
	/**
	 * @description Constructor Fills up the question object
	 * @param  sq Survey Question Record
	 */
	public SFQuestion(Survey_Question__c sq) {
		this.q = sq;
		name = sq.Name;
		id = sq.Id;
		question = sq.Question__c;
		orderNumber = String.valueOf(sq.OrderNumber__c + 1);
		choices = sq.Choices__c;
		required = sq.Required__c;
		questionType = sq.Type__c;
		selectedOption = '';
		selectedOptions = new List<String>();
		renderMultiCheckboxes = false;
		renderFreeText = false;
		renderRadioHorizontal = false;
		renderRadioVertical = false; 
		responseOptions = new List<SelectOption>();
     	
        //isVisible = true;
  		isVisible = checkVisibility(new Map<Id, String>());

        
		if (sq.Type__c == 'Single Select--Vertical') {
			renderRadioVertical = true;
			responseOptions = stringToSelectOptions(choices);
		} else if (sq.Type__c == 'Multi-Select--Vertical') {
			renderMultiCheckboxes = true;
			responseOptions = stringToSelectOptions(choices);
		} else if (sq.Type__c == 'Single Select--Horizontal') {
			responseOptions = stringToSelectOptions(choices);
            
			renderRadioHorizontal = true;
		} else if (sq.Type__c == 'Free Text' || sq.Type__c == 'Free Text - Single Row Visible') {
			renderFreeText = true;
			choices = '';
			inputText = '';
			//If it's text area but for single row then only show single row even though it's stil text area
			if (sq.Type__c == 'Free Text - Single Row Visible') {
				noOfRowsForTextArea = '1';
			} else {
				noOfRowsForTextArea = '5';
			}
		}
	}
    
    public class DependencyCriteria
	{
        public String logic { get; set; }
        public List<DependencyCondition> conditions { get; set; }
	}

	public class DependencyCondition
	{
    	public Id questionId { get; set; }
    	public String operator { get; set; }
    	public String value { get; set; }
	}
    
    public Boolean checkVisibility(Map<Id, String> responses)
        {
            if(String.isBlank(q.Dependency_Criteria__c))
            {
                return true;
            }
          	DependencyCriteria criteria = (DependencyCriteria) JSON.deserialize(q.Dependency_Criteria__c, DependencyCriteria.class);
            Boolean result = (criteria.logic == 'AND') ? true : false;
            
            for (DependencyCondition condition : criteria.conditions)
            {
                String responseValue = responses.get(condition.questionId);
                System.debug('responseValue ' + responseValue);
                Boolean conditionMet = responseValue != null && evaluateCondition(responseValue, condition.operator, condition.value);
                System.debug('conditionMet ' + conditionMet);
                
                if (criteria.logic == 'AND')
                {
                    result = result && conditionMet;
                    if(!result) break;
                }
                else if (criteria.logic == 'OR')
                {
                    result = result || conditionMet;
                    if(result) break;
                }
            }
            System.debug('isVisible ' + result);
            return result;
        }
    
    public Boolean evaluateCondition(String responseValue, String operator, String value)
    {
        Decimal responseDecimal;
        Decimal valueDecimal;
        Boolean comparisonResult = false;
        
        if (operator == '==')
        {
            comparisonResult = responseValue == value;
        }
        else if (operator == '!=')	
        {
            comparisonResult = responseValue != value;
        }
        else if (operator == '<')
        {
            responseDecimal = Decimal.valueOf(responseValue);
            valueDecimal = Decimal.valueOf(value);
            comparisonResult = responseDecimal < valueDecimal;
        }
        else if (operator == '<=')
        {
            responseDecimal = Decimal.valueOf(responseValue);
            valueDecimal = Decimal.valueOf(value);
            comparisonResult = responseDecimal <= valueDecimal;
        }
        else if (operator == '>')
        {
            responseDecimal = Decimal.valueOf(responseValue);
            valueDecimal = Decimal.valueOf(value);
            comparisonResult = responseDecimal > valueDecimal;
        }
        else if (operator == '>=')
        {
            responseDecimal = Decimal.valueOf(responseValue);
            valueDecimal = Decimal.valueOf(value);
            comparisonResult = responseDecimal >= valueDecimal;
        }
        
        return comparisonResult;
    }
    
    

	/**s
	 * Splits up the string as given by the user and adds each option to a list to be displayed as option on the Visualforce page
	 *
	 * @param str String (new-line separated) to parse into SelectOptions
	 * @return    `List<SelectOption>` picklist of question options
	 */
	private List<SelectOption> stringToSelectOptions(String str) {
		if (str == '') {
			return new List<SelectOption>();
		}
		List<String> strList = str.split('\n');

		List<SelectOption> returnVal = new List<SelectOption>();
		Integer i = 0;
		for (String s : strList) {
			if (String.isNotBlank(s) && s != 'null') {
				s.unescapeHtml4();
				returnVal.add(new SelectOption(String.valueOf(i), s));
				i++;
			}
		}
		return returnVal;
	}
    
    
}