package com.spaceshiptHunt.entities
{
	import com.spaceshiptHunt.level.Environment;
	import nape.callbacks.CbType;
	import nape.geom.Vec2;
	import nape.shape.Circle;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.MovieClip;
	import starling.textures.Texture;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PhysicsParticle extends BodyInfo
	{
		
		internal static var ParticlePool:Vector.<PhysicsParticle> = new Vector.<PhysicsParticle>();
		protected static const poolGrowth:int = 10;
		protected var currentCallId:uint;
		public static const INTERACTION_TYPE:CbType= new CbType(); 
		
		//	protected var 
		
		//	public static const fill:BlurFilter = new BlurFilter(2,2);
		
		public function PhysicsParticle(particleTexture:Vector.<Texture>, position:Vec2 = null)
		{
			super(position);
			body.isBullet = true;
			graphics = new MovieClip(particleTexture);
			graphics.pivotX = graphics.width / 2;
			graphics.pivotY = graphics.height / 2;
			body.cbTypes.add(PhysicsParticle.INTERACTION_TYPE);
			body.allowRotation = false;
			//	graphics.filter = fill;
			//var material:Material = Material.ice().copy();
			//material.staticFriction = 0;
			//material.dynamicFriction = 0;
			//material.
			//trace(material.dynamicFriction);
			//body.setShapeMaterials(material);
		}
		
		public static function spawn(particleType:String, position:Vec2, impulse:Vec2):void
		{
			var particleTexture:Vector.<Texture> = Environment.current.assetsLoader.getTextures(particleType)
			if (ParticlePool.length == 0)
			{
				var circleShape:Circle = new Circle(particleTexture[0].width/2);
				for (var i:int = 0; i < poolGrowth; i++)
				{
					ParticlePool.push(new PhysicsParticle(particleTexture));
					circleShape.filter.collisionMask = ~2;//in order for the raytracing to ignore it
					ParticlePool[i].body.shapes.add(circleShape.copy());
					ParticlePool[i].body.mass /= 3;
				}
			}
			var particle:PhysicsParticle=ParticlePool.pop();
			particle.body.position.set(position);
			particle.body.applyImpulse(impulse);
			particle.body.rotation = impulse.angle;
			particle.body.space = Environment.current.physicsSpace;
			var otherBodyGrp:DisplayObject = BodyInfo.list[0].graphics;
			otherBodyGrp.parent.addChildAt(particle.graphics,otherBodyGrp.parent.getChildIndex(otherBodyGrp));
			particle.updateGraphics();
			BodyInfo.list.push(particle);
			particle.currentCallId = Starling.juggler.delayCall(particle.dispose, 5);
			Starling.juggler.add(particle.graphics as MovieClip);
			(particle.graphics as MovieClip).play();
		}
		
		public function dispose():void
		{
			if (body.space) {
			Starling.juggler.removeByID(currentCallId);
			graphics.removeFromParent();
			body.space = null;
			BodyInfo.list.removeAt(BodyInfo.list.indexOf(this));
			ParticlePool.push(this);
			}
		}
	
	}

}