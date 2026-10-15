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

// set up vertex data (and buffer(s)) and configure vertex attributes
// ------------------------------------------------------------------
float[*] vertices = {
	0.5,  	0.5, 	0.0f, 	1, 0, 0, 	1, 1,  // top right
	0.5, 	-0.5, 	0.0f, 	0, 1, 0, 	1, 0,  // bottom right
	-0.5, 	-0.5, 	0.0f, 	0, 0, 1, 	0, 0,  // bottom left
	-0.5,  0.5, 	0.0f, 	1, 1, 1, 	0, 1   // top left 
};
GLuint[*] indices = {  // note that we start from 0!
	0, 1, 3,  // first Triangle
	1, 2, 3   // second Triangle
};

fn Program create_program()
{
	Program program;

	// build and compile our shader program
    // ------------------------------------
    // vertex shader
	program.vertexShader = gl::createShader(GL_VERTEX_SHADER);
	gl::shaderSource(program.vertexShader, 1, (GLchar**)&&VERT, null);
    gl::compileShader(program.vertexShader);
	// check for shader compile errors
	check_for_errors("ERROR::SHADER::VERTEX::COMPILATION_FAILED: %s", program.vertexShader);
	// fragment shader
    program.fragmentShader = gl::createShader(GL_FRAGMENT_SHADER);
    gl::shaderSource(program.fragmentShader, 1, (GLchar**)&&FRAG, null);
    gl::compileShader(program.fragmentShader);
    // check for shader compile errors
	check_for_errors("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED: %s", program.fragmentShader);

	// link shaders
    program.shaderProgram = gl::createProgram();
    gl::attachShader(program.shaderProgram, program.vertexShader);
    gl::attachShader(program.shaderProgram, program.fragmentShader);
    gl::linkProgram(program.shaderProgram);
    // check for linking errors
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
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    gl::bindVertexArray(self.vao);

    gl::bindBuffer(GL_ARRAY_BUFFER, self.vbo);
    gl::bufferData(GL_ARRAY_BUFFER, vertices.len * float::size, &vertices, GL_STATIC_DRAW);

    gl::bindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    gl::bufferData(GL_ELEMENT_ARRAY_BUFFER, indices.len * GLuint::size, &indices, GL_STATIC_DRAW);

    gl::vertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * float::size, null);
    gl::enableVertexAttribArray(0);

	gl::vertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * float::size, (void*)(3 * float::size));
    gl::enableVertexAttribArray(1);

	gl::vertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * float::size, (void*)(6 * float::size));
    gl::enableVertexAttribArray(2);

    // note that this is allowed, the call to glVertexAttribPointer registered vbo as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    gl::bindBuffer(GL_ARRAY_BUFFER, 0); 

    // remember: do NOT unbind the ebo while a vao is active as the bound element buffer object IS stored in the vao; keep the ebo bound.
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	self.texture;
    gl::genTextures(1, &self.texture);
    gl::bindTexture(GL_TEXTURE_2D, self.texture); // all upcoming GL_TEXTURE_2D operations now have effect on this texture object
    // set the texture wrapping parameters
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// set texture wrapping to GL_REPEAT (default wrapping method)
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    // set texture filtering parameters
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    gl::texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    // load image, create texture and generate mipmaps
	Context *spng = spng::new(0);
	spng.set_png_buffer(IMG, IMG.len);
	Ihdr pngHdr;
	spng.get_ihdr(&pngHdr);
	usz size;

	io::printn(pngHdr.color_type == ColorType.INDEXED);

	spng.decoded_image_size(Format.RGBA8, &size);
	char* pixels = malloc((sz)size);
	defer free(pixels);
	spng.decode_image(pixels, size, Format.RGBA8, 0);
    gl::texImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pngHdr.width, (GLsizei)pngHdr.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    gl::generateMipmap(GL_TEXTURE_2D);

    // You can unbind the vao afterwards so other vao calls won't accidentally modify this vao, but this rarely happens. Modifying other
    // vaos requires a call to glBindVertexArray anyways so we generally don't unbind vaos (nor vbos) when it's not directly necessary.
    gl::bindVertexArray(0);
}

fn void Program.delete_program(&self)
{
	gl::deleteProgram(self.shaderProgram);

	gl::deleteVertexArrays(1, &self.vao);
	gl::deleteBuffers(1, &self.vbo);
	gl::deleteBuffers(1, &self.ebo);
}

double timeValue;

fn void Program.send_uniform(&self)
{
	// update shader uniform
	timeValue += 0.005;
	float greenValue = (math::sin((float)timeValue) / 2.0) + 0.5;
	int vertexColorLocation = gl::getUniformLocation(self.shaderProgram, "color");
	gl::uniform4f(vertexColorLocation, 0, 0, 0, 1);

	Mat4 mat = matrix::IDENTITY4.translate({0.5, -0.5, 0}).rotate((float)timeValue*5, {0, 0, 1});

	int transform_ocation = gl::getUniformLocation(self.shaderProgram, "transform");
    gl::uniformMatrix4fv(transform_ocation, 1, GL_FALSE, (GLfloat*)&mat);
}

fn void Program.draw(&self)
{
	gl::bindTexture(GL_TEXTURE_2D, self.texture);

	// draw our first triangle
	gl::useProgram(self.shaderProgram);

	int textureLocation = gl::getUniformLocation(self.shaderProgram, "texture1");
    gl::uniform1i(textureLocation, 0);

	gl::bindVertexArray(self.vao); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
	//glDrawArrays(GL_TRIANGLES, 0, 6);
	gl::drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
	// glBindVertexArray(0); // no need to unbind it every time 
}