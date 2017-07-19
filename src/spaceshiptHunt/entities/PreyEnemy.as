package spaceshiptHunt.entities
{
	import DDLS.view.DDLSSimpleView;
	import spaceshiptHunt.level.Environment;
	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import starling.utils.Color;
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
		private static var _current:PreyEnemy;
		
		public function PreyEnemy(position:Vec2)
		{
			_current = this;
			super(position);
			playerPathCheckTime = -90;
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
				if (body.space.timeStamp - playerPathCheckTime > pathUpdateInterval)
				{
					Player.current.findPathToEntity(pathfindingAgent, _playerPredictedPath);
					playerPathCheckTime = body.space.timeStamp;
				}
			}
			else
			{
				if (graphics.alpha > 0.4)
				{
					graphics.alpha -= 0.005;
				}
				if (body.space.timeStamp - playerPathCheckTime > pathUpdateInterval)
				{
					var playerPosX:Number = Player.current.pathfindingAgent.x;
					var playerPosY:Number = Player.current.pathfindingAgent.y;
					Player.current.pathfindingAgent.x = lastSeenPlayerPos.x;
					Player.current.pathfindingAgent.y = lastSeenPlayerPos.y;
					Player.current.findPathToEntity(pathfindingAgent, _playerPredictedPath);
					Player.current.pathfindingAgent.x = playerPosX;
					Player.current.pathfindingAgent.y = playerPosY;
					playerPathCheckTime = body.space.timeStamp;
				}
			}
			updateArrow();
		}
		
		static public function get current():PreyEnemy
		{
			return _current;
		}
		
		static public function set current(value:PreyEnemy):void
		{
			_current = value;
		}
		
		public function get playerPredictedPath():Vector.<Number>
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
			body.space.rayMultiCast(rayPool, true, PLAYER_FILTER, rayList);
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
				else
				{
					if (nextPoint == -1)
					{
						Environment.current.meshNeedsUpdate = true;
					}
				}
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
		
		CONFIG::debug
		{
			import DDLS.view.DDLSSimpleView;
			
			override public function drawDebug(canvas:DDLSSimpleView):void
			{
				super.drawDebug(canvas);
					canvas.drawPath(playerPredictedPath, false, Color.BLUE);
			}
		}
	
		//end
	}
}