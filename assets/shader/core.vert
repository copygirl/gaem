#version 330 core

in vec3 inPosition;
in vec4 inColor;

out vec4 fragColor;

uniform mat4 projection;
uniform mat4 modelview = mat4(1.0);

void main() {
	fragColor = inColor;
	gl_Position = projection * modelview * vec4(inPosition, 1.0);
}
