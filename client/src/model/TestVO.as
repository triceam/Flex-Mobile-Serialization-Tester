package model
{
	public class TestVO
	{
		public static const TYPE_JSON : String = "json";
		public static const TYPE_AMF : String = "amf";
		
		public var index : int;
		public var iteration : int = 0;
		public var startTime : int;
		public var endTime : int;
		public var type : String;
		public var recordIndex : int;
		
		public function TestVO()
		{
		}
	}
}