package com.spaceshipStudent
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import com.spaceshipStudent.BodyInfo;
	import com.spaceshipStudent.EnemyAI;
	import com.spaceshipStudent.Player;
	import com.spaceshipStudent.Spaceship;
	import DDLS.ai.DDLSPathFinder;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSObject;
	import DDLS.factories.DDLSRectMeshFactory;
	import de.flintfabrik.starling.display.FFParticleSystem;
	import de.flintfabrik.starling.display.FFParticleSystem.SystemOptions;
	import nape.geom.Vec2;
	import nape.geom.Vec2List;
	import nape.phys.Body;
	import nape.phys.BodyList;
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
		public var assetsLoader:AssetManager;
		public var navMesh:DDLSMesh;
		public var physicsSpace:Space;
		public static var pathfinder:DDLSPathFinder;
		public static var timeSinceUpdate:int;
		protected var onFinishLoading:Vector.<Function>;
		protected var navBody:DDLSObject;
		protected var _enemy:EnemyAI;
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
		}
		
		public function set enemy(value:EnemyAI):void
		{
			_enemy = value;
		}
		
		public function get enemy():EnemyAI
		{
			return _enemy;
		}
		
		public function set player(value:Player):void
		{
			_player = value;
		}
		
		public function updatePhysics():void
		{
			timeSinceUpdate++;
			physicsSpace.step(1 / 60);
			var bodies:BodyList = physicsSpace.liveBodies;
			for (var i:int = 0; i < bodies.length; i++)
			{
				var body:Body = bodies.at(i);
				var bodyInfo:BodyInfo = body.userData.info as BodyInfo;
				bodyInfo.updatePhysics();
				if (bodyInfo is EnemyAI)
				{
					var enemy:EnemyAI = bodyInfo as EnemyAI;
					if (timeSinceUpdate > 30 && enemy.nextPoint > 0 && enemy.pathIsBlocked())
					{
						navMesh.updateObjects();
						timeSinceUpdate = 0;
						pathfinder.findPath(enemy.path[enemy.path.length - 2], enemy.path.pop(), enemy.path);
						if (enemy.path.length > 0)
						{
							enemy.nextPoint = 1;
						}
						else
						{
							enemy.nextPoint = 0;
						}
					}
				}
			}
			if (timeSinceUpdate % 61 == 0)
			{
				_enemy.checkPlayerVisibility();
			}
			var length:int = BodyInfo.list.length;
			for (var j:int = 0; j < length; j++) 
			{
				BodyInfo.list[j].updateLogic();
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
						var bodyInfo:BodyInfo = (body.userData.info as BodyInfo);
						bodyInfo.init(assetsLoader,bodyDescription, bodyDisplay);
						if (bodyDescription.hasOwnProperty("engineLocation"))
						{
							var spcaeship:Spaceship = bodyInfo as Spaceship;
							addFireParticle(spcaeship);
							if (spcaeship == _player)
							{
							  navMesh.insertObject(spcaeship.entityAI.approximateObject);
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
	
	}

}