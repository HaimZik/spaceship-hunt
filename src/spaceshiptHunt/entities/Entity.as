package spaceshiptHunt.entities
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import spaceshiptHunt.entities.BodyInfo;
	import DDLS.ai.DDLSEntityAI;
	import spaceshiptHunt.level.Environment;
	import nape.geom.Vec2;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.extensions.lighting.LightStyle;
	import starling.textures.Texture;
	
	public class Entity extends BodyInfo
	{
		protected var _pathfindingAgent:DDLSEntityAI;
		static protected var pathfindingAgentSafeDistance:Number = 30;
		protected var pathUpdateInterval:int = 48;
		
		public function Entity(position:Vec2)
		{
			super(position);
			_pathfindingAgent = new DDLSEntityAI();
			_pathfindingAgent.x = position.x;
			_pathfindingAgent.y = _pathfindingAgent.y;
			BodyInfo.list.push(this);
			graphics = new Sprite();
		}
		
		override public function init(bodyDescription:Object):void
		{
			var child:Image;
			for (var i:int = 0; i < bodyDescription.children.length; i++)
			{
				child = new Image(Environment.current.assetsLoader.getTexture(bodyDescription.children[i].textureName));
				var normalMap:Texture = Environment.current.assetsLoader.getTexture(bodyDescription.children[i].textureName + "_n");
				var lightStyle:LightStyle = new LightStyle(normalMap);
				lightStyle.light = Environment.current.light;
				child.style = lightStyle;
				child.x = bodyDescription.children[i].x;
				child.y = bodyDescription.children[i].y;
				child.pivotX = child.width / 2;
				child.pivotY = child.height / 2;
				(graphics as DisplayObjectContainer).addChild(child);
			}
			pathfindingAgent.radius = pathfindingAgentSafeDistance + Math.sqrt(body.bounds.width * body.bounds.width + body.bounds.height * body.bounds.height) / 2;
			pathfindingAgent.buildApproximation();
			pathfindingAgent.radius -= pathfindingAgentSafeDistance;
			Environment.current.navMesh.insertObject(pathfindingAgent.approximateObject);
		}
		
		override protected function updateGraphics():void
		{
			super.updateGraphics();
			pathfindingAgent.x = body.position.x;
			pathfindingAgent.y = body.position.y;
			var dirNorm:Vec2 = Vec2.fromPolar(1, body.rotation - Math.PI / 2);
			pathfindingAgent.dirNormX = dirNorm.x;
			pathfindingAgent.dirNormY = dirNorm.y;
			dirNorm.dispose();
			pathfindingAgent.approximateObject.x = body.position.x + body.velocity.x / 2;
			pathfindingAgent.approximateObject.y = body.position.y + body.velocity.y / 2;
		}
		
		public function get pathfindingAgent():DDLSEntityAI
		{
			return _pathfindingAgent;
		}
		
		CONFIG::debug
		{
			import DDLS.view.DDLSSimpleView;		
			public function drawDebug(canvas:DDLSSimpleView):void
			{
				canvas.drawEntity(pathfindingAgent, false);
			}
		}
	}

}