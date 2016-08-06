package spaceshiptHunt.entities
{
	import spaceshiptHunt.level.Environment;
	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import starling.utils.deg2rad;
	import spaceshiptHunt.entities.Enemy;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PreyEnemy extends Enemy
	{
		protected var _playerPredictedPath:Vector.<Number>;
		protected var playerPathCheckTime:int;
		
		public function PreyEnemy(position:Vec2)
		{
			super(position);
			playerPathCheckTime = 0;
			_playerPredictedPath = new Vector.<Number>();
		}
		
		public override function update():void
		{
			super.update();
			if (pointingArrow.visible != !canViewPlayer)
			{
				pointingArrow.visible = !canViewPlayer;
			}
			if (canViewPlayer)
			{
				if (graphics.alpha < 1)
				{
					graphics.alpha += 0.025;
				}
			}
			else if (graphics.alpha > 0.4)
			{
				graphics.alpha -= 0.005;
			}
			updateArrow();
			if (body.space.timeStamp - playerPathCheckTime > 48)
			{
				var behind:Vec2 = Player.current.body.position.sub(body.position);
				behind.length = _pathfindingAgent.radius + Player.current.pathfindingAgent.radius + 50;
				behind = Player.current.body.position.sub(behind);
				Player.current.findPathTo(_playerPredictedPath, behind.x, behind.y);
				behind.dispose();
				playerPathCheckTime = body.space.timeStamp;
			}
		}
		
		public function get playerPracticedPath():Vector.<Number>
		{
			return _playerPredictedPath;
		}
		
		protected override function decideNextAction():void
		{
			if (canViewPlayer)
			{
				hide();
			}
		}
		
		public function hide(rayAngle:Number = 0):void
		{
			rayPool.origin.x = Player.current.pathfindingAgent.x;
			rayPool.origin.y = Player.current.pathfindingAgent.y;
			rayPool.direction.setxy(pathfindingAgent.x - rayPool.origin.x, pathfindingAgent.y - rayPool.origin.y);
			if (rayAngle != 0)
			{
				rayPool.direction.rotate(rayAngle);
			}
			rayPool.maxDistance = Vec2.distance(Player.current.body.position, body.position) + 2000;
			body.space.rayMultiCast(rayPool, true, playerFilter, rayList);
			var rayEnter:RayResult;
			var rayExit:RayResult;
			var hidingSpot:Vec2;
			while (rayList.length >= 2 && nextPoint == -1)
			{
				rayList.shift().dispose();
				rayEnter = rayList.shift();
				if (rayList.length != 0)
				{
					rayExit = rayList.shift();
					if (rayExit.distance - rayEnter.distance > this.pathfindingAgent.radius)
					{
						hidingSpot = rayPool.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
						goTo(hidingSpot.x, hidingSpot.y);
						hidingSpot.dispose();
					}
					rayExit.dispose();
				}
				else
				{
					hidingSpot = rayPool.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
					goTo(hidingSpot.x, hidingSpot.y);
					hidingSpot.dispose();
				}
				rayEnter.dispose();
			}
			while (!rayList.empty())
				rayList.pop().dispose();
			if (nextPoint == -1)
			{
				if (rayAngle == 0)
				{
					hide(deg2rad(5));
					if (nextPoint == -1)
					{
						hide(deg2rad(-5));
					}
				}
				else if (Math.abs(rayAngle) < Math.PI)
				{
					hide(-(rayAngle + rayAngle / Math.abs(rayAngle) * deg2rad(15)));
				}
			}
			if (nextPoint == -1)
			{
				currentAction = null;
				if (body.space.timeStamp - pathCheckTime > 48)
				{
					Environment.current.meshNeedsUpdate = true;
					pathCheckTime = body.space.timeStamp;
				}
			}
			else
			{
				currentAction = followPath;
			}
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
	
		//end
	}
}