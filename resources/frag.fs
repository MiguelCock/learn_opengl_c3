#version 330 core

out vec4 FragColor;

uniform vec4 color;

in vec2 TexCoord;

// texture sampler
uniform sampler2D texture1;

void main()
{
    FragColor = texture(texture1, TexCoord) + vec4(color.xxx, 0);
}