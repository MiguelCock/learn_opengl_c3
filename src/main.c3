module opengl_test;

import std;
import std::gfx;
import opengl::gl;
import std::thread;

fn void main()
{
	GfxWindow* win = create_window();
	defer win.destoy_window();

	if (win == null) return;

	Shader base_shader = create_shader((GLchar**)&&BASE_VERT, (GLchar**)&&BASE_FRAG);
    defer base_shader.delete_shader();

	Shader light_shader = create_shader((GLchar**)&&LIGHT_VERT, (GLchar**)&&LIGHT_FRAG);
	defer light_shader.delete_shader();

	Camera cam = create_camera();

    while (!win.should_close())
    {
        win.input(&cam);

		if (gfx::is_key_down(SPACE, win)) continue;

		gl::clearColor(0.3, 0.3, 0.3, 1);
		gl::clear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		light_shader.send_uniform_light(&cam);
		light_shader.draw_light();

        base_shader.send_uniform_base(&cam);
		base_shader.draw_base();

		win.swap_opengl_buffers();
    }
}