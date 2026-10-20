module opengl_test;

import std;
import std::gfx;
import opengl::gl;

fn void check_for_errors(String format, GLuint program)
{
	int success;
    char[512] infoLog;
    gl::getShaderiv(program, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        gl::getShaderInfoLog(program, 512, null, &infoLog);
        io::printfn(format, (String)&infoLog);
    }
}

fn void GfxWindow.input(&self, Camera* cam)
{
    while (try e = gfx::poll(self));
	
	if (gfx::is_key_down(ESCAPE, self)) return;
	if (gfx::is_key_down(F, self)) self.set_fullscreen(!self.is_fullscreen());

	cam.update(self);
}

fn GfxWindow* create_window()
{
	gfx::init("Hello", { .init_opengl = true })!!;

	gfx::load_opengl()!!;

    GfxWindow* win = gfx::create_window("Hello", 200, 200, 900, 600)!!;

    win.set_exit_key(ESCAPE);

	GfxGlHints hints;
	hints.major = 3;
	hints.minor = 3;
	hints.depth = 24;
	GfxGlContext* cont = win.create_opengl_context(&hints)!!;

	if (cont == null)
	{
		io::printn("Failed to create OpenGL 3.3 core context. Check driver support.");
		return null;
	}

	gl::load_gl_internal((GLLoadFn)&gfx::get_opengl_proc);

	gl::enable(GL_BLEND); 
	gl::blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	gl::enable(GL_DEPTH_TEST);
	//gl::enable(GL_CULL_FACE);

	return win;
}

fn void GfxWindow.destoy_window(&self)
{
	self.destroy();
	gfx::unload_opengl();
	gfx::finalize();
}