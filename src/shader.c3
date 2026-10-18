module opengl_test;

import std;
import std::gfx;
import std::math::matrix;
import opengl::gl;
import spng;

struct Program
{
	GLuint vertexShader;
	GLuint fragmentShader;
	GLuint shaderProgram;
	GLuint vbo, vao, ebo;
	GLuint texture;
}

const VERT = $embed("../resources/vert.vs");
const FRAG = $embed("../resources/frag.fs");
const IMG = $embed("../resources/leaves.png");

float[*] vertices = {
    // front face
    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,

    // back face
     0.5, -0.5, -0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  0.0, 1.0,

    // left face
    -0.5, -0.5, -0.5,  0.0, 0.0,
    -0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,

    // right face
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  0.0, 1.0,

    // bottom face
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 1.0,

    // top face
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0
};

GLuint[*] indices = {
    0, 1, 2, 2, 3, 0,        // front
    4, 5, 6, 6, 7, 4,        // back
    8, 9, 10, 10, 11, 8,     // left
    12, 13, 14, 14, 15, 12,  // right
    16, 17, 18, 18, 19, 16,  // bottom
    20, 21, 22, 22, 23, 20   // top
};

fn Program create_program()
{
	Program program;

	program.vertexShader = gl::createShader(GL_VERTEX_SHADER);
	gl::shaderSource(program.vertexShader, 1, (GLchar**)&&VERT, null);
    gl::compileShader(program.vertexShader);
	check_for_errors("ERROR::SHADER::VERTEX::COMPILATION_FAILED: %s", program.vertexShader);

    program.fragmentShader = gl::createShader(GL_FRAGMENT_SHADER);
    gl::shaderSource(program.fragmentShader, 1, (GLchar**)&&FRAG, null);
    gl::compileShader(program.fragmentShader);
	check_for_errors("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED: %s", program.fragmentShader);

    program.shaderProgram = gl::createProgram();
    gl::attachShader(program.shaderProgram, program.vertexShader);
    gl::attachShader(program.shaderProgram, program.fragmentShader);
    gl::linkProgram(program.shaderProgram);
	int success;
    char[512] infoLog;
	gl::getProgramiv(program.shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        gl::getProgramInfoLog(program.shaderProgram, 512, null, &infoLog);
		io::printfn("ERROR::SHADER::PROGRAM::LINKING_FAILED: %s", (String)&infoLog);
    }

    gl::deleteShader(program.vertexShader);
    gl::deleteShader(program.fragmentShader);

	return program;
}

fn void Program.generate_vao(&self)
{
	gl::genVertexArrays(1, &self.vao);
    gl::genBuffers(1, &self.vbo);
    gl::genBuffers(1, &self.ebo);
    gl::bindVertexArray(self.vao);

    gl::bindBuffer(GL_ARRAY_BUFFER, self.vbo);
    gl::bufferData(GL_ARRAY_BUFFER, vertices.len * float::size, &vertices, GL_STATIC_DRAW);

    gl::bindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    gl::bufferData(GL_ELEMENT_ARRAY_BUFFER, indices.len * GLuint::size, &indices, GL_STATIC_DRAW);

    gl::vertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * float::size, null);
    gl::enableVertexAttribArray(0);

	gl::vertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * float::size, (void*)(3 * float::size));
    gl::enableVertexAttribArray(1);

    gl::bindBuffer(GL_ARRAY_BUFFER, 0); 

	self.texture;
    gl::genTextures(1, &self.texture);
    gl::bindTexture(GL_TEXTURE_2D, self.texture);
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	Context *spng = spng::new(0);
	spng.set_png_buffer(IMG, IMG.len);
	Ihdr pngHdr;
	spng.get_ihdr(&pngHdr);
	usz size;

	spng.decoded_image_size(Format.RGBA8, &size);
	char* pixels = malloc((sz)size);
	defer free(pixels);
	spng.decode_image(pixels, size, Format.RGBA8, 0);
    gl::texImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pngHdr.width, (GLsizei)pngHdr.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    gl::generateMipmap(GL_TEXTURE_2D);

    gl::bindVertexArray(0);
}

fn void Program.delete_program(&self)
{
	gl::deleteProgram(self.shaderProgram);

	gl::deleteVertexArrays(1, &self.vao);
	gl::deleteBuffers(1, &self.vbo);
	gl::deleteBuffers(1, &self.ebo);
}

float timeValue;

fn void Program.send_uniform(&self, Camera* cam)
{
	timeValue += 0.005;
	float greenValue = (math::sin(timeValue)) + 0.5;
	int vertexColorLocation = gl::getUniformLocation(self.shaderProgram, "color");
	gl::uniform4f(vertexColorLocation, 0, 0, 0, 1);

	Mat4 mat = matrix::IDENTITY4.translate({math::cos(timeValue), math::sin(timeValue), 0}).rotate(timeValue*5, {1, 1, 1});
	int transform_location = gl::getUniformLocation(self.shaderProgram, "transform");
    gl::uniformMatrix4fv(transform_location, 1, GL_FALSE, (GLfloat*)&mat);

	cam.view = matrix::look_at(cam.pos, cam.pos + cam.front, cam.up);
	int view_location = gl::getUniformLocation(self.shaderProgram, "view");
    gl::uniformMatrix4fv(view_location, 1, GL_FALSE, (GLfloat*)&cam.view);

	Mat4 projection = matrix::perspective(cam.fov, 800/600, 0.1, 100);
	int projection_location = gl::getUniformLocation(self.shaderProgram, "projection");
    gl::uniformMatrix4fv(projection_location, 1, GL_FALSE, (GLfloat*)&projection);
}

Vec3[*] cubePositions = {
    { 0.0f,  0.0f,  0.0f}, 
    { 2.0f,  5.0f, -15.0f}, 
    {-1.5f, -2.2f, -2.5f},  
    {-3.8f, -2.0f, -12.3f},  
    { 2.4f, -0.4f, -3.5f},  
    {-1.7f,  3.0f, -7.5f},  
    { 1.3f, -2.0f, -2.5f},  
    { 1.5f,  2.0f, -2.5f}, 
    { 1.5f,  0.2f, -1.5f}, 
    {-1.3f,  1.0f, -1.5f}  
};

fn void Program.draw(&self)
{
	gl::bindTexture(GL_TEXTURE_2D, self.texture);

	gl::useProgram(self.shaderProgram);

	gl::bindVertexArray(self.vao);

	for(uint i = 0; i < 10; i++)
	{
		Mat4 model = matrix::IDENTITY4.translate(cubePositions[i]).rotate((float)math::deg_to_rad(20 * i), {1, 0.3, 0.5});
		int model_location = gl::getUniformLocation(self.shaderProgram, "model");
    	gl::uniformMatrix4fv(model_location, 1, GL_FALSE, (GLfloat*)&model);

		gl::drawElements(GL_TRIANGLES, indices.len, GL_UNSIGNED_INT, null);
	}
}