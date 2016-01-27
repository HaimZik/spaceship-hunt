package com.spaceshipStudent
{
	import de.flintfabrik.starling.display.FFParticleSystem.Particle;
	import flash.utils.Dictionary;
	import nape.geom.Vec2;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.utils.AssetManager;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Spaceship extends BodyInfo
	{
		public var maxAcceleration:Number;
		public var maxTurningAcceleration:Number;
		public var engineLocation:Vec2;
		protected var _canViewPlayer:Boolean = true;
		protected var _gunType:String;
		protected var weaponsPlacement:Dictionary;
		private var weaponLeft:Image;
		private var weaponRight:Image;
		
		public function Spaceship(position:Vec2)
		{
			super(position);
			weaponsPlacement = new Dictionary(true);
		}
		
		override public function init(assetsLoader:AssetManager, bodyDescription:Object, bodyDisplay:DisplayObject):void
		{
			super.init(assetsLoader, bodyDescription, bodyDisplay);
			engineLocation = Vec2.get(bodyDescription.engineLocation.x, bodyDescription.engineLocation.y);
			maxAcceleration = body.mass * 8;
			maxTurningAcceleration = body.mass * 5;
		}
		
		public function get canViewPlayer():Boolean
		{
			return _canViewPlayer;
		}
		
		public function set gunType(gunType:String):void
		{
			_gunType = gunType;
			var texture:Texture = assetsLoader.getTexture(gunType);
			if (weaponLeft)
			{
				weaponLeft.texture = texture;
				weaponLeft.readjustSize();
				weaponRight.texture = texture;
				weaponRight.readjustSize();
			}
			else
			{
				weaponLeft = new Image(texture);
				weaponRight = new Image(texture);
				(graphics as DisplayObjectContainer).addChildAt(weaponLeft, 0);
				(graphics as DisplayObjectContainer).addChildAt(weaponRight, 0);
			}
			var position:Vec2 = weaponsPlacement[gunType];
			weaponLeft.x = position.x;
			weaponLeft.y = position.y;
			weaponRight.x = -position.x - weaponRight.width;
			weaponRight.y = position.y;
		}
		
		public function get gunType():String
		{
			return _gunType;
		}
		
		public function jetParticlePositioning(particles:Vector.<Particle>, numActive:int):void
		{
			var p:Particle;
			var velocityLength:Number = body.velocity.length;
			var speedL:Number = velocityLength / 10 + body.angularVel * 10;
			for (var i:int = 0; i < numActive; i += 2)
			{
				p = particles[i];
				if (p.x > -5)
				{
					p.x -= engineLocation.x * 2 - 5;
					p.y -= 5;
					if (speedL < 35)
					{
						if (velocityLength < 20)
						{
							p.colorAlpha = 0;
						}
						else
						{
							p.velocityY += Math.abs(speedL);
						}
					}
					else
					{
						p.tangentialAcceleration = -body.angularVel * 30;
						p.velocityY += speedL;
					}
				}
				else
				{
					p.colorAlpha = 0;
				}
			}
			var speedR:Number = -body.angularVel * 1.3 + velocityLength / 180;
			for (i = 1; i < numActive; i += 2)
			{
				p = particles[i];
				if (velocityLength < 50)
				{
					p.colorAlpha -= 0.5;
				}
				else if (p.x > -5)
				{
					//p.x += player.engineLocation.x * 2 - 5;
					if (speedR < 2)
					{
						if (velocityLength < 20)
						{
							p.colorAlpha = 0;
						}
						else
						{
							p.velocityY += Math.abs(speedR) / 5;
						}
					}
					else
					{
						p.tangentialAcceleration = -body.angularVel * 25;
						p.velocityY += speedR;
					}
				}
			}
		}
	
	}

}