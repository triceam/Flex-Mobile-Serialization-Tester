package control
{
	import flash.events.Event;
	
	public class TestProgressEvent extends Event
	{
		public static const PROGRESS : String = "testProgress";
		
		public var message : String;
		
		public function TestProgressEvent(message : String)
		{
			super(PROGRESS);
			this.message = message;
		}
	}
}