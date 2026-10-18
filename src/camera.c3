module opengl_test;

import std;
import std::gfx;
import std::math::matrix;
import std::math::vector;
import opengl::gl;
import spng;

struct Camera
{
	Mat4 view;
	Vec3 pos;
	Vec3 target;
	Vec3 direction;
	Vec3 front;
	Vec3 right;
	Vec3 up;
	float fov;
}

fn Camera create_camera()
{
	Camera cam;

	cam.pos = {0, 0, 3};
	cam.target = {0, 0, 0};
	cam.direction =  (cam.pos - cam.target).normalize();
	cam.front = {0, 0, -1};
	cam.right = {0, 1, 0}.cross(cam.direction).normalize();
	cam.up = cam.direction.cross(cam.right);
	cam.fov = (float)math::deg_to_rad(45);

	return cam;
}

float yaw = -120;
float pitch = 20;
float lastX =  900 / 2;
float lastY =  600 / 2;
bool firstMouse = true;
float cameraSpeed = 0.2;

fn void Camera.update(&self, GfxWindow* win)
{
	// KEYSS
	if (gfx::is_key_down(W, win) || gfx::is_key_down(UP, win)) self.pos += cameraSpeed * self.front;
	if (gfx::is_key_down(S, win) || gfx::is_key_down(DOWN, win)) self.pos -= cameraSpeed * self.front;
	if (gfx::is_key_down(A, win) || gfx::is_key_down(LEFT, win)) self.pos -= self.front.cross(self.up).normalize() * cameraSpeed;
	if (gfx::is_key_down(D, win) || gfx::is_key_down(RIGHT, win)) self.pos += self.front.cross(self.up).normalize() * cameraSpeed;

	// MOUSE
	GfxPoint mouse_pos = win.get_mouse();

	if (firstMouse)
	{
		lastX = mouse_pos.x;
		lastY = mouse_pos.y;
		firstMouse = false;
	}

	float xoffset = mouse_pos.x - lastX;
	float yoffset = lastY - mouse_pos.y; // reversed since y-coordinates go from bottom to top
	lastX = mouse_pos.x;
	lastY = mouse_pos.y;

	float sensitivity = 0.1f; // change this value to your liking
	xoffset *= sensitivity;
	yoffset *= sensitivity;

	yaw += xoffset;
	pitch += yoffset;

	if (pitch > 89.0f) pitch = 89.0f;
	if (pitch < -89.0f) pitch = -89.0f;

	Vec3 front = {
		-1 * math::sin(math::deg_to_rad(pitch)),
		math::cos(math::deg_to_rad(yaw)) * math::cos(math::deg_to_rad(pitch)),
		math::sin(math::deg_to_rad(yaw)) * math::cos(math::deg_to_rad(pitch))
	};

	self.front = front.normalize();

	// SCROLL
	Vec2 scroll = gfx::get_mouse_scroll() * 0.1;
	self.fov -= scroll.y;
	if (self.fov < 1) self.fov = 1;
	if (self.fov > 45) self.fov = 45;
}