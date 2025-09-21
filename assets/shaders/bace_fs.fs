 #version 330
 in vec2 fragTexCoord;
 in vec4 fragTexCoord2;
 in vec4 fragColor;
 in vec3 fragNormal;
 in vec2 positionWS;



 
 uniform sampler2D texture0;
 uniform vec4 colDiffuse;
 uniform vec2 at_size;
 
 out vec4 finalColor;


 void main()
 {
	vec4 texelColor = texture2D(texture0, fragTexCoord);
	if (texelColor.a<=0.1) {
		if( texelColor.a <= 0.0 ){
			discard;
		}
		if( texelColor.r >= 0.8){

		    vec2 localUV = fract(positionWS / (fragTexCoord2.zw));
    		vec2 uv_min =  fragTexCoord2.xy/at_size;
    		vec2 uv_max =  ((fragTexCoord2.zw+fragTexCoord2.xy)/at_size);
			vec2 uv2 = uv_min + localUV * (fragTexCoord2.zw/at_size);
			texelColor = texture2D(texture0, uv2);

		}
	}
    finalColor = texelColor*colDiffuse*fragColor;

 }    