package com.input
{
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	
	public class Key
	{
		private static var keys:Vector.<Boolean>;
		
		public static function init(s:Stage):void
		{
			s.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			s.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			keys = new Vector.<Boolean>(130);
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