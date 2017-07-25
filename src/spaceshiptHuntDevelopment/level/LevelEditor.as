package spaceshiptHuntDevelopment.level
{
	import DDLS.data.DDLSObject;
	import DDLS.view.DDLSSimpleView;
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	import input.Key;
	import nape.geom.GeomPoly;
	import nape.geom.GeomPolyList;
	import nape.geom.Mat23;
	import nape.geom.Vec2;
	import nape.geom.Winding;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.util.ShapeDebug;
	import spaceshiptHunt.entities.BodyInfo;
	import spaceshiptHunt.entities.Entity;
	import spaceshiptHunt.level.Environment;
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.display.Stage;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.geom.Polygon;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Pool;
	CONFIG::air
	{
		import nape.geom.MarchingSquares;
		import flash.display.BitmapData;
		import nape.BitmapDataIso;
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class LevelEditor extends Environment
	{
		private var obstacle:Vector.<starling.geom.Polygon>;
		private var obstacleBody:Vector.<Body>;
		private var obstacleDisplay:Vector.<Canvas>;
		private var verticesDisplay:Canvas;
		private var closeVertexIndex:int = -1;
		private var currentPoly:starling.geom.Polygon;
		private var lastObstacleIndex:int = -1;
		private var navShape:Vector.<DDLSObject>;
		private var napeDebug:ShapeDebug;
		private var navMeshDebugView:DDLSSimpleView;
		private var lastViewCenter:Point = new Point(0, 0);
		private var displayNavMesh:Boolean = true;
		CONFIG::air
		{
			private var dragEx:DragAndDropArea;
		}
		
		public function LevelEditor(mainSprite:Sprite)
		{
			super(mainSprite);
			obstacleDisplay = new Vector.<Canvas>();
			obstacleBody = new Vector.<Body>();
			obstacle = new Vector.<starling.geom.Polygon>();
			navShape = new Vector.<DDLSObject>();
			verticesDisplay = new Canvas();
			var stage:Stage = Starling.current.stage;
			napeDebug = new ShapeDebug(stage.stageWidth, stage.stageHeight, 0x33333333);
			navMeshDebugView = new DDLSSimpleView();
			navMeshDebugView.surface.mouseEnabled = false;
			Starling.current.nativeOverlay.addChild(navMeshDebugView.surface);
			Key.addKeyUpListener(Keyboard.N, disableNavMeshView);
			//Starling.current.nativeOverlay.addChild(napeDebug.display);
			CONFIG::air
			{
				dragEx = new DragAndDropArea(0, 0, stage.stageWidth, stage.stageHeight, onFileDrop);
				Starling.current.nativeStage.addChild(dragEx);
			}
		}
		
		override public function updatePhysics(passedTime:Number):void
		{
			super.updatePhysics(passedTime);
			drawDebugGrp();
		}
		
		override public function enqueueLevel(levelName:String):void
		{
			super.enqueueLevel(levelName);
			commandQueue.push(function addCommand():void
			{
				mainDisplay.addChild(verticesDisplay);
				drawNavMesh();
			});
		}
		
		private static function meshToString(mesh:Vector.<Vector.<int>>):String
		{
			return "[[" + mesh.join("],[") + "]]";
		}
		
		private function drawDebugGrp():void
		{
			if (napeDebug)
			{
				napeDebug.clear();
				napeDebug.draw(Environment.current.physicsSpace);
				napeDebug.flush();
				napeDebug.transform = Mat23.fromMatrix(mainDisplay.transformationMatrix);
			}
			if (displayNavMesh)
			{
				navMeshDebugView.cleanPaths();
				navMeshDebugView.cleanEntities();
				var viewRadius:Number = Math.max(Starling.current.viewPort.width, Starling.current.viewPort.height) / 2;
				var viewCenter:Point = Pool.getPoint(viewRadius, viewRadius);
				viewCenter = (navMeshDebugView.surface.globalToLocal(viewCenter));
				if (Starling.juggler.elapsedTime - lastNavMeshUpdate == 0 || navMeshDebugView.isMeshEndVisable(Environment.current.navMesh, viewCenter.x, viewCenter.y, viewRadius) || Point.distance(viewCenter, lastViewCenter) > viewRadius / 2.1)
				{
					lastViewCenter.x = viewCenter.x;
					lastViewCenter.y = viewCenter.y;
					navMeshDebugView.cleanMesh();
					navMeshDebugView.surface.transform.matrix = mainDisplay.transformationMatrix;
					navMeshDebugView.drawMesh(Environment.current.navMesh, false, viewCenter.x, viewCenter.y, viewRadius);
				}
				else
				{
					navMeshDebugView.surface.transform.matrix = mainDisplay.transformationMatrix;
				}
				Pool.putPoint(viewCenter);
				for (var i:int = 0; i < BodyInfo.list.length; i++)
				{
					if (BodyInfo.list[i] is Entity)
					{
						(BodyInfo.list[i] as Entity).drawDebug(navMeshDebugView);
					}
				}
			}
		}
		
		protected function disableNavMeshView():void
		{
			if (displayNavMesh)
			{
				navMeshDebugView.cleanPaths();
				navMeshDebugView.cleanEntities();
				navMeshDebugView.cleanMesh();
			}
			else
			{
				drawNavMesh();
			}
			displayNavMesh = !displayNavMesh;
		}
		
		CONFIG::air public function saveFile(path:String, data:String, rootFile:String = null):void
		{
			var file:File;
			if (rootFile)
			{
				file = new File(rootFile + path);
			}
			else
			{
				file = new File(File.applicationDirectory.resolvePath(path).nativePath);
			}
			var fileStream:FileStream = new FileStream();
			fileStream.addEventListener(Event.CLOSE, function fileSaved(e:Event):void
			{
				trace("done saving:" + path);
				fileStream.removeEventListener(Event.CLOSE, arguments.callee);
			});
			fileStream.openAsync(file, FileMode.WRITE);
			fileStream.writeUTFBytes(data);
			fileStream.close();
		}
		
		CONFIG::air public function saveLevel():void
		{
			saveAsteroidField({type: "Static", textureName: "concrete_baked"});
			var levelData:Object = new Object();
			var infoFileName:String;
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				infoFileName = BodyInfo.list[i].infoFileName;
				if (infoFileName)
				{
					if (!levelData[infoFileName])
					{
						levelData[infoFileName] = new Object();
						levelData[infoFileName].cordsX = new Vector.<int>();
						levelData[infoFileName].cordsY = new Vector.<int>();
					}
					var typeArray:Object = levelData[infoFileName];
					(typeArray.cordsX as Vector.<int>).push(BodyInfo.list[i].body.position.x);
					(typeArray.cordsY as Vector.<int>).push(BodyInfo.list[i].body.position.y);
				}
			}
			levelData["levelSpecific/" + currentLevel + "/static/asteroidField"] = new Object();
			saveFile(File.applicationDirectory.resolvePath("").nativePath + "/../src/spaceshiptHunt/level/" + currentLevel + ".json", JSON.stringify(levelData), "");
		}
		
		CONFIG::air public function saveAsteroidField(bodyInfo:Object):void
		{
			var meshData:String = meshToString(getMeshData());
			if (meshData.length > 7)
			{
				saveFile("physicsBodies/levelSpecific/" + currentLevel + "/static/asteroidField/Mesh.json", meshData);
				var meshDevData:String = "[[" + getDevMesh().join("],[") + "]]";
				saveFile("devPhysicsBodies/levelSpecific/" + currentLevel + "/static/asteroidField/Mesh.json", meshDevData);
				saveFile("physicsBodies/levelSpecific/" + currentLevel + "/static/asteroidField/Info.json", JSON.stringify(bodyInfo));
			}
		}
		
		public function handleTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(mainDisplay.parent);
			if (touch)
			{
				var mouseLocation:Point = touch.getLocation(mainDisplay);
				if (lastObstacleIndex != -1 && !e.ctrlKey)
				{
					mouseLocation.offset(-obstacleDisplay[lastObstacleIndex].x, -obstacleDisplay[lastObstacleIndex].y);
				}
				if (touch.phase == TouchPhase.BEGAN)
				{
					var i:int = -1;
					for (i = 0; i < obstacleBody.length; i++)
					{
						if (obstacleBody[i].contains(Vec2.fromPoint(touch.getLocation(mainDisplay))))
						{
							currentPoly = obstacle[i];
							break;
						}
					}
					if (e.ctrlKey || lastObstacleIndex == -1)
					{
						addMesh([mouseLocation.x, mouseLocation.y], new Body(BodyType.KINEMATIC));
					}
					if (closeVertexIndex == -1 && !e.shiftKey && (lastObstacleIndex == i || i == obstacle.length))
					{
						var distanceToEdge:Number;
						var closestDistance:Number = Number.MAX_VALUE;
						var pressedEdge:Boolean = false;
						for (var x:int = 0; x < currentPoly.numVertices; x++)
						{
							distanceToEdge = Point.distance(currentPoly.getVertex(x), mouseLocation);
							if (distanceToEdge < closestDistance)
							{
								closestDistance = distanceToEdge;
								closeVertexIndex = x;
								if (distanceToEdge < 30.0)
								{
									var preVertex:Point = currentPoly.getVertex(closeVertexIndex, Pool.getPoint());
									currentPoly.setVertex(closeVertexIndex, mouseLocation.x, mouseLocation.y);
									if (!currentPoly.isSimple)
									{
										currentPoly.setVertex(closeVertexIndex, preVertex.x, preVertex.y);
									}
									Pool.putPoint(preVertex);
									pressedEdge = true;
									break;
								}
							}
						}
						if (!pressedEdge)
						{
							if (currentPoly.numVertices < 3)
							{
								currentPoly.addVertices(mouseLocation);
								closeVertexIndex = currentPoly.numVertices - 1;
							}
							else
							{
								var closeToEdge:Point = Point.interpolate(currentPoly.getVertex(closeVertexIndex), mouseLocation, 0.99999);
								if (!currentPoly.containsPoint(mouseLocation))
								{
									if (currentPoly.containsPoint(closeToEdge))
									{
										closeVertexIndex = -1;
									}
								}
								else if (!currentPoly.containsPoint(closeToEdge))
								{
									closeVertexIndex = -1;
								}
								if (closeVertexIndex != -1)
								{
									addVertex(mouseLocation);
								}
							}
						}
					}
					else if (i != obstacle.length && i != -1 && currentPoly.numVertices > 2)
					{
						lastObstacleIndex = i;
					}
				}
				else
				{
					if (touch.phase == TouchPhase.MOVED && lastObstacleIndex != -1)
					{
						if (e.shiftKey)
						{
							var mouseMovement:Point = touch.getMovement(obstacleDisplay[lastObstacleIndex]);
							obstacleDisplay[lastObstacleIndex].x += mouseMovement.x;
							obstacleDisplay[lastObstacleIndex].y += mouseMovement.y;
							obstacleBody[lastObstacleIndex].translateShapes(Vec2.fromPoint(mouseMovement));
							navShape[lastObstacleIndex].x += mouseMovement.x;
							navShape[lastObstacleIndex].y += mouseMovement.y;
							Environment.current.meshNeedsUpdate = true;
							drawVertices(Color.BLUE);
						}
						else if (closeVertexIndex != -1)
						{
							//	var previousVertex:Point = currentPoly.getVertex(closeVertexIndex, Pool.getPoint());
							currentPoly.setVertex(closeVertexIndex, mouseLocation.x, mouseLocation.y);
								//if (!currentPoly.isSimple)
								//{
								//currentPoly.setVertex(closeVertexIndex, previousVertex.x, previousVertex.y);
								//}
								//	Pool.putPoint(previousVertex);
						}
					}
					else if (touch.phase == TouchPhase.ENDED)
					{
						closeVertexIndex = -1;
					}
				}
				if (touch.phase != TouchPhase.HOVER && !e.shiftKey)
				{
					updateCurrentPoly();
				}
			}
		}
		
		override protected function drawMesh(canvas:DisplayObjectContainer, vertices:starling.geom.Polygon, texture:Texture, normalMap:Texture = null):void
		{
			updateCurrentPoly();
		}
		
		override protected function addMesh(vertices:Array, body:Body):void
		{
			if (body.isDynamic())
			{
				super.addMesh(vertices, body);
			}
			else
			{
				verticesDisplay.clear();
				currentPoly = new starling.geom.Polygon(vertices);
				lastObstacleIndex = obstacle.push(currentPoly) - 1;
				obstacleDisplay.push(new Canvas());
				obstacleBody.push(new Body(BodyType.KINEMATIC));
				navMesh.insertObject(navShape[navShape.push(new DDLSObject()) - 1]);
				asteroidField.addChild(obstacleDisplay[lastObstacleIndex]);
				obstacleBody[lastObstacleIndex].space = physicsSpace;
			}
		}
		
		protected function drawNavMesh():void
		{
			var viewRadius:Number = Math.max(Starling.current.viewPort.width, Starling.current.viewPort.height) / 2;
			var viewCenter:Point = Pool.getPoint(viewRadius, viewRadius);
			viewCenter = (navMeshDebugView.surface.globalToLocal(viewCenter));
			navMeshDebugView.drawMesh(Environment.current.navMesh, true, viewCenter.x, viewCenter.y, viewRadius);
			lastViewCenter.x = viewCenter.x;
			lastViewCenter.y = viewCenter.y;
			Pool.putPoint(viewCenter);
		}
		
		private function getDevMesh():Vector.<Vector.<Number>>
		{
			var mesh:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(obstacle.length, true);
			for (var i:int = 0; i < obstacle.length; i++)
			{
				mesh[i] = new Vector.<Number>();
				polyToVector(obstacle[i], mesh[i], 0);
				for (var j:int = 0; j < mesh[i].length; j++)
				{
					mesh[i][j] = int(mesh[i][j] + obstacleDisplay[i].x);
					mesh[i][++j] = int(mesh[i][j] + obstacleDisplay[i].y);
				}
			}
			return mesh;
		}
		
		private function getMeshData():Vector.<Vector.<int>>
		{
			var meshData:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			var i:int = 0;
			var k:int = 0;
			var j:int = 0;
			var shape:nape.shape.Polygon;
			var bodies:BodyList = physicsSpace.bodies;
			for (i = 0; i < bodies.length; i++)
			{
				if (bodies.at(i).type != BodyType.DYNAMIC)
				{
					for (k = bodies.at(i).shapes.length - 1; k >= 0; k--)
					{
						shape = bodies.at(i).shapes.at(k).castPolygon;
						meshData.push(new Vector.<int>(shape.worldVerts.length * 2, true));
						for (j = 0; j < shape.worldVerts.length; j++)
						{
							meshData[meshData.length - 1][j * 2] = shape.worldVerts.at(j).x;
							meshData[meshData.length - 1][j * 2 + 1] = shape.worldVerts.at(j).y
						}
					}
				}
			}
			return meshData;
		}
		
		private function addVertex(location:Point):void
		{
			var closestDistance:Number = Point.distance(location, currentPoly.getVertex(closeVertexIndex));
			currentPoly.addVertices(currentPoly.getVertex(currentPoly.numVertices - 1));
			var leftVertex:Point;
			for (var j:int = currentPoly.numVertices - 2; j > closeVertexIndex; j--)
			{
				leftVertex = currentPoly.getVertex(j - 1);
				currentPoly.setVertex(j, leftVertex.x, leftVertex.y);
			}
			if (closeVertexIndex != 0)
			{
				leftVertex = currentPoly.getVertex(closeVertexIndex - 1);
			}
			else
			{
				leftVertex = currentPoly.getVertex(currentPoly.numVertices - 1)
			}
			var closePoint:Point = currentPoly.getVertex(closeVertexIndex + 1);
			var nextVertex:Point = currentPoly.getVertex((closeVertexIndex + 2) % currentPoly.numVertices);
			var point1:Point = Point.interpolate(leftVertex, closePoint, closestDistance / Point.distance(leftVertex, closePoint));
			var point2:Point = Point.interpolate(nextVertex, closePoint, closestDistance / Point.distance(nextVertex, closePoint));
			if (Point.distance(location, point1) > Point.distance(location, point2))
			{
				currentPoly.setVertex(++closeVertexIndex, location.x, location.y);
			}
			else
			{
				currentPoly.setVertex(closeVertexIndex, location.x, location.y);
			}
		}
		
		private function drawVertices(color:uint):void
		{
			verticesDisplay.x = obstacleDisplay[lastObstacleIndex].x;
			verticesDisplay.y = obstacleDisplay[lastObstacleIndex].y;
			verticesDisplay.clear();
			verticesDisplay.beginFill(color, 0.5);
			var edge:Point;
			for (var j:int = 0; j < currentPoly.numVertices; j++)
			{
				edge = currentPoly.getVertex(j);
				verticesDisplay.drawCircle(edge.x, edge.y, 30);
			}
			verticesDisplay.endFill();
		}
		
		private function updateCurrentPoly():void
		{
			if (currentPoly.numVertices > 2)
			{
				var shape:GeomPoly = GeomPoly.get();
				for (var i:int = 0; i < currentPoly.numVertices; i++)
				{
					shape.push(Vec2.fromPoint(currentPoly.getVertex(i)));
				}
				if (shape.isSimple())
				{
					if (shape.winding() == Winding.ANTICLOCKWISE)
					{
						currentPoly.reverse();
						closeVertexIndex = currentPoly.numVertices - closeVertexIndex - 1;
					}
					obstacleBody[lastObstacleIndex].shapes.clear();
					var convex:GeomPolyList = shape.convexDecomposition();
					while (!convex.empty())
					{
						obstacleBody[lastObstacleIndex].shapes.add(new nape.shape.Polygon(convex.pop()));
					}
					obstacleBody[lastObstacleIndex].translateShapes(Vec2.weak(obstacleDisplay[lastObstacleIndex].x, obstacleDisplay[lastObstacleIndex].y));
					var navMeshCords:Vector.<Number> = new Vector.<Number>(currentPoly.numVertices * 4, true);
					polyToVector(currentPoly, navMeshCords);
					for (var l:int = 2; l <= navMeshCords.length - 6; l += 3)
					{
						navMeshCords[l] = navMeshCords[l + 2];
						navMeshCords[++l] = navMeshCords[l + 2];
					}
					navMeshCords[navMeshCords.length - 2] = navMeshCords[0];
					navMeshCords[navMeshCords.length - 1] = navMeshCords[1];
					navShape[lastObstacleIndex].coordinates = navMeshCords;
					obstacleDisplay[lastObstacleIndex].clear();
					super.drawMesh(obstacleDisplay[lastObstacleIndex], currentPoly, assetsLoader.getTexture("concrete_baked"), assetsLoader.getTexture("concrete_baked_n"));
					drawVertices(Color.BLUE);
					Environment.current.meshNeedsUpdate = true;
				}
				else
				{
					obstacleDisplay[lastObstacleIndex].clear();
					obstacleDisplay[lastObstacleIndex].beginFill(Color.RED, 0.5);
					obstacleDisplay[lastObstacleIndex].drawPolygon(obstacle[lastObstacleIndex]);
					obstacleDisplay[lastObstacleIndex].endFill();
					drawVertices(Color.RED);
				}
				shape.dispose();
			}
			else
			{
				drawVertices(Color.OLIVE);
			}
		}
		
		private function polyToVector(polygon:starling.geom.Polygon, array:Vector.<Number>, stride:int = 2):void
		{
			var numVertices:int = polygon.numVertices;
			var vertex:Point = Pool.getPoint();
			for (var i:int = 0; i < numVertices; i++)
			{
				vertex = polygon.getVertex(i, vertex);
				array[i * 2 + i * stride] = vertex.x;
				array[i * 2 + 1 + i * stride] = vertex.y;
			}
			Pool.putPoint(vertex);
		}
		
		CONFIG::air
		{
			public static function imageToMesh(image:BitmapData):Vector.<Vector.<int>>
			{
				var body:Body = new Body();
				var imageIso:BitmapDataIso = new BitmapDataIso(image);
				var polys:GeomPolyList = MarchingSquares.run(imageIso, imageIso.bounds, new Vec2(4, 4), 2);
				var data:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
				for (var i:int = 0; i < polys.length; i++)
				{
					var list:GeomPolyList = polys.at(i).simplify(3).convexDecomposition();
					var shape:nape.shape.Polygon;
					while (!list.empty())
					{
						shape = new nape.shape.Polygon(list.pop());
						//if (physicsSpace)
						//{
						//body.shapes.add(shape);
						//}
						data.push(new Vector.<int>(shape.localVerts.length * 2, true));
						for (var j:int = 0; j < shape.localVerts.length; j++)
						{
							data[data.length - 1][j * 2] = shape.localVerts.at(j).x - image.width / 2
							data[data.length - 1][j * 2 + 1] = shape.localVerts.at(j).y - image.height / 2;
						}
					}
				}
				return data;
			}
			
			private function dropJSON(x:Number, y:Number, file:File):void
			{
				var fs:FileStream = new FileStream();
				fs.open(file, FileMode.READ);
				var data:String = fs.readUTFBytes(fs.bytesAvailable);
				trace(data);
				fs.close();
			}
			
			private function dropImage(x:Number, y:Number, file:File):void
			{
				var loader:Loader = new Loader();
				var urlReq:URLRequest = new URLRequest(file.url);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					var bmp:Bitmap = e.target.content as Bitmap;
					var data:BitmapData = bmp.bitmapData;
					var name:String = file.name.slice(0, file.name.indexOf("."));
					saveFile("physicsBodies/" + name + "/Mesh.json", meshToString(imageToMesh(data)));
					data.dispose();
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);
				});
				loader.load(urlReq);
			}
			
			private function onFileDrop(x:Number, y:Number, file:File):void
			{
				if (file.type == ".json")
				{
					dropJSON(x, y, file);
				}
				else
				{
					dropImage(x, y, file);
				}
			}
		
		}
	}
}