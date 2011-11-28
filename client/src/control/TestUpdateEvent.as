package control
{
	import flash.events.Event;
	
	import model.TestVO;
	
	public class TestUpdateEvent extends Event
	{
		public static const TEST_UPDATE : String = "testUpdate";
		public static const TEST_STATUS : String = "testStatusChange";
		
		public var vo : TestVO;
		
		public function TestUpdateEvent( type : String, vo : TestVO = null)
		{
			super(type);
			this.vo = vo;
		}
	}
}