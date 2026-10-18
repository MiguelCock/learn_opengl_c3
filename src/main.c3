module opengl_test;

import std;
import std::gfx;
import opengl::gl;
import std::thread;

fn void main()
{
    gfx::init("Hello", { .init_opengl = true })!!;
    defer gfx::finalize();

	gfx::load_opengl()!!;
	defer gfx::unload_opengl();

    GfxWindow* win = gfx::create_window("Hello", 200, 200, 900, 600)!!;
    defer win.destroy();

    win.set_exit_key(ESCAPE);

	GfxGlHints hints;
	hints.major = 3;
	hints.minor = 3;
	hints.depth = 24;
	GfxGlContext* cont = win.create_opengl_context(&hints)!!;

	if (cont == null)
	{
		io::printn("Failed to create OpenGL 3.3 core context. Check driver support.");
		return;
	}

	gl::load_gl_internal((GLLoadFn)&gfx::get_opengl_proc);

	gl::enable(GL_BLEND); 
	gl::blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	gl::enable(GL_DEPTH_TEST);

	Program program = create_program();
    defer program.delete_program();
    program.generate_vao();

	Camera cam = create_camera();

	Data data = {win, &cam};
	Thread thread;
	thread.create((ThreadFn)&thread_fn, &data)!!;
	defer thread.join()!!;

    while (!win.should_close())
    {
        //win.input(&cam);

		gl::clearColor(0.2f, 0.3f, 0.3f, 1.0f);
		gl::clear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        program.send_uniform(&cam);
		program.draw();

		win.swap_opengl_buffers();
    }
}