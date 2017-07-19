package input
{
	import starling.core.Starling;
	import starling.display.Stage;
	import starling.events.KeyboardEvent;
	
	public class Key
	{
		private static var keys:Vector.<Boolean>;
		private static var keyUpEvents:Vector.<Vector.<Function>>=new Vector.<Vector.<Function>>(130, true);
		
		public static function init(stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			keys = new Vector.<Boolean>(130, true);
		}
		
		public static  function isDown(keyCode:int):Boolean
		{
			return keys[keyCode];
		}
		
		public static function addKeyUpListener(keyCode:int, listener:Function):void
		{
			if (keyUpEvents[keyCode])
			{
				keyUpEvents[keyCode].push(listener);
			}
			else
			{
				keyUpEvents[keyCode] = new Vector.<Function>(1);
				keyUpEvents[keyCode][0] = listener;
			}
		}
		
		public static function removeKeyUpListener(keyCode:int, listener:Function):void
		{
			keyUpEvents[keyCode].removeAt(keyUpEvents[keyCode].indexOf(listener));
		}
		
		public static function reset():void
		{
			if (keys)
			{
				for (var i:int = 0; i < keys.length; i++)
				{
					if (keys[i])
					{
						var keyEvent:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_UP, 0, i);
						keys[i] = false;
						Starling.current.stage.dispatchEvent(keyEvent);
					}
				}
			}
		}
		
		private static function onKeyDown(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
				keys[e.keyCode] = true;
		}
		
		private static function onKeyUp(e:KeyboardEvent):void
		{
			if (e.keyCode < 130)
			{
				keys[e.keyCode] = false;
				if (keyUpEvents[e.keyCode])
				{
					for (var i:int = 0; i < keyUpEvents[e.keyCode].length; i++)
					{
						keyUpEvents[e.keyCode][i]();
					}
				}
			}
		}
	
	}
}