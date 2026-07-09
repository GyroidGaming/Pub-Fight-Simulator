extends RigidBody3D

func flip_table():
	apply_impulse(Vector3(0, 3, -6), Vector3(1, 0, 0))
	apply_torque_impulse(Vector3(8, 0, 0))
