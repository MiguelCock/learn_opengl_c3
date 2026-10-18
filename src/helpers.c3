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