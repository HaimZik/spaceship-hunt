package input
{
	import starling.display.Stage;
	import starling.events.KeyboardEvent;
	
	public class Key
	{
		private static var keys:Vector.<Boolean>;
		
		public static function init(stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			keys = new Vector.<Boolean>(130, true);
		}
		
		private static function onKeyDown(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
				keys[e.keyCode] = true;
		}
		
		private static function onKeyUp(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
				keys[e.keyCode] = false;
		}
		
		static public function isDown(n:int):Boolean
		{
			return keys[n];
		}
	}
}