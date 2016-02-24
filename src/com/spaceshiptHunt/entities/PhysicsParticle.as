package com.spaceshiptHunt.entities
{
	import com.spaceshiptHunt.level.Environment;
	import nape.callbacks.CbType;
	import nape.geom.Vec2;
	import nape.phys.Material;
	import nape.shape.Circle;
	import starling.animation.IAnimatable;
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	import starling.utils.VectorUtil;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PhysicsParticle extends BodyInfo
	{
		
		internal static var ParticlePool:Vector.<PhysicsParticle> = new Vector.<PhysicsParticle>();
		protected static const poolGrowth:int = 10;
		protected var currentCall:IAnimatable;
		public static const INTERACTION_TYPE:CbType= new CbType(); 
		
		//	protected var 
		
		//	public static const fill:BlurFilter = new BlurFilter(2,2);
		
		public function PhysicsParticle(particleTexture:Texture, position:Vec2 = null)
		{
			super(position);
			body.isBullet = true;
			graphics = new Image(particleTexture);
			graphics.pivotX = graphics.width / 2;
			graphics.pivotY = graphics.height / 2;
			body.cbTypes.add(PhysicsParticle.INTERACTION_TYPE);
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
			var particleTexture:Texture = Environment.assetsLoader.getTexture(particleType)
			if (ParticlePool.length == 0)
			{
				var circleShape:Circle = new Circle(particleTexture.width/2);
				for (var i:int = 0; i < poolGrowth; i++)
				{
					ParticlePool.push(new PhysicsParticle(particleTexture));
					circleShape.filter.collisionMask = ~2;
					ParticlePool[i].body.shapes.add(circleShape.copy());
					ParticlePool[i].body.mass /= 3;
				}
			}
			var particle:PhysicsParticle=ParticlePool.pop();
			particle.body.position.set(position);
			particle.body.applyImpulse(impulse);
			particle.body.rotation = impulse.angle;
			particle.body.space = Environment.physicsSpace;
			BodyInfo.list[0].graphics.parent.addChild(particle.graphics);
			particle.updateGraphics();
			BodyInfo.list.push(particle);
			particle.currentCall = Starling.juggler.delayCall(particle.dispose, 5);
		}
		
		public function dispose():void
		{
			if (body.space) {
			Starling.juggler.remove(currentCall);
			graphics.removeFromParent();
			body.space = null;
			BodyInfo.list.removeAt(BodyInfo.list.indexOf(this));
			ParticlePool.push(this);
			}
		}
	
	}

}