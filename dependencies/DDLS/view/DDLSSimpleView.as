package DDLS.view
{
	import DDLS.ai.DDLSEntityAI;
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSVertex;
	import DDLS.data.math.DDLSPoint2D;
	import DDLS.iterators.IteratorFromMeshToVertices;
	import DDLS.iterators.IteratorFromVertexToIncomingEdges;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	public class DDLSSimpleView
	{
		
		private var _edges:Sprite;
		private var _constraints:Sprite;
		private var _vertices:Sprite;
		private var _paths:Sprite;
		private var _entities:Sprite;
		
		private var _surface:Sprite;
		
		private var _showVerticesIndices:Boolean = false;
		
		public function DDLSSimpleView()
		{
			_edges = new Sprite();
			_constraints = new Sprite();
			_vertices = new Sprite();
			_paths = new Sprite();
			_entities = new Sprite();
			
			_surface = new Sprite();
			_surface.addChild(_edges);
			_surface.addChild(_constraints);
			_surface.addChild(_vertices);
			_surface.addChild(_paths);
			_surface.addChild(_entities);
		}
		
		public function get surface():Sprite
		{
			return _surface;
		}
		
		public function isMeshEndVisable(mesh:DDLSMesh, viewCenterX:Number, viewCenterY, viewRadius:Number):Boolean
		{
			return viewCenterX < viewRadius * 2 || viewCenterX > mesh.width - viewRadius * 2 || viewCenterY < viewRadius * 2 || viewCenterY > mesh.height - viewRadius * 2;
		}
		
		public function drawMesh(mesh:DDLSMesh, cleanBefore:Boolean = true, viewCenterX:Number = 0, viewCenterY = 0, viewRadius:Number = -1):void
		{
			if (cleanBefore)
			{
				cleanMesh();
			}
			while (_vertices.numChildren)
				_vertices.removeChildAt(0);
			if (viewRadius == -1 || isMeshEndVisable(mesh, viewCenterX, viewCenterY, viewRadius))
			{
				_surface.graphics.beginFill(0x00, 0);
				_surface.graphics.lineStyle(1, 0xFF0000, 1, false, LineScaleMode.NONE);
				_surface.graphics.drawRect(0, 0, mesh.width, mesh.height);
				_surface.graphics.endFill();
			}
			
			var vertex:DDLSVertex;
			var incomingEdge:DDLSEdge;
			var holdingFace:DDLSFace;
			
			var iterVertices:IteratorFromMeshToVertices;
			iterVertices = new IteratorFromMeshToVertices();
			iterVertices.fromMesh = mesh;
			var iterEdges:IteratorFromVertexToIncomingEdges;
			iterEdges = new IteratorFromVertexToIncomingEdges();
			var dictVerticesDone:Dictionary;
			dictVerticesDone = new Dictionary();
			while ((vertex = iterVertices.next()) != null)
			{
				dictVerticesDone[vertex] = true;
				if (!vertexIsInsideAABB(vertex, mesh))
					continue;
				
				//_vertices.graphics.lineStyle(0, 0);
				_vertices.graphics.beginFill(0x0000FF, 1);
				_vertices.graphics.drawCircle(vertex.pos.x, vertex.pos.y, 0.5);
				_vertices.graphics.endFill();
				
				if (_showVerticesIndices)
				{
					var tf:TextField = new TextField();
					tf.mouseEnabled = false;
					tf.text = String(vertex.id);
					tf.x = vertex.pos.x + 5;
					tf.y = vertex.pos.y + 5;
					tf.width = tf.height = 20;
					_vertices.addChild(tf);
				}
				
				iterEdges.fromVertex = vertex;
				incomingEdge = iterEdges.next();
				while (incomingEdge)
				{
					if (!dictVerticesDone[incomingEdge.originVertex])
					{
						if (viewRadius == -1 || isLineInView(incomingEdge.originVertex.pos,incomingEdge.destinationVertex.pos,viewCenterX,viewCenterY,viewRadius))
						{
							if (incomingEdge.isConstrained)
							{
								_constraints.graphics.lineStyle(2, 0xFF0000, 1, false, LineScaleMode.NONE);
								_constraints.graphics.moveTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y);
								_constraints.graphics.lineTo(incomingEdge.destinationVertex.pos.x, incomingEdge.destinationVertex.pos.y);
							}
							else
							{
								_edges.graphics.lineStyle(1, 0x999999, 1, false, LineScaleMode.NONE);
								_edges.graphics.moveTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y);
								_edges.graphics.lineTo(incomingEdge.destinationVertex.pos.x, incomingEdge.destinationVertex.pos.y);
							}
						}
					}
					incomingEdge = iterEdges.next();
				}
			}
		
		}
		
		public function cleanMesh():void
		{
			_surface.graphics.clear();
			_edges.graphics.clear();
			_constraints.graphics.clear();
			_vertices.graphics.clear();
		}
		
		public function drawEntity(entity:DDLSEntityAI, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				_entities.graphics.clear();
			
			_entities.graphics.lineStyle(1, 0x00FF00, 1, false, LineScaleMode.NONE);
			_entities.graphics.beginFill(0x00FF00, 0.5);
			_entities.graphics.drawCircle(entity.x, entity.y, entity.radius);
			_entities.graphics.endFill();
		}
		
		public function drawEntities(vEntities:Vector.<DDLSEntityAI>, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				_entities.graphics.clear();
			
			_entities.graphics.lineStyle(1, 0x00FF00, 0.5, false, LineScaleMode.NONE);
			for (var i:int = 0; i < vEntities.length; i++)
			{
				_entities.graphics.beginFill(0x00FF00, 1);
				_entities.graphics.drawCircle(vEntities[i].x, vEntities[i].y, vEntities[i].radius);
				_entities.graphics.endFill();
			}
		}
		
		public function cleanEntities():void
		{
			_entities.graphics.clear();
		}
		
		public function drawPath(path:Vector.<Number>, cleanBefore:Boolean = true, color:uint = 0xFF00FF):void
		{
			if (cleanBefore)
				_paths.graphics.clear();
			
			if (path.length == 0)
				return;
			
			_paths.graphics.lineStyle(1.5, color, 0.5, false, LineScaleMode.NONE);
			
			_paths.graphics.moveTo(path[0], path[1]);
			for (var i:int = 2; i < path.length; i += 2)
				_paths.graphics.lineTo(path[i], path[i + 1]);
		}
		
		public function cleanPaths():void
		{
			_paths.graphics.clear();
		}
		
		private function vertexIsInsideAABB(vertex:DDLSVertex, mesh:DDLSMesh):Boolean
		{
			if (vertex.pos.x < 0 || vertex.pos.x > mesh.width || vertex.pos.y < 0 || vertex.pos.y > mesh.height)
				return false;
			else
				return true;
		}
		
		private function isLineInView(lineStart:DDLSPoint2D,lineEnd:DDLSPoint2D,viewCenterX:Number,viewCenterY:Number,viewRadius:Number):Boolean
		{
			var viewRangeSquared:Number = Math.pow(viewRadius * 1.5, 2);
			var isStartVertexInView:Boolean = Math.pow(viewCenterX - lineStart.x, 2) < viewRangeSquared && Math.abs(viewCenterY - lineStart.y) < viewRangeSquared;
			var isEndVertexInView:Boolean=Math.pow(viewCenterX - lineEnd.x, 2) < viewRangeSquared && Math.abs(viewCenterY - lineEnd.y) < viewRangeSquared
			return isStartVertexInView || isEndVertexInView || lineStart.distanceTo(lineEnd)>viewRadius*2;
		}
	
	}
}