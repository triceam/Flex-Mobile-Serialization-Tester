package control
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getTimer;
	
	import model.TestSummaryVO;
	import model.TestVO;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.remoting.RemoteObject;
	
	import views.SummaryView;
	
	[Event(name="testStatusChange", type="control.TestUpdateEvent")]
	[Event(name="testUpdate", type="control.TestUpdateEvent")]
	public class SerializationTestController extends EventDispatcher
	{
		private var remoteObject : RemoteObject;
		private var httpService : HTTPService;
		
		private var _testing : Boolean = false;
		
		private var testIndex : int = 0;
		private var iterationIndex : int = 0;
		private var recordCountIndex : int = 0;
		private var testInstanceIndex : int = 0;
		
		private var _results : ArrayCollection;
		private var currentTest : TestVO;
		
		public static const ITERATIONS : int = 5;
		public static const RECORD_COUNT : Array = [1,10,100,1000,10000];
		public static const TESTS : Array = [ TestVO.TYPE_AMF, TestVO.TYPE_JSON ];
		
		public static const REMOTE_OBJECT_SOURCE : String = 	"com.myserver.Services"; //the path to your remote CFC
		public static const REMOTE_OBJECT_ENDPOINT : String = 	"http://myserver.com/flex2gateway/"; //the remote object gateway
		public static const JSON_HTTP_BASE : String = 			"http://myserver.com/path/to/my/cfc";  //the json endpoint base url for the CFC
		
		public function SerializationTestController(target:IEventDispatcher=null)
		{
			super(target);
			
			remoteObject = new RemoteObject("ColdFusion");
			remoteObject.source = REMOTE_OBJECT_SOURCE;
			remoteObject.endpoint = REMOTE_OBJECT_ENDPOINT;
			
			httpService = new HTTPService();
			
			_results = new ArrayCollection();
		}
		
		[Bindable(event="testStatusChange")]
		public function get testing ():Boolean
		{
			return _testing;
		}
		
		public function get results():ArrayCollection
		{
			return _results;
		}
		
		public function get chartResults() : ArrayCollection
		{
			var result : ArrayCollection = new ArrayCollection();
			
			for ( var index : int = 0; index < ITERATIONS; index++ )
			{
				var summaryVO : TestSummaryVO = new TestSummaryVO();
				summaryVO.iteration = index+1;
				result.addItem( summaryVO );
			}
			
			for each ( var vo : TestVO in results )
			{
				summaryVO = result.getItemAt( vo.iteration ) as TestSummaryVO;
					
				if ( vo.type == TestVO.TYPE_AMF )
					summaryVO[ "amfDuration" + SerializationTestController.RECORD_COUNT[ vo.recordIndex ] ] = vo.endTime - vo.startTime;
				else
					summaryVO[ "jsonDuration" + SerializationTestController.RECORD_COUNT[ vo.recordIndex ] ] = vo.endTime - vo.startTime;
				
			}
			
			return result;
		}
		
		
		
		public function startTest() : void
		{
			if ( _testing )  return;
			
			_testing = true;
			testIndex = 0;
			iterationIndex = 0;
			recordCountIndex = 0;
			testInstanceIndex = 0;
			updateTest();
			dispatchEvent( new TestUpdateEvent( TestUpdateEvent.TEST_STATUS ) );
			dispatchEvent( new TestProgressEvent( "STARTING TEST..." ) );
		}
		
		private function completeTest() : void
		{
			_testing = false;
			dispatchEvent( new TestUpdateEvent( TestUpdateEvent.TEST_STATUS ) );
			dispatchEvent( new TestProgressEvent( "TEST COMPLETE" ) );
		}
		
		private function createTestVO() : void
		{
			currentTest = new TestVO();
			currentTest.startTime = getTimer();
			currentTest.index = testInstanceIndex;
			currentTest.iteration = iterationIndex;
			currentTest.recordIndex = recordCountIndex;
			currentTest.type = TESTS[ testIndex ];
		}
		
		private function finalizeTestVO(error : Boolean = false) : void
		{
			if ( error )
				currentTest.endTime = -1
			else
				currentTest.endTime = getTimer();
			
			_results.addItem( currentTest );
			dispatchEvent( new TestUpdateEvent( TestUpdateEvent.TEST_UPDATE,  currentTest ) );
			dispatchEvent( new TestProgressEvent( "task completed in " + (currentTest.endTime - currentTest.startTime) + " milliseconds" ) );
			currentTest = null;
		}
		
		private function updateTest() : void
		{
			if ( iterationIndex >= ITERATIONS )
				return completeTest();
			
			createTestVO();
			
			if ( TESTS[ testIndex ] == TestVO.TYPE_AMF )
			{
				doAMFTest();
				recordCountIndex ++;
				
				if ( recordCountIndex >= RECORD_COUNT.length )
				{
					recordCountIndex = 0;
					testIndex++;
				}
			}
			
			else if ( TESTS[ testIndex ] == TestVO.TYPE_JSON )
			{
				doJSONTest();
				recordCountIndex ++;
				
				if ( recordCountIndex >= RECORD_COUNT.length )
				{
					recordCountIndex = 0;
					testIndex = 0;
					iterationIndex ++;
				}
			}
			
			testInstanceIndex++;
		}
		
		private function doAMFTest() : void
		{
			dispatchEvent( new TestProgressEvent( "AMF Requesting " + RECORD_COUNT[ recordCountIndex ] ) );
			var token : AsyncToken = remoteObject.getRecords( RECORD_COUNT[ recordCountIndex ] );
			token.addResponder( new mx.rpc.Responder( onAMFResult, onFault ) );
		}
		
		
		
		protected function onAMFResult( event : ResultEvent ) : void
		{
			var result : ArrayCollection = event.result as ArrayCollection;
			finalizeTestVO();
			updateTest();
		}
		
		private function doJSONTest() : void
		{
			dispatchEvent( new TestProgressEvent( "JSON Requesting " + RECORD_COUNT[ recordCountIndex ] ) );
			httpService.url = JSON_HTTP_BASE + "/Services.cfc?method=getrecords&records=" + RECORD_COUNT[ recordCountIndex ] + "&returnformat=json";
			var token : AsyncToken = httpService.send();
			token.addResponder( new mx.rpc.Responder( onJSONResult, onFault ) );
		}
		
		protected function onJSONResult( event : ResultEvent ) : void
		{
			var resultString : String = event.result as String;
			var result : ArrayCollection = new ArrayCollection( JSON.parse( resultString ) as Array );
			
			finalizeTestVO();
			updateTest();
			
		}
		
		protected function onFault( event : FaultEvent ) : void
		{
			trace( event.fault.toString() );
			finalizeTestVO(true);
			updateTest();
		}
		
	}
}