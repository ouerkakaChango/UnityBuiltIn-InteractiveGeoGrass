Shader "XCGrass/grass_v1"
{
	//Custom interactive
	//No shadow,only 1 segment, unlit 
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Height", Float) = 0.5
		_BladeHeightRandom("Blade Height Random", Float) = 0.3

		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1

		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Float) = 1

		_MaskRT("_MaskRT", 2D) = "black" {}
		_MaskUV("_MaskUV", Vector) = (0, 0, 0, 0)
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "Shaders/CustomTessellation.cginc" 

	#define BLADE_SEGMENTS 1
	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	struct geometryOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 grassInfo : TEXCOORD3;
	};

	float _BendRotationRandom;
	float _BladeHeight;
	float _BladeHeightRandom;
	float _BladeWidth;
	float _BladeWidthRandom;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;

	sampler2D _MaskRT;
	float4 _MaskRT_ST;
	float4 _MaskUV;
	geometryOutput VertexOutput(float3 pos, float2 uv, float4 grassInfo)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = uv;
		o.grassInfo = grassInfo;
		return o;
	}

	geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float height, float2 uv, float3x3 transformMatrix,float colorInten)
	{
		float3 tangentPoint = float3(width, 0, height);

		float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);
		float4 grassInfo = 0;
		grassInfo.r = height;
		grassInfo.g = colorInten;
		return VertexOutput(localPosition, uv, grassInfo);
	}

	float2 safeNormalize(float2 v)
	{
		if (length(v) < 0.00001f)
		{
			return float2(1, 0);
		}
		else
		{
			return normalize(v);
		}
	}

	//??? 很奇怪，我也不知道为啥会对应成这样，不管了
	float2 ForceDir(float2 worldDir)
	{
		return safeNormalize(float2(worldDir.y, -worldDir.x));
	}

	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
	void geo(triangle vertexOutput IN[3], inout TriangleStream<geometryOutput> triStream)
	{
		float3 pos = IN[0].vertex.xyz;
		pos.x += 0.1f*rand(pos.z);
		pos.z += 0.1f*rand(pos.x);

		float3 vNormal = IN[0].normal;
		float4 vTangent = IN[0].tangent;
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);

		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));

		//??? 默认朝着贴图(1,1)方向移动
		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y*float2(1,1);
		float2 windDirColor = tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy;
		float2 windSample = (windDirColor * 2 - 1) * _WindStrength;
		float3 wind = normalize(float3(windSample.x, windSample.y, 0));
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample.x, wind);
		float3x3 identity = float3x3(1, 0, 0,
			0, 1, 0,
			0, 0, 1);
		//float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);
		//??? +z,-x,0
		float forceScale = 0;
		float colorInten = 1;
		float3 worldPos = mul(unity_ObjectToWorld, IN[0].vertex).xyz;
		float r = 10;
		//if (length(worldPos.xz) < r)
		float2 planeUV = (worldPos.xz - _MaskUV.xy) / _MaskUV.zw;
		//!!! 不知道为啥，xz是反的，不管，强行转一下
		planeUV = 1 - planeUV;
		half4 mask = tex2Dlod(_MaskRT, float4(planeUV,0,0));
		//if(mask.r>0.5&&mask.a>0.01)
		{
			forceScale = mask.a;// mask.a;// saturate(1 - length(worldPos.xz) / r);
			//_BladeHeight = 0;
			//_BladeWidthRandom = 0;
			windRotation = lerp(windRotation, identity,mask.a);
			colorInten = lerp(1,0.2,mask.a);
		}
		float2 f2 = ForceDir(float2(1, 0));
		float3x3 tt = AngleAxis3x3(UNITY_PI *0.49* forceScale, float3(f2.x,f2.y,0));
		float3x3 transformationMatrix = mul(mul(mul(tt, windRotation), facingRotationMatrix), bendRotationMatrix);
		transformationMatrix = mul(tangentToLocal, transformationMatrix);
		//___
		float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
		geometryOutput o;

		for (int i = 0; i < BLADE_SEGMENTS; i++)
		{
			float t = i / (float)BLADE_SEGMENTS;
			float segmentHeight = height * t;
			float segmentWidth = width * (1 - t);
			float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;

			triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, float2(0, t), transformMatrix, colorInten));
			triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, float2(1, t), transformMatrix, colorInten));
		}
		triStream.Append(GenerateGrassVertex(pos, 0, height, float2(0.5, 1), transformationMatrix, colorInten));

	}
	ENDCG

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geo
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain

			#pragma target 4.6
            
			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;

			float4 frag(geometryOutput i, fixed facing : VFACE) : SV_Target
			{
				return lerp(_BottomColor, _TopColor, i.uv.y * i.grassInfo.g);// *lerp(0,1,i.grassInfo.x / (_BladeHeight + _BladeHeightRandom));
            }
            ENDCG
        }
    }
}