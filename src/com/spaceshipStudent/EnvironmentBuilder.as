package com.spaceshipStudent
{
	import DDLS.data.DDLSObject;
	import flash.geom.Point;
	import nape.geom.GeomPoly;
	import nape.geom.GeomPolyList;
	import nape.geom.Vec2;
	import nape.geom.Winding;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.geom.Polygon;
	import starling.utils.Color;
	CONFIG::air
	{
		import nape.geom.MarchingSquares;
		import flash.display.BitmapData;
		import com.nape.BitmapDataIso;
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
		import com.spaceshipStudent.Level;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class EnvironmentBuilder extends Environment
	{
		private var mainDisplay:Sprite;
		private var obstacle:Vector.<starling.geom.Polygon>;
		private var obstacleBody:Vector.<Body>;
		private var obstacleDisplay:Vector.<Canvas>;
		private var verticesDisplay:Canvas;
		private var closeVertex:int = -1;
		private var currentPoly:starling.geom.Polygon;
		private var lastObstacleIndex:int = -1;
		private var navShape:Vector.<DDLSObject>;
		
		public function EnvironmentBuilder(mainSprite:Sprite)
		{
			mainDisplay = mainSprite;
			obstacleDisplay = new Vector.<Canvas>();
			obstacleBody = new Vector.<Body>();
			obstacle = new Vector.<starling.geom.Polygon>();
			navShape = new Vector.<DDLSObject>();
			verticesDisplay = new Canvas();
			mainDisplay.parent.addChild(verticesDisplay);
		}
		
		 CONFIG::air public static function imageToMesh(image:BitmapData):Vector.<Vector.<int>>
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
		
		CONFIG::air public function saveLevel(levelInfo:Level):void
		{
			var data:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
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
						data.push(new Vector.<int>(shape.worldVerts.length * 2, true));
						for (j = 0; j < shape.worldVerts.length; j++)
						{
							data[data.length - 1][j * 2] = shape.worldVerts.at(j).x;
							data[data.length - 1][j * 2 + 1] = shape.worldVerts.at(j).y
						}
					}
				}
			}
			if (data.length > 0)
			{
				EnvironmentBuilder.saveBody(levelInfo, data);
				saveBodyDev(levelInfo);
			}
		}
		
		CONFIG::air public function saveBodyDev(bodyInfo:Object):void
		{
			//development mesh
			var mesh:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(obstacle.length, true);
			for (var i:int = 0; i < obstacle.length; i++)
			{
				mesh[i] = new Vector.<Number>();
				obstacle[i].copyToVector(mesh[i]);
				for (var j:int = 0; j < mesh[i].length; j++)
				{
					mesh[i][j] = int(mesh[i][j] + obstacleDisplay[i].x);
					mesh[i][++j] = int(mesh[i][j] + obstacleDisplay[i].y);
				}
			}
			var projectLocation:String = "C:/files/programing/as3Projects/spaceship hunt/bin/devPhysicsBodies/";
			//mesh file
			var file:File = new File(projectLocation + bodyInfo.name + "/Mesh.json");
			//	var file:File = new File((new File("app:/"+BodyName + "Mesh.json")).nativePath);
			var data:String = "[[" + mesh.join("],[") + "]]";
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(data);
			fileStream.close();
		}
		
		CONFIG::air public static function saveBody(bodyInfo:Object, mesh:Vector.<Vector.<int>>):void
		{
			var projectLocation:String = "C:/files/programing/as3Projects/spaceship hunt/bin/physicsBodies/";
			//mesh file
			var file:File = new File(projectLocation + bodyInfo.name + "/Mesh.json");
			//	var file:File = new File((new File("app:/"+BodyName + "Mesh.json")).nativePath);
			var data:String = "[[" + mesh.join("],[") + "]]";
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(data);
			fileStream.close();
			//info file
			file = new File(projectLocation + bodyInfo.name + "/Info.json");
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeMultiByte(JSON.stringify(bodyInfo), "utf-8");
			fileStream.close();
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
					if (e.target is Image)
					{
						for (i = 0; i < obstacleBody.length; i++)
						{
							if (obstacleBody[i].contains(Vec2.fromPoint(touch.getLocation(mainDisplay))))
							{
								currentPoly = obstacle[i];
								break;
							}
						}
					}
					else
					{
						i = lastObstacleIndex;
					}
					if (e.ctrlKey || lastObstacleIndex == -1)
					{
						addShape();
					}
					if (closeVertex == -1 && !e.shiftKey && (lastObstacleIndex == i || i == obstacle.length))
					{
						var distanceToEdge:Number;
						var closestDistance:Number = 99999999999.0;
						var pressedEdge:Boolean = false;
						for (var x:int = 0; x < currentPoly.numVertices; x++)
						{
							distanceToEdge = Point.distance(currentPoly.getVertex(x), mouseLocation);
							if (distanceToEdge < closestDistance)
							{
								closestDistance = distanceToEdge;
								closeVertex = x;
								if (distanceToEdge < 30.0)
								{
									currentPoly.setVertex(closeVertex, mouseLocation.x, mouseLocation.y);
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
								closeVertex = currentPoly.numVertices - 1;
							}
							else
							{
								var closeToEdge:Point = Point.interpolate(currentPoly.getVertex(closeVertex), mouseLocation, 0.99999);
								if (!currentPoly.containsPoint(mouseLocation))
								{
									if (currentPoly.containsPoint(closeToEdge))
									{
										closeVertex = -1;
									}
								}
								else if (!currentPoly.containsPoint(closeToEdge))
								{
									closeVertex = -1;
								}
								if (closeVertex != -1)
								{
									addVertex(mouseLocation);
								}
							}
						}
					}
					else
					{
						if (i != obstacle.length && i != -1)
						{
							lastObstacleIndex = i;
						}
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
							drawVertices(Color.BLUE);
						}
						else
						{
							if (closeVertex != -1)
							{
								currentPoly.setVertex(closeVertex, mouseLocation.x, mouseLocation.y);
							}
						}
					}
					else
					{
						if (touch.phase == TouchPhase.ENDED)
						{
							closeVertex = -1;
						}
					}
				}
				if (touch.phase != TouchPhase.HOVER && !e.shiftKey)
				{
					updateCurrentPoly();
				}
			}
		}
		
		private function addVertex(location:Point):void
		{
			var closestDistance:Number = Point.distance(location, currentPoly.getVertex(closeVertex));
			currentPoly.addVertices(currentPoly.getVertex(currentPoly.numVertices - 1));
			var leftVertex:Point;
			for (var j:int = currentPoly.numVertices - 2; j > closeVertex; j--)
			{
				leftVertex = currentPoly.getVertex(j - 1);
				currentPoly.setVertex(j, leftVertex.x, leftVertex.y);
			}
			if (closeVertex != 0)
			{
				leftVertex = currentPoly.getVertex(closeVertex - 1);
			}
			else
			{
				leftVertex = currentPoly.getVertex(currentPoly.numVertices - 1)
			}
			var closePoint:Point = currentPoly.getVertex(closeVertex + 1);
			var nextVertex:Point = currentPoly.getVertex((closeVertex + 2) % currentPoly.numVertices);
			var point1:Point = Point.interpolate(leftVertex, closePoint, closestDistance / Point.distance(leftVertex, closePoint));
			var point2:Point = Point.interpolate(nextVertex, closePoint, closestDistance / Point.distance(nextVertex, closePoint));
			if (Point.distance(location, point1) > Point.distance(location, point2))
			{
				currentPoly.setVertex(++closeVertex, location.x, location.y);
			}
			else
			{
				currentPoly.setVertex(closeVertex, location.x, location.y);
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
						closeVertex = currentPoly.numVertices - closeVertex - 1;
					}
					obstacleBody[lastObstacleIndex].shapes.clear();
					var convex:GeomPolyList = shape.convexDecomposition();
					shape.dispose();
					while (!convex.empty())
					{
						obstacleBody[lastObstacleIndex].shapes.add(new nape.shape.Polygon(convex.pop()));
					}
					obstacleBody[lastObstacleIndex].translateShapes(Vec2.weak(obstacleDisplay[lastObstacleIndex].x, obstacleDisplay[lastObstacleIndex].y));
					var navPolygon:Vector.<Number> = new Vector.<Number>(currentPoly.numVertices * 4, true);
					currentPoly.copyToVector(navPolygon, 0, 2);
					for (var l:int = 2; l <= navPolygon.length - 6; l += 3)
					{
						navPolygon[l] = navPolygon[l + 2];
						navPolygon[++l] = navPolygon[l + 2];
					}
					navPolygon[navPolygon.length - 2] = navPolygon[0];
					navPolygon[navPolygon.length - 1] = navPolygon[1];
					navShape[lastObstacleIndex].coordinates = navPolygon;
					
					obstacleDisplay[lastObstacleIndex].clear();
					obstacleDisplay[lastObstacleIndex].drawPolygon(currentPoly);
					drawVertices(Color.BLUE);
				}
				else
				{
					//	obstacleDisplay[lastObstacleIndex].beginFill(Color.RED, 0.5);
					obstacleDisplay[lastObstacleIndex].drawPolygon(obstacle[lastObstacleIndex]);
					//	obstacleDisplay[lastObstacleIndex].endFill();
					drawVertices(Color.RED);
				}
			}
			else
			{
				drawVertices(Color.BLUE);
			}
		}
		
		override protected function addMesh(points:Array, body:Body, canvas:DisplayObject = null):void
		{
			if (canvas)
			{
				addShape(new starling.geom.Polygon(points));
				updateCurrentPoly();
			}
			else
			{
				super.addMesh(points, body);
			}
		}
		
		private function addShape(newPoly:starling.geom.Polygon = null):void
		{
			verticesDisplay.clear();
			if (newPoly)
			{
				obstacle.push(newPoly);
			}
			else
			{
				obstacle.push(new starling.geom.Polygon());
			}
			obstacleDisplay.push(new Canvas());
			obstacleBody.push(new Body(BodyType.KINEMATIC));
			navMesh.insertObject(navShape[navShape.push(new DDLSObject()) - 1]);
			lastObstacleIndex = obstacle.length - 1;
			currentPoly = obstacle[lastObstacleIndex];
			mainDisplay.addChild(obstacleDisplay[lastObstacleIndex]);
			obstacleBody[lastObstacleIndex].space = this.physicsSpace;
		}
	
	}
}