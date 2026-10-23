module opengl_test;

import std;
import std::gfx;
import std::math::matrix;
import opengl::gl;
import spng;

struct Shader
{
	GLuint vertexShader;
	GLuint fragmentShader;
	GLuint shaderProgram;
	GLuint vbo, vao, ebo;
	GLuint texture;
}

const BASE_VERT = $embed("../resources/base_vert.vs");
const BASE_FRAG = $embed("../resources/base_frag.fs");
const LIGHT_VERT = $embed("../resources/ligth_vert.vs");
const LIGHT_FRAG = $embed("../resources/ligth_frag.fs");
const IMG = $embed("../resources/leaves.png");

float[*] vertices = {
    // front face (+Z)
    -0.5, -0.5,  0.5,  0.0, 0.0,   0.0,  0.0,  1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,   0.0,  0.0,  1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,   0.0,  0.0,  1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,   0.0,  0.0,  1.0,

    // back face (-Z)
     0.5, -0.5, -0.5,  0.0, 0.0,   0.0,  0.0, -1.0,
    -0.5, -0.5, -0.5,  1.0, 0.0,   0.0,  0.0, -1.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,   0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0, 1.0,   0.0,  0.0, -1.0,

    // left face (-X)
    -0.5, -0.5, -0.5,  0.0, 0.0,  -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5,  1.0, 0.0,  -1.0,  0.0,  0.0,
    -0.5,  0.5,  0.5,  1.0, 1.0,  -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,  -1.0,  0.0,  0.0,

    // right face (+X)
     0.5, -0.5,  0.5,  0.0, 0.0,   1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,   1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,   1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  0.0, 1.0,   1.0,  0.0,  0.0,

    // bottom face (-Y)
    -0.5, -0.5, -0.5,  0.0, 0.0,   0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,   0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  1.0, 1.0,   0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, 1.0,   0.0, -1.0,  0.0,

    // top face (+Y)
     0.5,  0.5, -0.5,  1.0, 1.0,   0.0,  1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,   0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,   0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,   0.0,  1.0,  0.0
};

GLuint[*] indices = {
    0, 1, 2, 2, 3, 0,        // front
    4, 5, 6, 6, 7, 4,        // back
    8, 9, 10, 10, 11, 8,     // left
    12, 13, 14, 14, 15, 12,  // right
    16, 17, 18, 18, 19, 16,  // bottom
    20, 21, 22, 22, 23, 20   // top
};

fn Shader create_shader(GLchar** vert, GLchar** frag)
{
	Shader shader;

	shader.vertexShader = gl::createShader(GL_VERTEX_SHADER);
	gl::shaderSource(shader.vertexShader, 1, vert, null);
    gl::compileShader(shader.vertexShader);
	check_for_errors("ERROR::SHADER::VERTEX::COMPILATION_FAILED: %s", shader.vertexShader);

    shader.fragmentShader = gl::createShader(GL_FRAGMENT_SHADER);
    gl::shaderSource(shader.fragmentShader, 1, frag, null);
    gl::compileShader(shader.fragmentShader);
	check_for_errors("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED: %s", shader.fragmentShader);

    shader.shaderProgram = gl::createProgram();
    gl::attachShader(shader.shaderProgram, shader.vertexShader);
    gl::attachShader(shader.shaderProgram, shader.fragmentShader);
    gl::linkProgram(shader.shaderProgram);
	int success;
    char[512] infoLog;
	gl::getProgramiv(shader.shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        gl::getProgramInfoLog(shader.shaderProgram, 512, null, &infoLog);
		io::printfn("ERROR::SHADER::PROGRAM::LINKING_FAILED: %s", (String)&infoLog);
    }

    gl::deleteShader(shader.vertexShader);
    gl::deleteShader(shader.fragmentShader);

	// ================ VAO ================
	gl::genVertexArrays(1, &shader.vao);
    gl::genBuffers(1, &shader.vbo);
    gl::genBuffers(1, &shader.ebo);
    gl::bindVertexArray(shader.vao);

    gl::bindBuffer(GL_ARRAY_BUFFER, shader.vbo);
    gl::bufferData(GL_ARRAY_BUFFER, vertices.len * float::size, &vertices, GL_STATIC_DRAW);

    gl::bindBuffer(GL_ELEMENT_ARRAY_BUFFER, shader.ebo);
    gl::bufferData(GL_ELEMENT_ARRAY_BUFFER, indices.len * GLuint::size, &indices, GL_STATIC_DRAW);

    gl::vertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * float::size, null);
    gl::enableVertexAttribArray(0);

	gl::vertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 8 * float::size, (void*)(3 * float::size));
    gl::enableVertexAttribArray(1);

	gl::vertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 8 * float::size, (void*)(5 * float::size));
    gl::enableVertexAttribArray(2);

    gl::bindBuffer(GL_ARRAY_BUFFER, 0); 

    gl::genTextures(1, &shader.texture);
    gl::bindTexture(GL_TEXTURE_2D, shader.texture);
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

	return shader;
}

fn void Shader.delete_shader(&self)
{
	gl::deleteProgram(self.shaderProgram);

	gl::deleteVertexArrays(1, &self.vao);
	gl::deleteBuffers(1, &self.vbo);
	gl::deleteBuffers(1, &self.ebo);
}

float timeValue;
Vec3 light_pos = {5, 5, -5};

struct Material {
    Vec3 ambient;
    Vec3 diffuse;
    Vec3 specular;
    float shininess;
}

fn void Shader.send_uniform_base(&self, Camera* cam)
{
	timeValue += 0.005;

	gl::bindTexture(GL_TEXTURE_2D, self.texture);
	gl::useProgram(self.shaderProgram);

	//Mat4 mat = matrix::IDENTITY4.translate({math::cos(timeValue), math::sin(timeValue), 0}).rotate(timeValue*5, {1, 1, 1});
    Mat4 mat = matrix::IDENTITY4;
	gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "transform"), 1, GL_FALSE, (GLfloat*)&mat);

    gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "view"), 1, GL_FALSE, (GLfloat*)&cam.view);

	Mat4 projection = matrix::perspective(cam.zoom, 900/600, 0.1, 100);
    gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "projection"), 1, GL_FALSE, (GLfloat*)&projection);

	// light
    gl::uniform3fv(gl::getUniformLocation(self.shaderProgram, "lightPos"), 1, &light_pos);
    gl::uniform3fv(gl::getUniformLocation(self.shaderProgram, "viewPos"), 1, (GLfloat*)&cam.pos);
    gl::uniform3f(gl::getUniformLocation(self.shaderProgram, "lightColor"), 1, 1, 1);
}

fn void Shader.send_uniform_light(&self, Camera* cam)
{
	float factor = 2;
	light_pos = {math::cos(timeValue) * factor, math::sin(timeValue) * factor, 2};

    //light_pos = light_pos.rotate_axis({1, 0, 0}, math::cos(timeValue) / 2);

	gl::bindTexture(GL_TEXTURE_2D, self.texture);
	gl::useProgram(self.shaderProgram);

	Mat4 mat = matrix::IDENTITY4.rotate(timeValue*5, {1, 1, 1});
    gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "transform"), 1, GL_FALSE, (GLfloat*)&mat);

    gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "view"), 1, GL_FALSE, (GLfloat*)&cam.view);

	Mat4 projection = matrix::perspective(cam.zoom, 900/600, 0.1, 100);
    gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "projection"), 1, GL_FALSE, (GLfloat*)&projection);

	Mat4 model = matrix::IDENTITY4.translate(light_pos);
	gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "model"), 1, GL_FALSE, (GLfloat*)&model);
}

Vec3[*] cubePositions = {
    {-1, -1, 0},
    {-1, 0, 0},
    {-1, 1, 0},
    {-1, 2, 0},
    {0, -1, 0},
    {0, 0, 0},
    {0, 1, 0},
    {0, 2, 0},
    {1, 0, 0},
    {1, 1, 0}
};

Material[*] cubeMaterials = {
	{ {0.0215, 0.1745, 0.0215}, {0.07568, 0.61424, 0.07568}, {0.633, 0.727811, 0.633}, 0.6 }, //emerald
	{ {0.2125, 0.1275, 0.054}, {0.714, 0.4284, 0.18144}, {0.393548, 0.271906, 0.166721}, 1 }, // bronze
	{ {0.05375, 0.05, 0.06625}, {0.18275, 0.17, 0.22525}, {0.332741, 0.328634, 0.346435}, 0.3 }, // obsidian
	{ {0, 0, 0}, {0.1, 0.35, 0.1}, {0.45, 0.55, 0.45}, 0.25 }, // green plastic
	{ {0.05, 0.05, 0.05}, {0.05, 0.05, 0.05}, {0.7, 0.7, 0.7}, 0.078125 }, // white rubber
	{ {0.25, 0.25, 0.25}, {0.4, 0.4, 0.4}, {0.774597, 0.774597, 0.774597}, 0.6 }, //chrome
	{ {0.02, 0.02, 0.02}, {0.01, 0.01, 0.01}, {0.4, 0.4, 0.4}, 0.6 }, // black rubber
	{ {0.1745, 0.01175, 0.01175}, {0.61424, 0.04136, 0.04136}, {0.727811, 0.626959, 0.626959}, 0.6 }, // ruby
	{ {0, 0, 0}, {0.1, 0.35, 0.1}, {0.45, 0.55, 0.45}, 0.25 }, // green plastic
	{ {0.05, 0.05, 0.05}, {0.05, 0.05, 0.05}, {0.7, 0.7, 0.7}, 0.078125 }, // white rubber
    // { {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, 0}
};

fn void Shader.draw_base(&self)
{
	gl::bindVertexArray(self.vao);

	for(int i = 0; i < 10; i++)
	{
		Mat4 model = matrix::IDENTITY4.translate(cubePositions[i]);
    	gl::uniformMatrix4fv(gl::getUniformLocation(self.shaderProgram, "model"), 1, GL_FALSE, (GLfloat*)&model);

		gl::uniform3fv(gl::getUniformLocation(self.shaderProgram, "material.ambient"), 1, &cubeMaterials[i].ambient);
		gl::uniform3fv(gl::getUniformLocation(self.shaderProgram, "material.diffuse"), 1, &cubeMaterials[i].diffuse);
		gl::uniform3fv(gl::getUniformLocation(self.shaderProgram, "material.specular"), 1, &cubeMaterials[i].specular);
		gl::uniform1fv(gl::getUniformLocation(self.shaderProgram, "material.shininess"), 1, &cubeMaterials[i].shininess);

		gl::drawElements(GL_TRIANGLES, indices.len, GL_UNSIGNED_INT, null);
	}
}

fn void Shader.draw_light(&self)
{
	gl::bindVertexArray(self.vao);
	gl::drawElements(GL_TRIANGLES, indices.len, GL_UNSIGNED_INT, null);
}