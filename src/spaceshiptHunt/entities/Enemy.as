package spaceshiptHunt.entities
{
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.entities.Spaceship;
	import nape.dynamics.InteractionFilter;
	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.RayResultList;
	import nape.geom.Vec2;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Enemy extends Spaceship
	{
		
		public var path:Vector.<Number>;
		public var nextPoint:int = -1;
		public var canViewPlayer:Boolean = true;
		protected var rayPool:Ray;
		protected var rayList:RayResultList;

		protected static const PLAYER_FILTER:InteractionFilter = new InteractionFilter(2, -1);
		protected var pathCheckTime:int;
		protected var pointingArrow:Image;
		protected var currentAction:Function;
		
		public function Enemy(position:Vec2)
		{
			super(position);
			pathCheckTime = 0;
			path = new <Number>[];
			rayList = new RayResultList();
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
		
		public function goTo(x:Number, y:Number):void
		{
			findPathTo(path, x, y);
			if (path.length > 0)
			{
				nextPoint = 1;
				if (isPathBlocked())
				{
					nextPoint = -1;
					pathCheckTime = body.space.timeStamp;
					Environment.current.meshNeedsUpdate = true;
				}
				if (body.isSleeping)
				{
					body.velocity.x += 0.001;
				}
			}
			else
			{
				nextPoint = -1;
			}
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
			mainDisplay.addChildAt(pointingArrow,0);
		}
		
		protected function isPlayerVisible():Boolean
		{
			rayPool.origin = this.body.position;
			rayPool.direction.setxy(Player.current.body.position.x - rayPool.origin.x, Player.current.body.position.y - rayPool.origin.y);
			rayPool.maxDistance = Vec2.distance(this.body.position, Player.current.body.position);
			if (rayPool.maxDistance > 1300)
			{
				return false;
			}

			var rayResult:RayResult = body.space.rayCast(rayPool, false, PLAYER_FILTER);
			if (rayResult.shape.body == Player.current.body)
			{
				rayResult.dispose();
				return true;
			}
			rayResult.dispose();
			return false;
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
			var perpendicularLength:Number;
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
						perpendicularLength = Math.abs(startToCircle.dot(lineLeftNormal));
						lineDotCircle = startToCircle.dot(line);
						if (perpendicularLength - pathfindingAgent.radius < entity.pathfindingAgent.radius && lineDotCircle > 0 && lineDotCircle < length)
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
		
		protected function closestPointFromLine(startPoint:Vec2, endPoint:Vec2):Vec2
		{
			var line:Vec2 = endPoint.subeq(startPoint);
			var length:int = line.length;
			if (length == 0)
			{
				return Vec2.get();
			}
			line.muleq(1 / length);
			var startToCircle:Vec2 = Vec2.get(pathfindingAgent.x + body.velocity.x - startPoint.x, pathfindingAgent.y + body.velocity.y - startPoint.y);
			var lineDotCircle:Number = startToCircle.dot(line);
			if (lineDotCircle < 0)
			{
				startToCircle.dispose();
				return startPoint;
			}
			else if (lineDotCircle > length)
			{
				startToCircle.dispose();
				return endPoint;
			}
			else
			{
				var lineLeftNormal:Vec2 = Vec2.get(line.x, line.y).rotate(Math.PI * -0.5);
				var perpendicular:Number = startToCircle.dot(lineLeftNormal);
				lineLeftNormal.dispose();
				return startToCircle.addeq(Vec2.weak(0, perpendicular)).addeq(startPoint);
			}
		}
		
		override public function update():void
		{
			super.update();
			if (body.space.timeStamp % 61 == 0)
			{
				canViewPlayer = isPlayerVisible();
			}
			if (currentAction)
			{
				currentAction();
			}
			else
			{
				decideNextAction();
			}
		}
		
		protected function decideNextAction():void
		{
		}
		
		protected function followPath():void
		{
			if (nextPoint < path.length / 2)
			{
				var distance:Number = Vec2.distance(body.position, Player.current.body.position);
				if (distance < pathfindingAgent.radius + pathfindingAgent.radius + 20)
				{
					body.applyImpulse(body.position.sub(Player.current.body.position, true).muleq(22000 / (distance * distance)).rotate(Math.PI / 4));
				}
				var nextPointPos:Vec2 = Vec2.get(path[nextPoint * 2], path[nextPoint * 2 + 1]);
				while (Vec2.distance(body.position, nextPointPos) < 40 && ++nextPoint < path.length / 2)
				{
					nextPointPos.x = path[nextPoint * 2]
					nextPointPos.y = path[nextPoint * 2 + 1];
				}
				if (nextPoint < path.length / 2)
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
						nextPoint = -1;
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
						if (!Environment.current.meshNeedsUpdate && body.space.timeStamp - pathCheckTime > 48 && isPathBlocked())
						{
							Environment.current.meshNeedsUpdate = true;
							reFindPath();
						}
					}
				}
				else
				{
					nextPoint = -1;
				}
				nextPointPos.dispose();
			}
			else
			{
				nextPoint = -1;
			}
			if (nextPoint == -1)
			{
				currentAction = null;
			}
		}
		
		protected function reFindPath():void
		{
			pathCheckTime = body.space.timeStamp;
			findPathTo(path, path[path.length - 2], path.pop());
			if (path.length > 1)
			{
				nextPoint = 1;
			}
			else
			{
				nextPoint = -1;
			}
		}
	
		//end
	}

}