package spaceshiptHunt.entities
{
	import nape.geom.Vec2;
	import spaceshiptHunt.entities.Enemy;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class EnemyPathBlocker extends Enemy
	{
		protected var attackRange:Number = 300.0;
		
		public function EnemyPathBlocker(position:Vec2)
		{
			super(position);
			weaponsPlacement["fireCannon"] = Vec2.get(16, -37);
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			this.gunType = "fireCannon";
		}
		
		override protected function decideNextAction():void
		{
			super.decideNextAction();
			if (body.space.timeStamp - pathCheckTime > pathUpdateInterval)
			{
				currentAction = goToPlayerPath;
			}
		}
		
		protected function attackPlayer():void
		{
			if (canViewPlayer && Vec2.dsq(Player.current.body.position, body.position) < attackRange * attackRange)
			{
				startShooting();
			}
			else
			{
				stopShooting();
				currentAction = decideNextAction;
			}
		
		}
		
		protected function aimToPlayer():void
		{
			currentAction = attackPlayer;
		}
		
		protected function goToPlayerPath():void
		{
			if (canViewPlayer && Vec2.dsq(Player.current.body.position, body.position) < attackRange * attackRange)
			{
				currentAction = aimToPlayer;
			}
			else
			{
				var playerPredictedPath:Vector.<Number> = PreyEnemy.current.playerPredictedPath;
				if (playerPredictedPath.length > 0)
				{
					var closestPoint:Vec2 = closestPointFromPath(playerPredictedPath);
					if (!(closestPoint.x == 0 && closestPoint.y == 0))
					{
						goTo(closestPoint.x, closestPoint.y);
					}
					else
					{
						currentAction = decideNextAction;
					}
					closestPoint.dispose();
				}
			}
		}
		
		protected function closestPointFromPath(path:Vector.<Number>):Vec2
		{
			var distanceToClosestPoint:Number = Number.MAX_VALUE;
			var i:int = 0;
			var lineStart:Vec2 = Vec2.get(path[i], path[++i]);
			var closestPoint:Vec2 = Vec2.get();
			var safeDistance:Number = pathfindingAgentSafeDistance * 2 + pathfindingAgent.radiusSquared + Player.current.pathfindingAgent.radiusSquared;
			for (; i < path.length - 2; )
			{
				var lineEnd:Vec2 = Vec2.get(path[++i], path[++i]);
				if (distanceSquaredFromPlayer(lineEnd) > safeDistance)
				{
					if (distanceSquaredFromPlayer(lineStart) > safeDistance)
					{
						var closestPointFromLine:Vec2 = findClosestPoint(lineStart, lineEnd);
						var distanceToPoint:Number = Vec2.distance(closestPointFromLine, body.position);
						if (distanceToPoint < distanceToClosestPoint && distanceSquaredFromPlayer(closestPointFromLine) > safeDistance)
						{
							distanceToClosestPoint = distanceToPoint;
							closestPoint.set(closestPointFromLine);
						}
						closestPointFromLine.dispose();
					}
					else
					{
						var safePos:Vec2 = lineStart.sub(lineEnd);
						safePos.length = distanceSquaredFromPlayer(lineStart);
						safePos.addeq(lineStart);
						closestPoint.set(findClosestPoint(safePos, lineEnd, true));
						lineStart.dispose();
						lineEnd.dispose();
						return closestPoint;
					}
				}
				else if (distanceSquaredFromPlayer(lineStart) > safeDistance)
				{
					var safePoint:Vec2 = lineStart.sub(lineEnd);
					safePoint.length = distanceSquaredFromPlayer(lineEnd);
					safePoint = lineEnd.sub(safePoint);
					closestPoint.set(findClosestPoint(lineStart, safePoint, true));
					lineStart.dispose();
					lineEnd.dispose();
					return closestPoint;
				}
				lineStart.dispose();
				lineStart = lineEnd;
			}
			lineStart.dispose();
			return closestPoint;
		}
		
		protected function distanceSquaredFromPlayer(pos:Vec2):Number
		{
			if (Enemy.enemiesSeePlayerCounter > 0)
			{
				return Vec2.dsq(Player.current.body.position, pos);
			}
			else
			{
				return Math.min(Vec2.dsq(lastSeenPlayerPos, pos), Vec2.dsq(Player.current.body.position, pos));
			}
		}
		
		protected function findClosestPoint(lineStart:Vec2, lineEnd:Vec2, weak:Boolean = false):Vec2
		{
			var closestPoint:Vec2 = Vec2.get(0, 0, weak);
			var line:Vec2 = lineEnd.sub(lineStart);
			var length:Number = line.length;
			line.muleq(1 / length);
			var startToCircle:Vec2 = Vec2.get(pathfindingAgent.x + body.velocity.x - lineStart.x, pathfindingAgent.y + body.velocity.y - lineStart.y);
			var lineDotCircle:Number = startToCircle.dot(line);
			if (lineDotCircle < 0)
			{
				closestPoint.set(lineStart);
			}
			else if (lineDotCircle > length)
			{
				closestPoint.set(lineEnd);
			}
			else
			{
				closestPoint.set(lineStart.sub(line.muleq(lineDotCircle), true));
			}
			line.dispose();
			startToCircle.dispose();
			return closestPoint;
		}
	
	}

}