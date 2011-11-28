component { 

	remote array function getRecords(numeric records=1) { 
    	var result = [];
        
        for (var x = 0; x < records; x=x+1) {
        	var item = new SampleVO();
            item.itemId = x;
            ArrayAppend( result, item );
        }
        
        return result;
    }
}
