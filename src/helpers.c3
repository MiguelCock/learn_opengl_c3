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

fn void GfxWindow.close_window(GfxWindow* self)
{
    if (try e = gfx::poll(self))
    {
        switch (e.type)
        {
            case WINDOW_CLOSE: 
                return;
            case KEY_PRESSED:
                if (e.key.value == ESCAPE) return;
                if (e.key.value == F) self.set_fullscreen(!self.is_fullscreen());
            default:
                break;
        }
    }
}