package spaceshiptHunt.entities
{
	import DDLS.ai.DDLSEntityAI;
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.entities.Entity;
	import flash.utils.Dictionary;
	import nape.geom.Vec2;
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.textures.Texture;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Spaceship extends Entity
	{
		public var maxAcceleration:Number;
		public var maxTurningAcceleration:Number;
		public var engineLocation:Vec2;
		protected var _gunType:String;
		protected var fireType:String = "fireball";
		protected var weaponsPlacement:Dictionary;
		protected var weaponRight:Image;
		protected var weaponLeft:Image;
		protected const firingRate:Number = 0.1;
		private var shootingCallId:uint;
		
		public function Spaceship(position:Vec2)
		{
			super(position);
			weaponsPlacement = new Dictionary(true);
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			engineLocation = Vec2.get(bodyDescription.engineLocation.x, bodyDescription.engineLocation.y);
			maxAcceleration = body.mass * 8;
			maxTurningAcceleration = body.mass * 5;
		}
		
		public function set gunType(gunType:String):void
		{
			_gunType = gunType;
			var texture:Texture = Environment.current.assetsLoader.getTexture(gunType);
			if (weaponRight)
			{
				weaponRight.texture = texture;
				weaponRight.readjustSize();
				weaponLeft.texture = texture;
				weaponLeft.readjustSize();
			}
			else
			{
				weaponRight = new Image(texture);
				weaponLeft = new Image(texture);
				(graphics as DisplayObjectContainer).addChildAt(weaponRight, 0);
				(graphics as DisplayObjectContainer).addChildAt(weaponLeft, 0);
			}
			var position:Vec2 = weaponsPlacement[gunType];
			weaponRight.x = position.x;
			weaponRight.y = position.y;
			weaponLeft.x = -position.x - weaponLeft.width;
			weaponLeft.y = position.y;
		}
		
		public function get gunType():String
		{
			return _gunType;
		}
		
		public function startShooting():void
		{
			if (!Starling.juggler.containsDelayedCalls(shootParticle))
			{
				shootingCallId = Starling.juggler.repeatCall(shootParticle, firingRate);
			}
		}
		
		public function stopShooting():void
		{
			Starling.juggler.removeByID(shootingCallId);
		}
		
		public function findPathTo(x:Number, y:Number, outPath:Vector.<Number>):void
		{
			Environment.current.findPath(pathfindingAgent, x, y, outPath);
		}
		
		public function findPathToEntity(entity:DDLSEntityAI, outPath:Vector.<Number>):void
		{
			var diraction:Vec2 = Vec2.weak(entity.x - _pathfindingAgent.x, entity.y - _pathfindingAgent.y);
			diraction.length = pathfindingAgent.radius + entity.radius + pathfindingAgentSafeDistance * 2 + 2;
			findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
			for (var i:int = 0; i < 3; i++)
			{
				if (outPath.length == 0)
				{
					diraction.set(diraction.perp(true));
					findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
				}
				else
				{
					diraction.dispose();
					return;
				}
			}
			diraction.dispose();
			Environment.current.meshNeedsUpdate = true;
		}
		
		protected function shootParticle():void
		{
			var position:Vec2 = Vec2.get(weaponRight.x + weaponLeft.width / 2, weaponRight.y - 5);
			var impulse:Vec2 = Vec2.get(0, 200 + Math.random() * 200);
			impulse.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 + 0.05;
			PhysicsParticle.spawn(fireType, position.copy(true).rotate(body.rotation).addeq(body.position), impulse);
			position.x = weaponLeft.x + weaponLeft.width / 2;
			impulse.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 - 0.05;
			PhysicsParticle.spawn(fireType, position.rotate(body.rotation).addeq(body.position), impulse);
			body.applyImpulse(impulse.mul(-0.3));
			position.dispose();
			impulse.dispose();
		}
	
		//public function jetParticlePositioning(particles:Vector.<PDParticle>, numActive:int):void
		//{
		//var p:PDParticle;
		//var velocityLength:Number = body.velocity.length;
		//var speedL:Number = velocityLength / 10 + body.angularVel * 10;
		//for (var i:int = 0; i < numActive; i += 2)
		//{
		//p = particles[i];
		//if (p.x > -5)
		//{
		//p.x -= engineLocation.x * 2 - 5;
		//p.y -= 5;
		//if (speedL < 35)
		//{
		//if (velocityLength < 20)
		//{
		//p.alpha = 0;
		//}
		//else
		//{
		//p.velocityY += Math.abs(speedL);
		//}
		//}
		//else
		//{
		//p.tangentialAcceleration = -body.angularVel * 30;
		//p.velocityY += speedL;
		//}
		//}
		//else
		//{
		//p.alpha = 0;
		//}
		//}
		//var speedR:Number = -body.angularVel * 1.3 + velocityLength / 180;
		//for (i = 1; i < numActive; i += 2)
		//{
		//p = particles[i];
		//if (velocityLength < 50)
		//{
		//p.alpha -= 0.5;
		//}
		//else if (p.x > -5)
		//{
		////p.x += player.engineLocation.x * 2 - 5;
		//if (speedR < 2)
		//{
		//if (velocityLength < 20)
		//{
		//p.alpha = 0;
		//}
		//else
		//{
		//p.velocityY += Math.abs(speedR) / 5;
		//}
		//}
		//else
		//{
		//p.tangentialAcceleration = -body.angularVel * 25;
		//p.velocityY += speedR;
		//}
		//}
		//}
		//}
	
	}

}