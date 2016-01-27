package com.spaceshipStudent
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import DDLS.ai.DDLSEntityAI;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.utils.AssetManager;
	
	public class BodyInfo
	{
		public var body:Body;
		public var graphics:DisplayObject;
		protected var _entityAI:DDLSEntityAI;
		protected var assetsLoader:AssetManager;
		internal static var list:Vector.<BodyInfo> = new Vector.<BodyInfo>();
		
		public function BodyInfo(position:Vec2)
		{
			_entityAI = new DDLSEntityAI();
			_entityAI.x = position.x;
			_entityAI.y = _entityAI.y;
			body = new Body(BodyType.DYNAMIC, position);
			body.userData.info = this;
			list.push(this);
		}
		
		public function init(assetsLoader:AssetManager, bodyDescription:Object, bodyDisplay:DisplayObject):void
		{
			this.assetsLoader = assetsLoader;
			var child:Image;
			for (var i:int = 0; i < bodyDescription.children.length; i++)
			{
				child = new Image(assetsLoader.getTexture(bodyDescription.children[i].imageName));
				child.x = bodyDescription.children[i].x;
				child.y = bodyDescription.children[i].y;
				child.pivotX = child.width / 2;
				child.pivotY = child.height / 2;
				(bodyDisplay as DisplayObjectContainer).addChild(child);
			}
			graphics = bodyDisplay;
			entityAI.radius = 30 + Math.sqrt(body.bounds.width * body.bounds.width + body.bounds.height * body.bounds.height) / 2;
			entityAI.buildApproximation();
			entityAI.radius -= 30;
		}
		
		public function updatePhysics():void
		{
			graphics.x = body.position.x;
			graphics.y = body.position.y;
			graphics.rotation = body.rotation;
			entityAI.x = body.position.x;
			entityAI.y = body.position.y;
			entityAI.approximateObject.x = body.position.x + body.velocity.x / 2;
			entityAI.approximateObject.y = body.position.y + body.velocity.y / 2;
		}
		
		public function updateLogic():void
		{
			
		}
		
		public function get entityAI():DDLSEntityAI
		{
			return _entityAI;
		}
	}

}