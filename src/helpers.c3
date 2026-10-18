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

fn bool GfxWindow.input(&self, Camera* cam)
{
    if (try e = gfx::poll(self))
    {
        switch (e.type)
        {
            case WINDOW_CLOSE: 
                return true;
            case KEY_PRESSED:
                if (e.key.value == ESCAPE) return true;
                if (e.key.value == F) self.set_fullscreen(!self.is_fullscreen());
            default:
                break;
        }

		cam.update(self, &e);
    }

	return false;
}

struct Data
{
	GfxWindow* win;
	Camera* cam;
}

fn void thread_fn(void* args)
{
	Data* data = (Data*)args;
	while (true)
	{
		if (data.win.input(data.cam)) break;
	}
	return;
}