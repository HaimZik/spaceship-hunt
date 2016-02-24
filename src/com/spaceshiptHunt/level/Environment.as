package com.spaceshiptHunt.level
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import com.spaceshiptHunt.entities.BodyInfo;
	import com.spaceshiptHunt.entities.Entity;
	import com.spaceshiptHunt.entities.PhysicsParticle;
	import com.spaceshiptHunt.entities.Player;
	import com.spaceshiptHunt.entities.Spaceship;
	import DDLS.ai.DDLSPathFinder;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSObject;
	import DDLS.factories.DDLSRectMeshFactory;
	import de.flintfabrik.starling.display.FFParticleSystem;
	import de.flintfabrik.starling.display.FFParticleSystem.SystemOptions;
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.geom.Vec2;
	import nape.geom.Vec2List;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.geom.Polygon;
	import starling.utils.AssetManager;
	
	public class Environment
	{
		public static var assetsLoader:AssetManager;
		public static var navMesh:DDLSMesh;
		public static var physicsSpace:Space;
		public static var pathfinder:DDLSPathFinder;
		protected var onFinishLoading:Vector.<Function>;
		protected var navBody:DDLSObject;
		private var _player:Player;
		private var ParticleSysOptions:SystemOptions;
		[Embed(source = "JetFire.pex", mimeType = "application/octet-stream")]
		private static const JetFire:Class;
		
		public function Environment()
		{
			physicsSpace = new Space(new Vec2(0, 0));
			physicsSpace.worldAngularDrag = 3.0;
			physicsSpace.worldLinearDrag = 2;
			assetsLoader = new AssetManager();
			onFinishLoading = new Vector.<Function>();
			navMesh = DDLSRectMeshFactory.buildRectangle(10000, 10000);
			navBody = new DDLSObject();
			navMesh.insertObject(navBody);
			pathfinder = new DDLSPathFinder();
			pathfinder.mesh = navMesh;
			FFParticleSystem.init(1024, false, 512, 4);
			var bulletCollisionListener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbType.ANY_BODY, PhysicsParticle.INTERACTION_TYPE, onBulletHit);
			physicsSpace.listeners.add(bulletCollisionListener);
		}
		
		public function set player(value:Player):void
		{
			_player = value;
		}
		
		public function updatePhysics(passedTime:Number):void
		{
			physicsSpace.step(passedTime);
			var length:int = BodyInfo.list.length;
			var meshNeedsUpdate:Boolean = false;
			for (var j:int = 0; j < length; j++)
			{
				var bodyInfo:BodyInfo = BodyInfo.list[j];
				bodyInfo.update();
				if (bodyInfo.needsMeshUpdate)
				{
					meshNeedsUpdate = bodyInfo.needsMeshUpdate;
					bodyInfo.needsMeshUpdate = false;
				}
			}
			if (meshNeedsUpdate)
			{
				navMesh.updateObjects();
			}
		}
		
		public function enqueueBody(name:String, body:Body = null, bodyDisplay:DisplayObject = null):void
		{
			var infoFileName:String = assetsLoader.enqueueWithName("physicsBodies/" + name + "/Info.json", name + "Info");
			onFinishLoading.push(function onFinish():void
			{
				var bodyDescription:Object = assetsLoader.getObject(infoFileName);
				var i:int = 0;
				var meshFileName:String;
				if (bodyDescription.hasOwnProperty("children"))
				{
					meshFileName = assetsLoader.enqueueWithName("physicsBodies/" + name + "/Mesh.json", name + "Mesh");
				}
				else
				{
					CONFIG::debug
					{
						meshFileName = assetsLoader.enqueueWithName("devPhysicsBodies/" + name + "/Mesh.json", name + "Mesh");
					}
					CONFIG::release
					{
						meshFileName = assetsLoader.enqueueWithName("physicsBodies/" + name + "/Mesh.json", name + "Mesh");
					}
				}
				onFinishLoading.push(function onFinish():void
				{
					var polygonArray:Array = assetsLoader.getObject(meshFileName) as Array;
					if (bodyDescription.hasOwnProperty("children"))
					{
						for (i = 0; i < polygonArray.length; i++)
						{
							addMesh(polygonArray[i], body);
						}
						var bodyInfo:Entity = (body.userData.info as Entity);
						bodyInfo.init(bodyDescription, bodyDisplay);
						if (bodyDescription.hasOwnProperty("engineLocation"))
						{
							var spcaeship:Spaceship = bodyInfo as Spaceship;
							addFireParticle(spcaeship);
							if (spcaeship == _player)
							{
								navMesh.insertObject(spcaeship.pathfindingAgent.approximateObject);
							}
						}
					}
					else
					{
						//	bodyDisplay.touchable = false;
						//	var outline:Canvas = new Canvas();
						for (i = 0; i < polygonArray.length; i++)
						{
							addMesh(polygonArray[i], body, bodyDisplay);
						}
							//outline.filter = BlurFilter.createGlow(Color.SILVER,0.3);
							//bodyDisplay.parent.addChildAt(outline,0);
					}
					physicsSpace.bodies.add(body);
					assetsLoader.removeObject(meshFileName);
					assetsLoader.removeObject(infoFileName);
				})
			});
		}
		
		protected function addMesh(points:Array, body:Body, canvas:DisplayObject = null):void
		{
			var vec2List:Vec2List = new Vec2List();
			var i:int = 0;
			if (body.type == BodyType.STATIC)
			{
				navBody.coordinates.push(points[0], points[1]);
				vec2List.add(Vec2.weak(points[points.length - 2], points[points.length - 1]));
				i += 2;
				for (; i < points.length; i++)
				{
					navBody.coordinates.push(points[i], points[i + 1]);
					navBody.coordinates.push(points[i], points[i + 1]);
					vec2List.add(Vec2.weak(points[points.length - i - 2], points[points.length - i - 1]));
					i++;
				}
				navBody.coordinates.push(points[0], points[1]);
				navBody.hasChanged = true;
			}
			else
			{
				for (; i < points.length; i++)
				{
					vec2List.add(Vec2.weak(points[i], points[++i]));
				}
			}
			if (canvas)
			{
				var polygon:starling.geom.Polygon = new starling.geom.Polygon(points);
				(canvas as Canvas).drawPolygon(polygon);
			}
			body.shapes.add(new nape.shape.Polygon(vec2List));
			vec2List.clear();
			vec2List = null;
		}
		
		public function loadLevel(onFinish:Function):void
		{
			assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					var length:int = onFinishLoading.length;
					for (var i:int = 0; i < length; i++)
					{
						(onFinishLoading.shift())();
					}
					onFinish();
					navMesh.updateObjects();
				}
			})
		}
		
		protected function addFireParticle(bodyInfo:Spaceship):void
		{
			if (!ParticleSysOptions)
			{
				ParticleSysOptions = SystemOptions.fromXML(XML(new JetFire()), assetsLoader.getTexture("fireball"));
			}
			var ps:FFParticleSystem = new FFParticleSystem(ParticleSysOptions);
			ps.customFunction = bodyInfo.jetParticlePositioning;
			(bodyInfo.graphics as DisplayObjectContainer).addChild(ps);
			ps.start();
			ps.x = bodyInfo.engineLocation.x;
			ps.y = -bodyInfo.engineLocation.y;
		}
		
		private function onBulletHit(event:InteractionCallback):void
		{
			if (event.int1.userData.info is PhysicsParticle)
			{
				(event.int1.userData.info as PhysicsParticle).dispose();
			}
			if (event.int2.userData.info is PhysicsParticle)
			{
				(event.int2.userData.info as PhysicsParticle).dispose();
			}
		}
	
	}
}