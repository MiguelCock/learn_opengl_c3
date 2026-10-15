#version 330 core

out vec4 FragColor;

uniform vec4 color;
in vec3 ourColor;
in vec2 TexCoord;

// texture sampler
uniform sampler2D texture1;

void main()
{
    FragColor = FragColor = texture(texture1, TexCoord) + vec4(ourColor, 0.0) * 0.4; //+ color * 0.1;
}