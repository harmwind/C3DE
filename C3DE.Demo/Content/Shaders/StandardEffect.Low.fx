// Matrix
float4x4 World;
float4x4 View;
float4x4 Projection;

// Material
float3 AmbientColor = float3(0.1, 0.1, 0.1);
float3 DiffuseColor = float3(1.0, 1.0, 1.0);
float3 EmissiveColor = float3(0.0, 0.0, 0.0);
float3 SpecularColor = float3(0.8, 0.8, 0.8);
float Shininess = 200.0;
float EmissiveIntensity = 1.0;

// Lighting
float3 LightColor;
float3 LightDirection;
float3 LightPosition;
float LightIntensity;
float LightSpotAngle;
float LightRange;
int LightFallOff;
int LightType = 0;
int EmissiveTextureEnabled;

// Misc
float3 EyePosition = float3(1, 1, 0);
float2 TextureTiling = float2(1, 1);

texture MainTexture;
sampler2D textureSampler = sampler_state
{
	Texture = (MainTexture);
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

texture EmissiveTexture;
sampler2D emissiveSampler = sampler_state
{
	Texture = (EmissiveTexture);
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

float3 CalcDirectionalLightColor(float3 normal, float4 worldPosition)
{
	float3 diffuse = saturate(dot(normal, LightDirection));
	return diffuse * LightColor * LightIntensity;
}

float3 CalcPointLightColor(float3 normal, float4 worldPosition)
{
	float3 lightDirection = normalize(LightPosition - worldPosition);
	float diffuse = saturate(dot(normal, lightDirection));
	float d = distance(LightPosition, worldPosition);
	float attenuation = 1 - pow(clamp(d / LightRange, 0, 1), LightFallOff);

	return diffuse * attenuation * LightColor * LightIntensity;
}

float3 CalcSpotLightColor(float3 normal, float4 worldPosition)
{
	float3 lightDirection = normalize(LightPosition - worldPosition);
	float3 diffuse = saturate(dot(normal, lightDirection));

	float d = dot(lightDirection, normalize(LightDirection));
	float a = cos(LightSpotAngle);

	float attenuation = 1.0;

	if (a < d)
		attenuation = 1 - pow(clamp(a / d, 0, 1), LightFallOff);

	return diffuse * attenuation * LightColor * LightIntensity;
}

float3 CalcSpecularColor(float3 normal, float4 worldPosition, float3 color, int type)
{
	if (type == 0)
		return float3(0, 0, 0);

	float3 lightDirection = LightDirection;

	//  Point light 
	if (type == 2)
		lightDirection = normalize(LightPosition - worldPosition);

	float3 R = normalize(2 * color.xyz * normal - lightDirection);

	return SpecularColor * pow(saturate(dot(R, normalize(LightPosition - worldPosition))), Shininess);
}

struct VertexShaderInput
{
#if SM4
	float4 Position : SV_Position;
#else
	float4 Position : POSITION0;
#endif
	float2 UV : TEXCOORD0;
	float3 Normal : NORMAL0;
};

struct VertexShaderOutput
{
	float4 Position : POSITION0;
	float2 UV : TEXCOORD0;
	float3 Normal : TEXCOORD1;
	float4 WorldPosition : TEXCOORD2;
	float FogDistance : FOG;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
	VertexShaderOutput output;

	float4 worldPosition = mul(input.Position, World);
	float4 viewPosition = mul(worldPosition, View);
	output.Position = mul(viewPosition, Projection);
	output.UV = input.UV;
	output.Normal = mul(input.Normal, World);
	output.WorldPosition = worldPosition;
	output.FogDistance = distance(worldPosition, EyePosition);

	return output;
}

float4 PixelShaderAmbient(VertexShaderOutput input) : COLOR0
{
    float3 diffuseColor = tex2D(textureSampler, input.UV * TextureTiling).xyz;
    return float4(AmbientColor * (DiffuseColor + diffuseColor), 1);
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
    float3 lightFactor = float3(0, 0, 0);
	float3 normal = normalize(input.Normal);

	// Apply a light influence.
	if (LightType == 1)
		lightFactor = CalcDirectionalLightColor(normal, input.WorldPosition);
	else if (LightType == 2)
		lightFactor = CalcPointLightColor(normal, input.WorldPosition);
	else if (LightType == 3)
		lightFactor = CalcSpotLightColor(normal, input.WorldPosition);

	float3 finalDiffuse = lightFactor;
	float3 finalSpecular = CalcSpecularColor(normal, input.WorldPosition, finalDiffuse, LightType);
	float3 finalCompose = finalDiffuse + finalSpecular;
	
	return float4(finalCompose, 1.0);
}

float4 PixelShaderEmissive(VertexShaderOutput input) : COLOR0
{
    float3 emissiveColor = EmissiveColor;

    if (EmissiveTextureEnabled == 1)
        emissiveColor = tex2D(emissiveSampler, input.UV * TextureTiling).xyz;

    return float4(emissiveColor * EmissiveIntensity, 1);
}

technique Textured
{
	pass AmbientPass
	{
#if SM4
		VertexShader = compile vs_4_0_level_9_3 VertexShaderFunction();
		PixelShader = compile ps_4_0_level_9_3 PixelShaderAmbient();
#else
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 PixelShaderAmbient();
#endif
	}
	
	pass LightPass
	{
#if SM4
		PixelShader = compile ps_4_0_level_9_3 PixelShaderFunction();
#else
		PixelShader = compile ps_3_0 PixelShaderFunction();
#endif
	}
	
	pass EmissivePass
	{
#if SM4
		PixelShader = compile ps_4_0_level_9_3 PixelShaderEmissive();
#else
		PixelShader = compile ps_3_0 PixelShaderEmissive();
#endif
	}
}