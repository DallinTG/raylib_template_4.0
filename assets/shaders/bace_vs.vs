#version 330

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexBoneWeights; //fragTexCoord2
in vec3 vertexNormal;
in vec4 vertexColor;



uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 matNormal;
uniform vec2 at_size;


out vec2 fragTexCoord;
out vec4 fragTexCoord2;
out vec4 fragColor;
out vec3 fragNormal;
out vec2 positionWS;




void main()
{


    positionWS = (matModel * vec4(vertexPosition,1)).xy;


    fragTexCoord = vertexTexCoord;

    
    // vec2 localUV = fract(positionWS / (vertexBoneWeights.zw));
    // vec2 uv_min =  vertexBoneWeights.xy/at_size;
    // vec2 uv_max =  ((vertexBoneWeights.zw+vertexBoneWeights.xy)/at_size);
    // fragTexCoord2 = uv_min + localUV * (vertexBoneWeights.zw/at_size);
    fragTexCoord2 = vertexBoneWeights;

    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));

    // Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}

