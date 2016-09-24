package spaceshiptHuntDevelopment.level
{
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	CONFIG::air
	{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.events.Event
	import starling.core.Starling;
	import starling.events.TouchPhase;
	
	public class DragAndDropArea extends Sprite
	{
		public var onFileDrop:Function;
		
		public function DragAndDropArea(x:int, y:int, width:int, height:int, onFileDrop:Function)
		{
			this.graphics.beginFill(0xff0000, 0);
			this.graphics.drawRect(x, y, width, height);
			this.graphics.endFill();
			addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
			this.onFileDrop = onFileDrop;
		}
		
//called when the user drags an item into the component area
		private function onDragIn(e:NativeDragEvent):void
		{
			//check and see if files are being drug in
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				//get the array of files
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				
				//make sure only one file is dragged in (i.e. this app doesn't
				//support dragging in multiple files)
				if (files.length == 1)
				{
					//accept the drag action
					NativeDragManager.acceptDragDrop(this);
				}
			}
		}
		
//called when the user drops an item over the component
		private function onDragDrop(e:NativeDragEvent):void
		{
			//get the array of files being drug into the app
			var fileList:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			onFileDrop(e.stageX, e.stageY, fileList[0]);
		}
	}
}
}