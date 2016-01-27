package com.input
{
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	
	public class Key
	{
		private static var keys:Vector.<Boolean>;
		
		public static function init(s:Stage):void
		{
			s.addEventListener(KeyboardEvent.KEY_DOWN, okd);
			s.addEventListener(KeyboardEvent.KEY_UP, oku);
			keys = new Vector.<Boolean>(130);
		}
		
		private static function okd(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
				keys[e.keyCode] = true;
		}
		
		private static function oku(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
				keys[e.keyCode] = false;
		}
		
		static public function isDown(n:int):Boolean
		{
			return keys[n];
		}
		
		public static function get dIsDown():Boolean
		{
			return keys[68];
		}
		
		public static function get lIsDown():Boolean
		{
			return keys[76];
		}
		
		public static function get pIsDown():Boolean
		{
			return keys[80];
		}
		
		public static function get aIsDown():Boolean
		{
			return keys[65];
		}
		
		public static function get sIsDown():Boolean
		{
			return keys[83];
		}
		
		public static function get wIsDown():Boolean
		{
			return keys[87];
		}
	}
}