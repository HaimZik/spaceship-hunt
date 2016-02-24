package com.spaceshiptHunt.entities
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import com.spaceshiptHunt.entities.BodyInfo;
	import com.spaceshiptHunt.level.Environment;
	import DDLS.ai.DDLSEntityAI;
	import starling.display.DisplayObject;
	import nape.geom.Vec2;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	
	public class Entity extends BodyInfo
	{
		protected var _pathfindingAgent:DDLSEntityAI;
		
		public function Entity(position:Vec2)
		{
			super(position);
			_pathfindingAgent = new DDLSEntityAI();
			_pathfindingAgent.x = position.x;
			_pathfindingAgent.y = _pathfindingAgent.y;
			BodyInfo.list.push(this);
		}
		
		public function init(bodyDescription:Object, bodyDisplay:DisplayObject):void
		{
			var child:Image;
			for (var i:int = 0; i < bodyDescription.children.length; i++)
			{
				child = new Image(Environment.assetsLoader.getTexture(bodyDescription.children[i].imageName));
				child.x = bodyDescription.children[i].x;
				child.y = bodyDescription.children[i].y;
				child.pivotX = child.width / 2;
				child.pivotY = child.height / 2;
				(bodyDisplay as DisplayObjectContainer).addChild(child);
			}
			graphics = bodyDisplay;
			pathfindingAgent.radius = 30 + Math.sqrt(body.bounds.width * body.bounds.width + body.bounds.height * body.bounds.height) / 2;
			pathfindingAgent.buildApproximation();
			pathfindingAgent.radius -= 30;
		}
		
		override protected function updateGraphics():void
		{
			super.updateGraphics();
			pathfindingAgent.x = body.position.x;
			pathfindingAgent.y = body.position.y;
			pathfindingAgent.approximateObject.x = body.position.x + body.velocity.x / 2;
			pathfindingAgent.approximateObject.y = body.position.y + body.velocity.y / 2;
		}
		
		public function get pathfindingAgent():DDLSEntityAI
		{
			return _pathfindingAgent;
		}
	}

}