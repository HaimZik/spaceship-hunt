package com.spaceshiptHunt.entities
{
	import com.spaceshiptHunt.entities.BodyInfo;
	import com.spaceshiptHunt.level.Environment;
	import nape.dynamics.InteractionFilter;
	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.RayResultList;
	import nape.geom.Vec2;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.utils.deg2rad;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PreyEnemy extends Spaceship
	{
		public var path:Vector.<Number>;
		public var nextPoint:int = 0;
		public var canViewPlayer:Boolean = true;
		protected var rayPool:Ray;
		protected var rayList:RayResultList;
		protected static var rayFilter:InteractionFilter = new InteractionFilter(2, -1);
		private var pathCheckTime:int;
		protected var pointingArrow:Image;
		
		public function PreyEnemy(position:Vec2)
		{
			super(position);
			pathCheckTime = Starling.juggler.elapsedTime;
			path = new Vector.<Number>();
			rayList = new RayResultList();
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			for (var i:int = 0; i < body.shapes.length; i++)
			{
				body.shapes.at(i).filter.collisionMask = ~2;
			}
			rayPool = Ray.fromSegment(this.body.position, Player.current.body.position);
			pointingArrow = new Image(Environment.current.assetsLoader.getTexture("arrow"));
			var mainDisplay:Sprite = Environment.current.mainDisplay;
			mainDisplay.addChildAt(pointingArrow, mainDisplay.getChildIndex(graphics) - 1);
		}
		
		public function followPath():void
		{
			if (nextPoint != 0 && path.length > 0)
			{
				var nextPointPos:Vec2 = Vec2.get(path[nextPoint * 2], path[nextPoint * 2 + 1]);
				while (Vec2.distance(body.position, nextPointPos) < 40)
				{
					nextPoint++;
					if (nextPoint < path.length / 2)
					{
						nextPointPos.x = path[nextPoint * 2]
						nextPointPos.y = path[nextPoint * 2 + 1];
					}
					else
					{
						nextPoint = 0;
						break;
					}
				}
				if (nextPoint != 0 && nextPoint < path.length / 2)
				{
					var prePath:Vec2 = nextPointPos.sub(Vec2.weak(path[nextPoint * 2 - 2], path[nextPoint * 2 - 1]), true);
					var rotaDiff:Number = prePath.angle + Math.PI / 2 - body.rotation;
					prePath.dispose();
					if (Math.abs(rotaDiff) > Math.PI / 2)
					{
						//in order for the ship to rotate in the shorter angle
						rotaDiff -= (Math.abs(rotaDiff) / rotaDiff) * Math.PI * 2;
					}
					body.applyAngularImpulse(body.mass * 300 * rotaDiff);
					nextPointPos.subeq(body.position);
					var maxSpeed:Number = 250;
					if (nextPoint == path.length / 2 - 1 && body.velocity.length > nextPointPos.length * 2)
					{
						if (!canViewPlayer)
						{
							body.applyImpulse(nextPointPos.mul(-2, true));
						}
						else
						{
							nextPoint = 0;
							hide();
						}
					}
					else
					{
						var impulseForce:Number = maxAcceleration * Math.sqrt(nextPointPos.length / 3.5 + 60) / 6;
						if (Environment.current.meshNeedsUpdate)
						{
							impulseForce /= 2;
						}
						nextPointPos.length = impulseForce;
						body.applyImpulse(nextPointPos);
					}
				}
				else
				{
					nextPoint = 0;
				}
				nextPointPos.dispose();
			}
			//else if (canViewPlayer)
			//{
			//hide();
			//}
		}
		
		private function isPlayerVisible():Boolean
		{
			rayPool.origin = this.body.position;
			rayPool.direction.setxy(Player.current.body.position.x - rayPool.origin.x, Player.current.body.position.y - rayPool.origin.y);
			rayPool.maxDistance = Vec2.distance(this.body.position, Player.current.body.position);
			if (rayPool.maxDistance > 1300)
			{
				return false;
			}
			PreyEnemy.rayFilter.collisionGroup = 2; //Filter player
			var rayResult:RayResult = body.space.rayCast(rayPool, false, PreyEnemy.rayFilter);
			if (rayResult.shape.body == Player.current.body)
			{
				rayResult.dispose();
				return true;
			}
			rayResult.dispose();
			return false;
		}
		
		private function updateArrow():void 
		{
			var distanceVec:Vec2 = Player.current.body.position.sub(body.position, true);
			distanceVec.length /= -10;
			if (distanceVec.length > 120)
			{
				pointingArrow.x = Player.current.graphics.x + distanceVec.x;
				pointingArrow.y = Player.current.graphics.y + distanceVec.y;
				pointingArrow.rotation = distanceVec.angle + Math.PI / 2;
				pointingArrow.visible = true;
			}
			else
			{
				pointingArrow.visible = false;
			}
			distanceVec.dispose();
		}
		
		public override function update():void
		{
			super.update();
			if (Starling.juggler.elapsedTime % 2 < 1)
			{
				canViewPlayer = isPlayerVisible();
				pointingArrow.visible = !canViewPlayer;
			}
			if (!Environment.current.meshNeedsUpdate)
			{
				if (Starling.juggler.elapsedTime - pathCheckTime > 0.8 && nextPoint > 0 && isPathBlocked())
				{
					Environment.current.meshNeedsUpdate = true;
					pathCheckTime = Starling.juggler.elapsedTime;
					Environment.current.pathfinder.findPath(path[path.length - 2], path.pop(), path);
					if (path.length > 0)
					{
						nextPoint = 1;
					}
					else
					{
						nextPoint = 0;
					}
				}
				if (canViewPlayer)
				{
					var distance:Number = Vec2.distance(body.position, Player.current.body.position);
					if (distance < pathfindingAgent.radius + pathfindingAgent.radius + 20)
					{
						body.applyImpulse(body.position.sub(Player.current.body.position, true).muleq(22000 / (distance * distance)).rotate(Math.PI / 4));
					}
					hide();
					if (graphics.alpha < 1)
					{
						graphics.alpha += 0.05;
					}
				}
				else if (graphics.alpha > 0.4)
				{
					graphics.alpha -= 0.005;
				}
			}
			followPath();
			updateArrow();
		}
		
		public function hide(angle:Number = 0):void
		{
			rayPool.origin.x = Player.current.pathfindingAgent.x;
			rayPool.origin.y = Player.current.pathfindingAgent.y;
			rayPool.direction.setxy(pathfindingAgent.x - rayPool.origin.x, pathfindingAgent.y - rayPool.origin.y);
			if (angle != 0)
			{
				rayPool.direction.rotate(angle);
			}
			rayPool.maxDistance = Vec2.distance(Player.current.body.position, body.position) + 2000;
			rayFilter.collisionGroup = 2; //Filter enemy and player
			body.space.rayMultiCast(rayPool, true, PreyEnemy.rayFilter, rayList);
			var rayEnter:RayResult;
			var rayExit:RayResult;
			var hidingSpot:Vec2;
			while (rayList.length >= 2 && nextPoint == 0)
			{
				rayList.shift().dispose();
				rayEnter = rayList.shift();
				if (rayList.length != 0)
				{
					rayExit = rayList.shift();
					if (rayExit.distance - rayEnter.distance > this.pathfindingAgent.radius)
					{
						hidingSpot = rayPool.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
						findPath(hidingSpot.x, hidingSpot.y);
						hidingSpot.dispose();
					}
					rayExit.dispose();
				}
				else
				{
					hidingSpot = rayPool.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
					findPath(hidingSpot.x, hidingSpot.y);
					hidingSpot.dispose();
				}
				rayEnter.dispose();
			}
			while (!rayList.empty())
				rayList.pop().dispose();
			if (nextPoint == 0)
			{
				if (angle == 0)
				{
					hide(deg2rad(5));
					if (nextPoint == 0)
					{
						hide(-5);
					}
				}
				else if (Math.abs(angle) < Math.PI)
				{
					hide(angle + angle / Math.abs(angle) * deg2rad(15));
				}
			}
		}
		
		public function findPath(x:Number, y:Number):void
		{
			Environment.current.pathfinder.entity = pathfindingAgent;
			Environment.current.pathfinder.findPath(x, y, path);
			if (path.length > 0)
			{
				nextPoint = 1;
				if (isPathBlocked())
				{
					nextPoint = 0;
					pathCheckTime = Starling.juggler.elapsedTime;
					Environment.current.meshNeedsUpdate = true;
				}
				if (body.isSleeping)
				{
					body.velocity.x += 0.001;
				}
			}
			else
			{
				nextPoint = 0;
			}
		}
		
		protected function entitiesIntersectsLine(startPoint:Vec2, endPoint:Vec2):Boolean
		{
			var line:Vec2 = endPoint.subeq(startPoint);
			var length:int = line.length;
			if (length == 0)
			{
				return false;
			}
			line.muleq(1 / length);
			var lineLeftNormal:Vec2 = Vec2.get(line.x, line.y).rotate(Math.PI * -0.5);
			var startToCircle:Vec2 = Vec2.get();
			var startDotNormal:Number;
			var lineDotCircle:Number;
			var entitiesNum:int = BodyInfo.list.length;
			for (var i:int = 0; i < entitiesNum; i++)
			{
				if (BodyInfo.list[i] is Entity)
				{
					var entity:Entity = BodyInfo.list[i] as Entity;
					if (entity.pathfindingAgent.approximateObject.hasChanged && entity != this && !(!canViewPlayer && entity is Player))
					{
						startToCircle.setxy(entity.pathfindingAgent.x + entity.body.velocity.x - startPoint.x, entity.pathfindingAgent.y + entity.body.velocity.y - startPoint.y);
						startDotNormal = Math.abs(startToCircle.dot(lineLeftNormal));
						lineDotCircle = startToCircle.dot(line);
						if (startDotNormal - pathfindingAgent.radius < entity.pathfindingAgent.radius && lineDotCircle > 0 && lineDotCircle < length)
						{
							lineLeftNormal.dispose();
							startToCircle.dispose();
							return true;
						}
					}
				}
			}
			lineLeftNormal.dispose();
			startToCircle.dispose();
			return false;
		}
		
		public function isPathBlocked():Boolean
		{
			var length:int = path.length / 2 - nextPoint;
			var lineStart:Vec2 = Vec2.get(pathfindingAgent.x, pathfindingAgent.y);
			lineStart.addeq(body.velocity);
			var lineEnd:Vec2 = Vec2.get(path[nextPoint * 2], path[nextPoint * 2 + 1]);
			var i:int = 0;
			while (i < length)
			{
				if (entitiesIntersectsLine(lineStart, lineEnd))
				{
					lineStart.dispose();
					lineEnd.dispose();
					return true
				}
				lineStart.setxy(path[(nextPoint + i) * 2 - 2], path[(nextPoint + i) * 2 - 1]);
				lineEnd.setxy(path[(nextPoint + i) * 2], path[(nextPoint + i) * 2 + 1]);
				i++;
			}
			lineStart.dispose();
			lineEnd.dispose();
			return false;
		}
	
		//end
	}
}