package spaceshiptHunt.entities
{
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import starling.display.DisplayObject;
	
	public class BodyInfo
	{
		public static var list:Vector.<BodyInfo> = new Vector.<BodyInfo>();
		public var body:Body;
		public var graphics:DisplayObject;
		public var infoFileName:String;
		
		public function BodyInfo(position:Vec2)
		{
			body = new Body(BodyType.DYNAMIC, position);
			body.userData.info = this;
		}
		
		protected function updateGraphics():void
		{
			graphics.x = body.position.x;
			graphics.y = body.position.y;
			graphics.rotation = body.rotation;
		}
		
		public function init(bodyDescription:Object):void
		{
		}
		
		public function update():void
		{
			if (!body.isSleeping)
			{
				updateGraphics();
			}
		}
	
	}
}