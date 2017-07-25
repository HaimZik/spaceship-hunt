package spaceshiptHunt.entities
{
	import spaceshiptHunt.level.Environment;
	import nape.geom.Vec2;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Player extends Spaceship
	{
		public var leftImpulse:Vec2;
		public var rightImpulse:Vec2;
		private static var _current:Player=new Player(new Vec2());
		
		public function Player(position:Vec2)
		{
			//normally should be called by Player.current
			super(position);
			rightImpulse = Vec2.get(0, 0);
			leftImpulse = Vec2.get(0, 0);
			weaponsPlacement["fireCannon"] = Vec2.get(16, -37);
		}
		
		static public function get current():Player
		{
			return _current;
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			for (var i:int = 0; i < body.shapes.length; i++)
			{
				body.shapes.at(i).filter.collisionMask = ~4;
				body.shapes.at(i).filter.collisionGroup = 8;
			}
			this.gunType = "fireCannon";
			//Environment.current.navMesh.insertObject(pathfindingAgent.approximateObject);
		}
		
		override public function update():void
		{
			super.update();
			if (leftImpulse.length != 0)
			{
				var enginePositionL:Vec2 = engineLocation.copy(true).rotate(body.rotation).addeq(body.position);
				body.applyImpulse(leftImpulse.rotate(body.rotation), enginePositionL);
				leftImpulse.setxy(0, 0);
			}
			if (rightImpulse.length != 0)
			{
				var enginePositionR:Vec2 = engineLocation.copy(true);
				enginePositionR.x = -enginePositionR.x;
				enginePositionR.rotate(body.rotation).addeq(body.position);
				body.applyImpulse(rightImpulse.rotate(body.rotation), enginePositionR);
				rightImpulse.setxy(0, 0);
			}
			//if (body.velocity.length > 500)
			//{
				//body.velocity.length = 500;
			//}
		}
	
	}

}