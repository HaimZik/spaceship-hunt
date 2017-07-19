package spaceshiptHunt.level
{
	import avmplus.getQualifiedClassName;
	import spaceshiptHunt.entities.*;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class LevelInfo
	{
		//to enable dynamic creation of clasess from json files.
		private static const allowedTypes:Vector.<Class> = new <Class>[PreyEnemy,Player,EnemyPathBlocker];
		public static var entityTypes:Dictionary=new Dictionary();
		
		[Embed(source = "level1.json", mimeType = "application/octet-stream")]
		public static const Level1:Class;
		[Embed(source = "level1Test.json", mimeType = "application/octet-stream")]
		public static const Level1Test:Class;
		
		   // static initializer
		{
			init();
		}
		
		private static function init():void
		{
			for (var i:int = 0; i < allowedTypes.length; i++)
			{
				entityTypes[getQualifiedClassName(allowedTypes[i])] = allowedTypes[i];
			}
		}

	}

}