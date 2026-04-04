extends MeshInstance3D

var width = 100
var depth = 100
var resolution = 50

func _ready():
	generate_terrain()

func generate_terrain():
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(resolution):
		for x in range(resolution):
			var x1 = float(x) / resolution * width - width/2
			var z1 = float(z) / resolution * depth - depth/2
			var x2 = float(x+1) / resolution * width - width/2
			var z2 = float(z+1) / resolution * depth - depth/2
			
			var y1 = get_height(x1, z1)
			var y2 = get_height(x2, z1)
			var y3 = get_height(x1, z2)
			var y4 = get_height(x2, z2)
			
			surface.add_vertex(Vector3(x1, y1, z1))
			surface.add_vertex(Vector3(x2, y2, z1))
			surface.add_vertex(Vector3(x1, y3, z2))
			
			surface.add_vertex(Vector3(x2, y2, z1))
			surface.add_vertex(Vector3(x2, y4, z2))
			surface.add_vertex(Vector3(x1, y3, z2))
	
	surface.generate_normals()
	mesh = surface.commit()
	
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	$StaticBody3D/CollisionShape3D.shape = shape

func get_height(x, z):
	return sin(x * 0.1) * 3 + cos(z * 0.1) * 3
