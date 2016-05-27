package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author Haim
	 */
	public class Main extends Sprite
	{
		private var gameEngine:Starling;
		
		public function Main()
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			Starling.multitouchEnabled = true;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			removeEventListener(Event.ADDED_TO_STAGE, init);
			gameEngine = new Starling(Game, stage, null, null, "auto", "baselineExtended");
			//gameEngine.skipUnchangedFrames = true;
			gameEngine.antiAliasing = 4;
			gameEngine.showStats = true;
		}
	
	}
}